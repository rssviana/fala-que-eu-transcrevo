import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:transcritor/src/core/segment.dart';
import 'package:transcritor/src/core/transcriber.dart';

/// Processo falso: emite linhas prontas e sai com [exitCodeValue].
class FakeProcess implements Process {
  FakeProcess({
    List<String> stdoutLines = const [],
    List<String> stderrLines = const [],
    this.exitCodeValue = 0,
    this.hang = false,
  }) {
    _out = Stream.fromIterable(stdoutLines.map((l) => utf8.encode('$l\n')));
    _err = Stream.fromIterable(stderrLines.map((l) => utf8.encode('$l\r')));
    if (!hang) _exit.complete(exitCodeValue);
  }

  final int exitCodeValue;
  final bool hang;
  late final Stream<List<int>> _out;
  late final Stream<List<int>> _err;
  final _exit = Completer<int>();
  bool killed = false;

  @override
  Stream<List<int>> get stdout => _out;
  @override
  Stream<List<int>> get stderr => _err;
  @override
  Future<int> get exitCode => _exit.future;
  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    killed = true;
    if (!_exit.isCompleted) _exit.complete(-15);
    return true;
  }

  @override
  int get pid => 1;
  @override
  IOSink get stdin => throw UnimplementedError();
}

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('transcritor_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('roda ffmpeg e whisper e devolve os segmentos', () async {
    final calls = <String>[];
    final t = Transcriber(
      ffmpegPath: 'ffmpeg',
      whisperPath: 'whisper-cli',
      tempDir: tmp,
      processors: 4,
      startProcess: (exe, args) async {
        calls.add('$exe ${args.join(' ')}');
        if (exe == 'ffmpeg') {
          return FakeProcess(
            stderrLines: [
              'Duration: 00:00:10.00, start: 0.0',
              'size=1kB time=00:00:05.00 bitrate=1',
            ],
          );
        }
        return FakeProcess(
          stdoutLines: [
            '[00:00:00.000 --> 00:00:04.000]   Bom dia.',
            '[00:00:04.000 --> 00:00:09.000]   Até logo.',
          ],
          stderrLines: ['whisper_print_progress_callback: progress =  50%'],
        );
      },
    );
    final progress = <double>[];
    final live = <Segment>[];
    final result = await t.run(
      input: '/v/video.mp4',
      modelPath: '/m/ggml-base.bin',
      language: 'pt',
      onProgress: (_, p) => progress.add(p),
      onSegment: live.add,
    );
    expect(result.map((s) => s.text), ['Bom dia.', 'Até logo.']);
    expect(live, result);
    expect(calls.first, startsWith('ffmpeg '));
    expect(calls.last, contains('-l pt'));
    expect(calls.last, contains('-t 2'));
    expect(progress.last, 1);
    // Progresso nunca anda para trás.
    for (var i = 1; i < progress.length; i++) {
      expect(progress[i], greaterThanOrEqualTo(progress[i - 1]));
    }
    expect(tmp.listSync(), isEmpty, reason: 'WAV temporário apagado');
  });

  test('falha do ffmpeg vira TranscriptionFailed com o stderr', () async {
    final t = Transcriber(
      ffmpegPath: 'ffmpeg',
      whisperPath: 'whisper-cli',
      tempDir: tmp,
      startProcess: (exe, args) async => FakeProcess(
        stderrLines: ['Output file does not contain any stream'],
        exitCodeValue: 1,
      ),
    );
    await expectLater(
      t.run(input: 'x', modelPath: 'm', language: 'pt', onProgress: (_, _) {}),
      throwsA(
        isA<TranscriptionFailed>().having(
          (e) => e.details,
          'details',
          contains('does not contain'),
        ),
      ),
    );
  });

  test('cancelar mata o processo e lança TranscriptionCancelled', () async {
    final hanging = FakeProcess(hang: true);
    late Transcriber t;
    t = Transcriber(
      ffmpegPath: 'ffmpeg',
      whisperPath: 'whisper-cli',
      tempDir: tmp,
      startProcess: (exe, args) async {
        scheduleMicrotask(t.cancel);
        return hanging;
      },
    );
    await expectLater(
      t.run(input: 'x', modelPath: 'm', language: 'pt', onProgress: (_, _) {}),
      throwsA(isA<TranscriptionCancelled>()),
    );
    expect(hanging.killed, isTrue);
  });

  test('binário inexistente vira TranscriptionFailed', () async {
    final t = Transcriber(
      ffmpegPath: 'ffmpeg',
      whisperPath: 'whisper-cli',
      tempDir: tmp,
      startProcess: (exe, args) async =>
          throw ProcessException(exe, args, 'No such file'),
    );
    await expectLater(
      t.run(input: 'x', modelPath: 'm', language: 'pt', onProgress: (_, _) {}),
      throwsA(isA<TranscriptionFailed>()),
    );
  });
}
