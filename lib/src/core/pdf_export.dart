import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'export.dart';
import 'segment.dart';

/// Gera o PDF da transcrição. As fontes entram como bytes (TTF) para que o
/// PDF tenha acentuação e para a função não depender do Flutter.
Future<Uint8List> toPdf(
  List<Segment> segments,
  TranscriptInfo info, {
  required ByteData regularFont,
  required ByteData boldFont,
}) {
  final regular = pw.Font.ttf(regularFont);
  final bold = pw.Font.ttf(boldFont);
  final grey = PdfColor.fromInt(0xFF6B7280);
  final doc = pw.Document(
    title: info.fileName,
    creator: 'Fala que eu transcrevo!',
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 56, vertical: 48),
      footer: (context) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Fala que eu transcrevo!',
            style: pw.TextStyle(fontSize: 8, color: grey),
          ),
          pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: grey),
          ),
        ],
      ),
      build: (context) => [
        pw.Text(info.fileName, style: pw.TextStyle(font: bold, fontSize: 18)),
        pw.SizedBox(height: 6),
        pw.Text(
          'Idioma: ${info.languageLabel}  ·  Modelo: Whisper ${info.modelLabel}'
          '  ·  ${dateLabel(info.date)}',
          style: pw.TextStyle(fontSize: 9, color: grey),
        ),
        pw.Divider(color: grey, thickness: 0.5, height: 24),
        for (final p in paragraphs(segments)) ...[
          pw.Text(
            clockLabel(p.start),
            style: pw.TextStyle(fontSize: 8, color: grey),
          ),
          // pw.Paragraph quebra entre páginas; pw.Text não.
          pw.Paragraph(
            text: p.text,
            style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
            margin: const pw.EdgeInsets.only(top: 2, bottom: 10),
          ),
        ],
      ],
    ),
  );
  return doc.save();
}
