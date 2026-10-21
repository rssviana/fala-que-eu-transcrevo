/// Etapas da Tela 3 e como cada uma pesa na porcentagem geral.
library;

enum PipelineStep { extract, model, transcribe, done }

/// Peso de cada etapa no total. Baixar o modelo só pesa quando precisa baixar.
Map<PipelineStep, double> stepWeights({required bool needsDownload}) =>
    needsDownload
    ? {
        PipelineStep.extract: 0.05,
        PipelineStep.model: 0.35,
        PipelineStep.transcribe: 0.60,
      }
    : {
        PipelineStep.extract: 0.08,
        PipelineStep.model: 0.0,
        PipelineStep.transcribe: 0.92,
      };

/// Fração 0–1 do total, dada a etapa atual e o quanto dela já foi feito.
double overallFraction(
  PipelineStep step,
  double stepFraction, {
  required bool needsDownload,
}) {
  if (step == PipelineStep.done) return 1;
  final w = stepWeights(needsDownload: needsDownload);
  var total = 0.0;
  for (final s in [
    PipelineStep.extract,
    PipelineStep.model,
    PipelineStep.transcribe,
  ]) {
    if (s == step) return total + w[s]! * stepFraction.clamp(0.0, 1.0);
    total += w[s]!;
  }
  return total;
}

/// Estima o tempo restante a partir do ritmo até aqui. `null` enquanto houver
/// pouco dado para estimar.
Duration? estimateRemaining({
  required Duration elapsed,
  required double fraction,
}) {
  if (fraction < 0.03 || elapsed < const Duration(seconds: 3)) return null;
  if (fraction >= 1) return Duration.zero;
  final totalMs = elapsed.inMilliseconds / fraction;
  return Duration(milliseconds: (totalMs - elapsed.inMilliseconds).round());
}

/// "cerca de N min restantes".
String etaLabel(Duration? remaining) {
  if (remaining == null) return 'calculando o tempo…';
  if (remaining < const Duration(minutes: 1)) return 'menos de 1 min restante';
  final min = (remaining.inSeconds / 60).ceil();
  return 'cerca de $min min restantes';
}
