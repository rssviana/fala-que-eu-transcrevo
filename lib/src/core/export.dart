import 'segment.dart';

/// Geração de .txt e .srt a partir dos segmentos.

String _two(int n) => n.toString().padLeft(2, '0');

/// `HH:MM:SS,mmm`, o formato de tempo do SubRip.
String srtTimestamp(Duration d) {
  final ms = d.inMilliseconds.remainder(1000).toString().padLeft(3, '0');
  return '${_two(d.inHours)}:${_two(d.inMinutes.remainder(60))}:'
      '${_two(d.inSeconds.remainder(60))},$ms';
}

/// `HH:MM:SS.mmm`, o formato de tempo do WebVTT.
String vttTimestamp(Duration d) => srtTimestamp(d).replaceFirst(',', '.');

String toVtt(List<Segment> segments) {
  final buf = StringBuffer('WEBVTT\n\n');
  for (final s in segments) {
    if (s.text.isEmpty) continue;
    buf
      ..writeln('${vttTimestamp(s.start)} --> ${vttTimestamp(s.end)}')
      ..writeln(s.text)
      ..writeln();
  }
  return buf.toString();
}

/// Palavras do texto corrido (sem anotações como `[MÚSICA]`).
int wordCount(List<Segment> segments) => RegExp(
  r"[\p{L}\p{N}][\p{L}\p{N}'’-]*",
  unicode: true,
).allMatches(toPlainText(segments)).length;

/// `mm:ss`, ou `h:mm:ss` a partir de 1 hora. Usado na prévia, no resultado e
/// na duração do vídeo.
String timestampLabel(Duration d) {
  final s = _two(d.inSeconds.remainder(60));
  if (d.inHours > 0) {
    return '${d.inHours}:${_two(d.inMinutes.remainder(60))}:$s';
  }
  return '${_two(d.inMinutes)}:$s';
}

/// Tempo gasto, curto: `25 s`, `7 min`, `1 h 05 min`.
String elapsedLabel(Duration d) {
  if (d.inSeconds < 60) return '${d.inSeconds} s';
  if (d.inHours > 0) {
    return '${d.inHours} h ${_two(d.inMinutes.remainder(60))} min';
  }
  return '${(d.inSeconds / 60).round()} min';
}

String toSrt(List<Segment> segments) {
  final buf = StringBuffer();
  var index = 1;
  for (final s in segments) {
    if (s.text.isEmpty) continue;
    buf
      ..writeln(index++)
      ..writeln('${srtTimestamp(s.start)} --> ${srtTimestamp(s.end)}')
      ..writeln(s.text)
      ..writeln();
  }
  return buf.toString();
}

/// Texto corrido: um segmento por linha, sem marcações do whisper como
/// `[MÚSICA]` ou `(risos)` sozinhas na linha.
String toPlainText(List<Segment> segments) => segments
    .map((s) => s.text.trim())
    .where((t) => t.isNotEmpty && !_isAnnotation(t))
    .join('\n');

bool _isAnnotation(String t) => RegExp(r'^[\[\(][^\]\)]*[\]\)]$').hasMatch(t);

/// Dados do cabeçalho do Markdown e do PDF.
class TranscriptInfo {
  const TranscriptInfo({
    required this.fileName,
    required this.languageLabel,
    required this.modelLabel,
    required this.date,
  });

  final String fileName;
  final String languageLabel;
  final String modelLabel;
  final DateTime date;
}

/// Parágrafo do texto: segmentos consecutivos agrupados, com o tempo de início.
class Paragraph {
  const Paragraph(this.start, this.text);
  final Duration start;
  final String text;

  @override
  bool operator ==(Object other) =>
      other is Paragraph && other.start == start && other.text == text;

  @override
  int get hashCode => Object.hash(start, text);

  @override
  String toString() => 'Paragraph($start: $text)';
}

/// Agrupa segmentos em parágrafos: quebra numa pausa maior que [gap] ou quando
/// o parágrafo passa de [maxChars] e o segmento anterior terminou uma frase
/// (ou passa de `2 × maxChars`, para fala sem pontuação).
List<Paragraph> paragraphs(
  List<Segment> segments, {
  Duration gap = const Duration(milliseconds: 1500),
  int maxChars = 600,
}) {
  final result = <Paragraph>[];
  Duration? start;
  Duration? lastEnd;
  final buf = StringBuffer();
  void flush() {
    if (buf.isNotEmpty) result.add(Paragraph(start!, buf.toString()));
    buf.clear();
  }

  for (final s in segments) {
    final text = s.text.trim();
    if (text.isEmpty || _isAnnotation(text)) continue;
    final paused = lastEnd != null && s.start - lastEnd > gap;
    final long =
        buf.length >= maxChars * 2 ||
        (buf.length >= maxChars && RegExp(r'[.!?…]$').hasMatch(buf.toString()));
    if (paused || long) flush();
    if (buf.isEmpty) {
      start = s.start;
    } else {
      buf.write(' ');
    }
    buf.write(text);
    lastEnd = s.end;
  }
  flush();
  return result;
}

/// `M:SS` ou `H:MM:SS`, para leitura humana.
String clockLabel(Duration d) {
  final m = d.inMinutes.remainder(60), s = _two(d.inSeconds.remainder(60));
  return d.inHours > 0 ? '${d.inHours}:${_two(m)}:$s' : '$m:$s';
}

/// `21/10/2026 19:07`
String dateLabel(DateTime d) =>
    '${_two(d.day)}/${_two(d.month)}/${d.year} ${_two(d.hour)}:${_two(d.minute)}';

String _escapeMarkdown(String text) => text
    .replaceAllMapped(RegExp(r'([\\`*_\[\]<>])'), (m) => '\\${m[1]}')
    .replaceFirstMapped(RegExp(r'^(#|\d+\.|[-+] )'), (m) => '\\${m[1]}');

String toMarkdown(List<Segment> segments, TranscriptInfo info) {
  final buf = StringBuffer()
    ..writeln('# ${_escapeMarkdown(info.fileName)}')
    ..writeln()
    ..writeln('- **Idioma:** ${info.languageLabel}')
    ..writeln('- **Modelo:** Whisper ${info.modelLabel}')
    ..writeln('- **Transcrito em:** ${dateLabel(info.date)}')
    ..writeln()
    ..writeln('## Transcrição')
    ..writeln();
  for (final p in paragraphs(segments)) {
    buf
      ..writeln('**[${clockLabel(p.start)}]** ${_escapeMarkdown(p.text)}')
      ..writeln();
  }
  buf.writeln('---');
  buf.writeln('*Gerado localmente por Fala que eu transcrevo!*');
  return buf.toString();
}
