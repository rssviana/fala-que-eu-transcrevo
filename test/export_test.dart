import 'package:flutter_test/flutter_test.dart';
import 'package:transcritor/src/core/export.dart';
import 'package:transcritor/src/core/segment.dart';

void main() {
  const segs = [
    Segment(
      start: Duration.zero,
      end: Duration(seconds: 2, milliseconds: 5),
      text: 'Olá.',
    ),
    Segment(
      start: Duration(seconds: 2),
      end: Duration(seconds: 3),
      text: '[MÚSICA]',
    ),
    Segment(start: Duration(seconds: 3), end: Duration(seconds: 3), text: ''),
    Segment(
      start: Duration(hours: 1, minutes: 2, seconds: 3, milliseconds: 40),
      end: Duration(hours: 1, minutes: 2, seconds: 6),
      text: 'Tchau!',
    ),
  ];

  test('timestamp SRT', () {
    expect(srtTimestamp(Duration.zero), '00:00:00,000');
    expect(
      srtTimestamp(
        const Duration(hours: 1, minutes: 2, seconds: 3, milliseconds: 40),
      ),
      '01:02:03,040',
    );
  });

  test('SRT numera em sequência e pula segmentos vazios', () {
    expect(toSrt(segs), '''
1
00:00:00,000 --> 00:00:02,005
Olá.

2
00:00:02,000 --> 00:00:03,000
[MÚSICA]

3
01:02:03,040 --> 01:02:06,000
Tchau!

''');
  });

  test('VTT com cabeçalho e ponto nos milissegundos', () {
    expect(
      toVtt(segs),
      startsWith('WEBVTT\n\n00:00:00.000 --> 00:00:02.005\nOlá.\n\n'),
    );
    expect(toVtt(segs), isNot(contains('00:00:03.000 --> 00:00:03.000')));
  });

  test('contagem de palavras ignora anotações', () {
    expect(wordCount(segs), 2);
    expect(
      wordCount(const [
        Segment(
          start: Duration.zero,
          end: Duration.zero,
          text: "É d'água, 2 vezes.",
        ),
      ]),
      4,
    );
  });

  test('rótulos de tempo', () {
    expect(timestampLabel(const Duration(seconds: 7)), '00:07');
    expect(timestampLabel(const Duration(minutes: 48, seconds: 12)), '48:12');
    expect(
      timestampLabel(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '1:02:03',
    );
    expect(elapsedLabel(const Duration(seconds: 25)), '25 s');
    expect(elapsedLabel(const Duration(minutes: 7, seconds: 10)), '7 min');
    expect(elapsedLabel(const Duration(hours: 1, minutes: 5)), '1 h 05 min');
  });

  test('texto puro remove anotações e vazios', () {
    expect(toPlainText(segs), 'Olá.\nTchau!');
  });
}
