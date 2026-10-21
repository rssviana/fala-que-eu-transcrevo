import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'commands.dart';
import 'progress.dart';
import 'segment.dart';

enum Stage { extracting, transcribing }

class TranscriptionCancelled implements Exception {
  @override
  String toString() => 'Transcrição cancelada';
}

class TranscriptionFailed implements Exception {
  TranscriptionFailed(this.message, [this.details = '']);
  final String message;
  final String details;

  @override
  String toString() => details.isEmpty ? message : '$message\n\n$details';
}

typedef ProcessStarter =
    Future<Process> Function(String executable, List<String> arguments);

/// Pipeline: ffmpeg extrai o áudio → whisper-cli transcreve.
/// Os dois rodam como processos filhos; o progresso vem do parse da saída.
class Transcriber {
  Transcriber({
    required this.ffmpegPath,
    required this.whisperPath,
    required this.tempDir,
    ProcessStarter? startProcess,
    int? processors,
  }) : _start =
           startProcess ??
           ((exe, args) => Process.start(exe, args, runInShell: false)),
       _threads = whisperThreads(processors ?? Platform.numberOfProcessors);

  final String ffmpegPath;
  final String whisperPath;
  final Directory tempDir;
  final ProcessStarter _start;
  final int _threads;

  Process? _current;
  bool _cancelled = false;

  void cancel() {
    _cancelled = true;
    _current?.kill();
  }

  Future<List<Segment>> run({
    required String input,
    required String modelPath,
    required String language,
    required void Function(Stage stage, double overall) onProgress,
    void Function(Segment segment)? onSegment,
  }) async {
    _cancelled = false;
    await tempDir.create(recursive: true);
    final wav = File(
      '${tempDir.path}${Platform.pathSeparator}audio_${DateTime.now().microsecondsSinceEpoch}.wav',
    );
    try {
      final duration = await _extract(input, wav.path, onProgress);
      return await _transcribe(
        wav.path,
        modelPath,
        language,
        duration,
        onProgress,
        onSegment,
      );
    } finally {
      if (await wav.exists()) await wav.delete();
    }
  }

  Future<Duration?> _extract(
    String input,
    String output,
    void Function(Stage, double) onProgress,
  ) async {
    Duration? duration;
    final tail = _Tail();
    onProgress(Stage.extracting, 0);
    final code = await _runProcess(
      ffmpegPath,
      ffmpegExtractArgs(input: input, output: output),
      onStderr: (line) {
        tail.add(line);
        duration ??= parseFfmpegDuration(line);
        final t = parseFfmpegTime(line);
        if (t != null && duration != null && duration!.inMilliseconds > 0) {
          onProgress(
            Stage.extracting,
            overallProgress(
              transcribing: false,
              stepFraction: t.inMilliseconds / duration!.inMilliseconds,
            ),
          );
        }
      },
    );
    if (code != 0) {
      throw TranscriptionFailed(
        'Não foi possível extrair o áudio do vídeo. O arquivo tem trilha de áudio?',
        tail.text,
      );
    }
    return duration;
  }

  Future<List<Segment>> _transcribe(
    String wav,
    String model,
    String language,
    Duration? duration,
    void Function(Stage, double) onProgress,
    void Function(Segment)? onSegment,
  ) async {
    final segments = <Segment>[];
    final tail = _Tail();
    var fraction = 0.0;
    void report(double f) {
      if (f <= fraction) return;
      fraction = f;
      onProgress(
        Stage.transcribing,
        overallProgress(transcribing: true, stepFraction: f),
      );
    }

    onProgress(
      Stage.transcribing,
      overallProgress(transcribing: true, stepFraction: 0),
    );
    final code = await _runProcess(
      whisperPath,
      whisperArgs(
        model: model,
        audio: wav,
        language: language,
        threads: _threads,
      ),
      onStdout: (line) {
        final s = parseWhisperSegment(line);
        if (s == null) return;
        segments.add(s);
        onSegment?.call(s);
        // Fallback de progresso: posição do último segmento / duração.
        if (duration != null && duration.inMilliseconds > 0) {
          report(s.end.inMilliseconds / duration.inMilliseconds * 0.99);
        }
      },
      onStderr: (line) {
        tail.add(line);
        final pct = parseWhisperProgress(line);
        if (pct != null) report(pct / 100);
      },
    );
    if (code != 0) {
      throw TranscriptionFailed(
        'O whisper-cli falhou (código $code).',
        tail.text,
      );
    }
    report(1);
    return segments;
  }

  Future<int> _runProcess(
    String exe,
    List<String> args, {
    void Function(String line)? onStdout,
    void Function(String line)? onStderr,
  }) async {
    if (_cancelled) throw TranscriptionCancelled();
    final Process process;
    try {
      process = await _start(exe, args);
    } on ProcessException catch (e) {
      throw TranscriptionFailed('Não foi possível executar $exe', e.message);
    }
    _current = process;
    // Cancelado enquanto o processo iniciava: mata agora.
    if (_cancelled) process.kill();
    Stream<String> lines(Stream<List<int>> s) => s
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter());
    final out = lines(process.stdout).forEach((l) => onStdout?.call(l));
    final err = lines(process.stderr).forEach((l) => onStderr?.call(l));
    final code = await process.exitCode;
    await Future.wait([out, err]);
    _current = null;
    if (_cancelled) throw TranscriptionCancelled();
    return code;
  }
}

/// Últimas linhas de stderr, para mostrar no erro.
class _Tail {
  final _lines = <String>[];
  void add(String l) {
    if (l.trim().isEmpty) return;
    _lines.add(l);
    if (_lines.length > 15) _lines.removeAt(0);
  }

  String get text => _lines.join('\n');
}
