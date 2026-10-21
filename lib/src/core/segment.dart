/// Trecho transcrito com tempo de início e fim.
class Segment {
  const Segment({required this.start, required this.end, required this.text});

  final Duration start;
  final Duration end;
  final String text;

  @override
  bool operator ==(Object other) =>
      other is Segment &&
      other.start == start &&
      other.end == end &&
      other.text == text;

  @override
  int get hashCode => Object.hash(start, end, text);

  @override
  String toString() => 'Segment($start → $end: $text)';
}
