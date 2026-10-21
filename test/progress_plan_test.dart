import 'package:flutter_test/flutter_test.dart';
import 'package:transcritor/src/core/progress_plan.dart';

void main() {
  test('sem download: extração 8% e transcrição 92%', () {
    double f(PipelineStep s, double x) =>
        overallFraction(s, x, needsDownload: false);
    expect(f(PipelineStep.extract, 0), 0);
    expect(f(PipelineStep.extract, 1), closeTo(0.08, 1e-9));
    expect(f(PipelineStep.model, 0.5), closeTo(0.08, 1e-9));
    expect(f(PipelineStep.transcribe, 0.5), closeTo(0.54, 1e-9));
    expect(f(PipelineStep.done, 0), 1);
  });

  test('com download o modelo pesa 35%', () {
    double f(PipelineStep s, double x) =>
        overallFraction(s, x, needsDownload: true);
    expect(f(PipelineStep.model, 0.5), closeTo(0.05 + 0.175, 1e-9));
    expect(f(PipelineStep.transcribe, 0), closeTo(0.40, 1e-9));
    expect(f(PipelineStep.transcribe, 2), closeTo(1, 1e-9));
  });

  test('estimativa de tempo restante', () {
    expect(
      estimateRemaining(elapsed: const Duration(seconds: 1), fraction: 0.5),
      isNull,
    );
    expect(
      estimateRemaining(elapsed: const Duration(minutes: 1), fraction: 0.01),
      isNull,
    );
    expect(
      estimateRemaining(elapsed: const Duration(minutes: 2), fraction: 0.4),
      const Duration(minutes: 3),
    );
  });

  test('texto da estimativa', () {
    expect(etaLabel(null), 'calculando o tempo…');
    expect(etaLabel(const Duration(seconds: 40)), 'menos de 1 min restante');
    expect(
      etaLabel(const Duration(minutes: 2, seconds: 10)),
      'cerca de 3 min restantes',
    );
  });
}
