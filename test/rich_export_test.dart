import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:transcritor/src/core/export.dart';
import 'package:transcritor/src/core/pdf_export.dart';
import 'package:transcritor/src/core/segment.dart';

Segment seg(int startMs, int endMs, String text) => Segment(
  start: Duration(milliseconds: startMs),
  end: Duration(milliseconds: endMs),
  text: text,
);

void main() {
  final info = TranscriptInfo(
    fileName: 'aula_01.mp4',
    languageLabel: 'Português (Brasil)',
    modelLabel: 'Small',
    date: DateTime(2026, 10, 21, 19, 7),
  );

  final segs = [
    seg(0, 2000, 'Olá, pessoal.'),
    seg(2000, 4000, 'Tudo bem?'),
    seg(4000, 5000, '[MÚSICA]'),
    // pausa de 3 s → novo parágrafo
    seg(8000, 10000, 'Vamos começar.'),
  ];

  test('clockLabel e dateLabel', () {
    expect(clockLabel(const Duration(seconds: 65)), '1:05');
    expect(
      clockLabel(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '1:02:03',
    );
    expect(dateLabel(DateTime(2026, 1, 2, 3, 4)), '02/01/2026 03:04');
  });

  test('parágrafos quebram em pausas e ignoram anotações', () {
    expect(paragraphs(segs), const [
      Paragraph(Duration.zero, 'Olá, pessoal. Tudo bem?'),
      Paragraph(Duration(seconds: 8), 'Vamos começar.'),
    ]);
  });

  test(
    'parágrafos longos quebram no fim de frase, ou no dobro sem pontuação',
    () {
      final frases = [
        for (var i = 0; i < 10; i++)
          seg(i * 1000, i * 1000 + 1000, 'Frase número $i.'),
      ];
      expect(paragraphs(frases, maxChars: 30).length, greaterThan(1));
      final semPonto = [
        for (var i = 0; i < 10; i++)
          seg(i * 1000, i * 1000 + 1000, 'palavra sem fim'),
      ];
      final ps = paragraphs(semPonto, maxChars: 30);
      expect(ps.length, greaterThan(1));
      expect(ps.every((p) => p.text.length < 80), isTrue);
    },
  );

  test('Markdown com cabeçalho, tempos e escape', () {
    final md = toMarkdown([
      ...segs,
      seg(12000, 13000, 'Use *asteriscos* e <tags>'),
    ], info);
    expect(md, startsWith('# aula\\_01.mp4\n'));
    expect(md, contains('- **Idioma:** Português (Brasil)'));
    expect(md, contains('- **Modelo:** Whisper Small'));
    expect(md, contains('- **Transcrito em:** 21/10/2026 19:07'));
    expect(md, contains('**[0:00]** Olá, pessoal. Tudo bem?\n'));
    expect(md, contains('**[0:08]** Vamos começar.'));
    expect(md, contains(r'Use \*asteriscos\* e \<tags\>'));
    expect(md, isNot(contains('MÚSICA')));
  });

  test('PDF válido com fonte embutida, inclusive com muitas páginas', () async {
    ByteData font(String name) => ByteData.sublistView(
      File('assets/fonts/NotoSans-$name.ttf').readAsBytesSync(),
    );
    final longo = [
      for (var i = 0; i < 400; i++)
        seg(
          i * 2000,
          i * 2000 + 1900,
          'Ação número $i, com acentuação: é, ã, ç, ô.',
        ),
    ];
    final bytes = await toPdf(
      longo,
      info,
      regularFont: font('Regular'),
      boldFont: font('Bold'),
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(10000));
  });
}
