import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'commands.dart';
import 'progress.dart';
import 'segment.dart';

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

/// Duração e miniatura de um arquivo de vídeo.
class MediaInfo {
  const MediaInfo({this.duration, this.thumbnailPath});
  final Duration? duration;
  final String? thumbnailPath;
}

/// Executa ffmpeg e whisper-cli como processos filhos. Cada etapa é um método,
/// para a tela poder intercalar o download do modelo entre elas. O progresso
/// vem do parse da saída e é entregue como fração 0–1 da etapa.
class Transcriber {
  Transcriber({
    required this.ffmpegPath,
    required this.whisperPath,
    ProcessStarter? startProcess,
    int? processors,
  }) : _start =
           startProcess ??
           ((exe, args) => Process.start(exe, args, runInShell: false)),
       _threads = whisperThreads(processors ?? Platform.numberOfProcessors);

  final String ffmpegPath;
  final String whisperPath;
  final ProcessStarter _start;
  final int _threads;

  Process? _current;
  bool _cancelled = false;

  bool get cancelled => _cancelled;

  void cancel() {
    _cancelled = true;
    _current?.kill();
  }

  /// Lê a duração e extrai um quadro para [thumbnailPath]. Nunca lança:
  /// sem ffmpeg ou sem vídeo, devolve o que conseguir.
  Future<MediaInfo> probe(String input, String thumbnailPath) async {
    Duration? duration;
    try {
      final code = await _runProcess(
        ffmpegPath,
        ffmpegThumbnailArgs(input: input, output: thumbnailPath),
        onStderr: (l) => duration ??= parseFfmpegDuration(l),
        checkCancel: false,
      );
      final thumb = File(thumbnailPath);
      return MediaInfo(
        duration: duration,
        thumbnailPath: code == 0 && thumb.existsSync() ? thumbnailPath : null,
      );
    } catch (_) {
      return MediaInfo(duration: duration);
    }
  }

  /// Extrai o áudio em WAV 16 kHz mono. Devolve a duração do arquivo.
  Future<Duration?> extractAudio(
    String input,
    String wavPath, {
    required void Function(double fraction) onProgress,
  }) async {
    Duration? duration;
    final tail = _Tail();
    final code = await _runProcess(
      ffmpegPath,
      ffmpegExtractArgs(input: input, output: wavPath),
      onStderr: (line) {
        tail.add(line);
        duration ??= parseFfmpegDuration(line);
        final t = parseFfmpegTime(line);
        final d = duration;
        if (t != null && d != null && d.inMilliseconds > 0) {
          onProgress(t.inMilliseconds / d.inMilliseconds);
        }
      },
    );
    if (code != 0) {
      throw TranscriptionFailed(
        'Não foi possível extrair o áudio do vídeo. O arquivo tem trilha de áudio?',
        tail.text,
      );
    }
    onProgress(1);
    return duration;
  }

  /// Transcreve o WAV. [onSegment] recebe cada trecho assim que sai.
  Future<List<Segment>> transcribe(
    String wavPath, {
    required String modelPath,
    required String language,
    Duration? duration,
    required void Function(double fraction) onProgress,
    void Function(Segment segment)? onSegment,
  }) async {
    final segments = <Segment>[];
    final tail = _Tail();
    var fraction = 0.0;
    void report(double f) {
      if (f <= fraction) return;
      fraction = f;
      onProgress(f);
    }

    final code = await _runProcess(
      whisperPath,
      whisperArgs(
        model: modelPath,
        audio: wavPath,
        language: language,
        threads: _threads,
      ),
      onStdout: (line) {
        final s = parseWhisperSegment(line);
        if (s == null) return;
        segments.add(s);
        onSegment?.call(s);
        // Fallback de progresso: posição do último trecho / duração.
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
    bool checkCancel = true,
  }) async {
    if (checkCancel && _cancelled) throw TranscriptionCancelled();
    final Process process;
    try {
      process = await _start(exe, args);
    } on ProcessException catch (e) {
      throw TranscriptionFailed('Não foi possível executar $exe', e.message);
    }
    if (!checkCancel) return _drain(process, onStdout, onStderr);
    _current = process;
    // Cancelado enquanto o processo iniciava: mata agora.
    if (_cancelled) process.kill();
    final code = await _drain(process, onStdout, onStderr);
    _current = null;
    if (_cancelled) throw TranscriptionCancelled();
    return code;
  }

  Future<int> _drain(
    Process process,
    void Function(String line)? onStdout,
    void Function(String line)? onStderr,
  ) async {
    Stream<String> lines(Stream<List<int>> s) => s
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter());
    final out = lines(process.stdout).forEach((l) => onStdout?.call(l));
    final err = lines(process.stderr).forEach((l) => onStderr?.call(l));
    final code = await process.exitCode;
    await Future.wait([out, err]);
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
