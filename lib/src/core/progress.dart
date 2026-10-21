import 'segment.dart';

/// Parse das saídas do ffmpeg e do whisper-cli. Funções puras, linha a linha.

final _duration = RegExp(r'Duration:\s*(\d+):(\d\d):(\d\d(?:\.\d+)?)');
final _ffTime = RegExp(r'time=\s*(\d+):(\d\d):(\d\d(?:\.\d+)?)');
final _whisperProgress = RegExp(r'progress\s*=\s*(\d{1,3})\s*%');
final _segment = RegExp(
  r'^\s*\[(\d+):(\d\d):(\d\d)[.,](\d{3})\s*-->\s*(\d+):(\d\d):(\d\d)[.,](\d{3})\]\s?(.*)$',
);

Duration _hms(String h, String m, String s) => Duration(
  microseconds:
      ((int.parse(h) * 3600 + int.parse(m) * 60) * 1e6 + double.parse(s) * 1e6)
          .round(),
);

/// Duração total do arquivo de entrada (linha "Duration:" do ffmpeg).
Duration? parseFfmpegDuration(String line) {
  final m = _duration.firstMatch(line);
  return m == null ? null : _hms(m[1]!, m[2]!, m[3]!);
}

/// Posição atual da conversão (campo "time=" do ffmpeg).
Duration? parseFfmpegTime(String line) {
  final m = _ffTime.firstMatch(line);
  return m == null ? null : _hms(m[1]!, m[2]!, m[3]!);
}

/// Percentual (0–100) impresso pelo whisper-cli com `-pp`.
int? parseWhisperProgress(String line) {
  final m = _whisperProgress.firstMatch(line);
  if (m == null) return null;
  return int.parse(m[1]!).clamp(0, 100);
}

/// Segmento do stdout do whisper-cli: `[00:00:01.000 --> 00:00:04.500]  texto`.
Segment? parseWhisperSegment(String line) {
  final m = _segment.firstMatch(line);
  if (m == null) return null;
  Duration t(int i) => Duration(
    hours: int.parse(m[i]!),
    minutes: int.parse(m[i + 1]!),
    seconds: int.parse(m[i + 2]!),
    milliseconds: int.parse(m[i + 3]!),
  );
  return Segment(start: t(1), end: t(5), text: m[9]!.trim());
}

/// Junta o progresso das duas etapas numa fração 0–1.
/// A extração de áudio é rápida, então vale [extractWeight] do total.
double overallProgress({
  required bool transcribing,
  required double stepFraction,
  double extractWeight = 0.1,
}) {
  final f = stepFraction.clamp(0.0, 1.0);
  return transcribing
      ? extractWeight + f * (1 - extractWeight)
      : f * extractWeight;
}
