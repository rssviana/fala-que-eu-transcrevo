import 'package:flutter_test/flutter_test.dart';
import 'package:transcritor/src/core/progress.dart';
import 'package:transcritor/src/core/segment.dart';

void main() {
  test('duração e tempo do ffmpeg', () {
    expect(
      parseFfmpegDuration(
        '  Duration: 00:01:23.45, start: 0.000000, bitrate: 1205 kb/s',
      ),
      const Duration(minutes: 1, seconds: 23, milliseconds: 450),
    );
    expect(
      parseFfmpegTime(
        'size=    1024kB time=00:00:10.50 bitrate= 128.0kbits/s speed=40x',
      ),
      const Duration(seconds: 10, milliseconds: 500),
    );
    expect(parseFfmpegDuration('Stream #0:0: Audio'), isNull);
    expect(parseFfmpegTime('Duration: N/A'), isNull);
  });

  test('progresso do whisper-cli', () {
    expect(
      parseWhisperProgress('whisper_print_progress_callback: progress =  25%'),
      25,
    );
    expect(parseWhisperProgress('progress = 100%'), 100);
    expect(
      parseWhisperProgress('whisper_init_from_file: loading model'),
      isNull,
    );
  });

  test('segmento do stdout do whisper-cli', () {
    expect(
      parseWhisperSegment('[00:00:01.000 --> 00:00:04.520]   Olá, tudo bem?'),
      const Segment(
        start: Duration(seconds: 1),
        end: Duration(seconds: 4, milliseconds: 520),
        text: 'Olá, tudo bem?',
      ),
    );
    expect(
      parseWhisperSegment('[01:02:03.004 --> 01:02:05.000]'),
      const Segment(
        start: Duration(hours: 1, minutes: 2, seconds: 3, milliseconds: 4),
        end: Duration(hours: 1, minutes: 2, seconds: 5),
        text: '',
      ),
    );
    expect(parseWhisperSegment('main: processing audio'), isNull);
  });

  test('progresso geral combina extração e transcrição', () {
    expect(
      overallProgress(transcribing: false, stepFraction: 0.5),
      closeTo(0.05, 1e-9),
    );
    expect(
      overallProgress(transcribing: true, stepFraction: 0),
      closeTo(0.1, 1e-9),
    );
    expect(
      overallProgress(transcribing: true, stepFraction: 1),
      closeTo(1, 1e-9),
    );
    expect(
      overallProgress(transcribing: true, stepFraction: 2),
      closeTo(1, 1e-9),
    );
  });
}
