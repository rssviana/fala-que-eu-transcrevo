import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Estilos de texto do handoff. As fontes são variáveis: o peso vai em
/// `fontVariations` (e também em `fontWeight`, que casa com o peso declarado
/// no pubspec). letterSpacing já convertido de em para pixels.
abstract final class AppText {
  /// Altura de linha "normal" do CSS (métricas hhea/typo de cada fonte). Sem
  /// isso o Flutter usa as métricas win, e o texto fica ~18% mais alto que no
  /// navegador.
  static const _normalHeight = {
    'Inter': 1.21,
    'Bricolage': 1.2,
    'JetBrainsMono': 1.32,
  };

  static TextStyle _font(
    String family,
    double size,
    int weight, {
    Color color = AppColors.text,
    double? height,
    double letterSpacingEm = 0,
    double? opsz,
  }) => TextStyle(
    fontFamily: family,
    fontFamilyFallback: family == 'JetBrainsMono'
        ? const ['Menlo', 'Consolas', 'monospace']
        : const ['system-ui', 'Segoe UI', 'Roboto', 'sans-serif'],
    fontSize: size,
    fontWeight: FontWeight.values[(weight ~/ 100) - 1],
    fontVariations: [
      FontVariation.weight(weight.toDouble()),
      if (opsz != null) FontVariation('opsz', opsz),
    ],
    color: color,
    height: height ?? _normalHeight[family],
    leadingDistribution: TextLeadingDistribution.even,
    letterSpacing: letterSpacingEm * size,
  );

  /// Bricolage Grotesque com o eixo óptico igual ao tamanho (12–96), como o
  /// navegador faz na referência (`font-optical-sizing: auto`).
  static TextStyle display(
    double size,
    int weight, {
    Color color = AppColors.text,
    double? height,
    double letterSpacingEm = 0,
  }) => _font(
    'Bricolage',
    size,
    weight,
    color: color,
    height: height,
    letterSpacingEm: letterSpacingEm,
    opsz: size.clamp(12, 96).toDouble(),
  );

  static TextStyle ui(
    double size,
    int weight, {
    Color color = AppColors.text,
    double? height,
    double letterSpacingEm = 0,
  }) => _font(
    'Inter',
    size,
    weight,
    color: color,
    height: height,
    letterSpacingEm: letterSpacingEm,
  );

  static TextStyle mono(double size, {Color color = AppColors.text}) =>
      _font('JetBrainsMono', size, 500, color: color);

  static final brandName = display(19, 800, letterSpacingEm: -0.01);
  static final brandSub = ui(12.5, 400, color: AppColors.textMuted);
  static final dropzoneTitle = display(30, 700, letterSpacingEm: -0.02);
  static final setupH1 = display(34, 800, height: 1.1, letterSpacingEm: -0.02);
  static final percent = display(56, 800, height: 1, letterSpacingEm: -0.03);
  static final percentSign = display(
    28,
    800,
    color: AppColors.textMuted,
    height: 1,
    letterSpacingEm: -0.03,
  );
  static final doneTitle = display(
    26,
    800,
    height: 1.15,
    letterSpacingEm: -0.02,
  );
  static final modelName = display(16, 700);
  static final sectionLabel = ui(
    13,
    600,
    color: AppColors.textStrongMuted,
    letterSpacingEm: 0.02,
  );
  static final eyebrow = ui(12.5, 600, letterSpacingEm: 0.08);
  static final lead = ui(15.5, 400, color: AppColors.textMuted, height: 1.6);
  static final body = ui(14, 400);
  static final hint = ui(13, 400, color: AppColors.textFaint, height: 1.5);
  static final hintSmall = ui(
    12.5,
    400,
    color: AppColors.textFaint,
    height: 1.5,
  );
}
