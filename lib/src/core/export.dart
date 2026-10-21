import 'segment.dart';

/// Geração de .txt e .srt a partir dos segmentos.

String _two(int n) => n.toString().padLeft(2, '0');

/// `HH:MM:SS,mmm`, o formato de tempo do SubRip.
String srtTimestamp(Duration d) {
  final ms = d.inMilliseconds.remainder(1000).toString().padLeft(3, '0');
  return '${_two(d.inHours)}:${_two(d.inMinutes.remainder(60))}:'
      '${_two(d.inSeconds.remainder(60))},$ms';
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
