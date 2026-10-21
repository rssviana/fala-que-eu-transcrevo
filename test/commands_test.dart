import 'package:flutter_test/flutter_test.dart';
import 'package:transcritor/src/core/commands.dart';

void main() {
  test('ffmpeg extrai WAV 16 kHz mono sem vídeo', () {
    final args = ffmpegExtractArgs(input: '/v/a b.mp4', output: '/t/x.wav');
    expect(args, containsAllInOrder(['-i', '/v/a b.mp4']));
    expect(args, containsAllInOrder(['-ar', '16000']));
    expect(args, containsAllInOrder(['-ac', '1']));
    expect(args, containsAllInOrder(['-c:a', 'pcm_s16le']));
    expect(args, contains('-vn'));
    expect(args, contains('-y'));
    expect(args.last, '/t/x.wav');
  });

  test('whisper-cli com modelo, áudio, idioma, threads e progresso', () {
    final args = whisperArgs(
      model: '/m/ggml-base.bin',
      audio: '/t/x.wav',
      language: 'pt',
      threads: 4,
    );
    expect(args, containsAllInOrder(['-m', '/m/ggml-base.bin']));
    expect(args, containsAllInOrder(['-f', '/t/x.wav']));
    expect(args, containsAllInOrder(['-l', 'pt']));
    expect(args, containsAllInOrder(['-t', '4']));
    expect(args, contains('-pp'));
  });

  test('whisperThreads fica entre 1 e 8', () {
    expect(whisperThreads(1), 1);
    expect(whisperThreads(8), 4);
    expect(whisperThreads(32), 8);
  });
}
