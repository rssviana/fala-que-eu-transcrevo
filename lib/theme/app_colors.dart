import 'package:flutter/material.dart';

/// Tokens de cor de design/HANDOFF.md (mesmos nomes, em camelCase).
/// Os que derivam do accent também estão em [AccentPalette], que é trocável.
abstract final class AppColors {
  // superfícies
  static const bg = Color(0xFF0C0E13);
  static const surface = Color(0xFF14171E);
  static const surfaceSunken = Color(0xFF11141A);
  static const surfaceRaised = Color(0xFF1B1F28);
  static const surfaceCode = Color(0xFF0F1217);
  static const surfaceHoverRow = Color(0xFF1A1E26);
  static const iconTile = Color(0xFF1E232D);
  static const track = Color(0xFF232834);
  // bordas
  static const border = Color(0xFF262B36);
  static const borderSubtle = Color(0xFF222731);
  static const borderHeader = Color(0xFF1E222B);
  static const borderStrong = Color(0xFF343B48);
  static const borderButton = Color(0xFF2C323D);
  // texto
  static const text = Color(0xFFECEEF2);
  static const textBody = Color(0xFFDDE1E7);
  static const textStrongMuted = Color(0xFFC9CED8);
  static const textMuted = Color(0xFFA1A8B5);
  static const textFaint = Color(0xFF8B93A1);
  // accent (coral) — valores padrão; use context.palette para o atual
  static const accent = Color(0xFFFF7A55);
  static const onAccent = Color(0xFF1A0B05);
  static const accentText = Color(0xFFFF9B7D);
  static const accentTextHover = Color(0xFFFFC2AE);
  static const accentSoftText = Color(0xFFFFB59E);
  static const accentSelectedBg = Color(0xFF1E1712);
  static const accentRing = Color(0x1AFF7A55);
  static const accentCardBg = Color(0xFF1A1410);
  static const accentCardBorder = Color(0xFF3A2A20);
  static const accentChipBg = Color(0xFF241914);
  // status
  static const success = Color(0xFF4ADE80);
  static const successText = Color(0xFF86EFAC);
  static const successBg = Color(0xFF14231A);
  static const warning = Color(0xFFFBBF24);
  static const warningText = Color(0xFFFCD34D);
  static const warningBg = Color(0xFF2A2212);
  // decorativos
  static const waveIdle = Color(0xFF3A4150);
  static const meterOff = Color(0xFF2C323D);
  static const meterSpeedOn = Color(0xFFCBD2DC);
}

/// Tokens derivados do accent. Fica no tema como extensão para dar para trocar
/// o accent depois (alternativas previstas: #7C9CFF, #5EEAD4, #FACC15).
@immutable
class AccentPalette extends ThemeExtension<AccentPalette> {
  const AccentPalette({
    required this.accent,
    required this.onAccent,
    required this.accentText,
    required this.accentTextHover,
    required this.accentSoftText,
    required this.accentSelectedBg,
    required this.accentRing,
    required this.accentCardBg,
    required this.accentCardBorder,
    required this.accentChipBg,
  });

  static const coral = AccentPalette(
    accent: AppColors.accent,
    onAccent: AppColors.onAccent,
    accentText: AppColors.accentText,
    accentTextHover: AppColors.accentTextHover,
    accentSoftText: AppColors.accentSoftText,
    accentSelectedBg: AppColors.accentSelectedBg,
    accentRing: AppColors.accentRing,
    accentCardBg: AppColors.accentCardBg,
    accentCardBorder: AppColors.accentCardBorder,
    accentChipBg: AppColors.accentChipBg,
  );

  final Color accent;
  final Color onAccent;
  final Color accentText;
  final Color accentTextHover;
  final Color accentSoftText;
  final Color accentSelectedBg;
  final Color accentRing;
  final Color accentCardBg;
  final Color accentCardBorder;
  final Color accentChipBg;

  @override
  AccentPalette copyWith({
    Color? accent,
    Color? onAccent,
    Color? accentText,
    Color? accentTextHover,
    Color? accentSoftText,
    Color? accentSelectedBg,
    Color? accentRing,
    Color? accentCardBg,
    Color? accentCardBorder,
    Color? accentChipBg,
  }) => AccentPalette(
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    accentText: accentText ?? this.accentText,
    accentTextHover: accentTextHover ?? this.accentTextHover,
    accentSoftText: accentSoftText ?? this.accentSoftText,
    accentSelectedBg: accentSelectedBg ?? this.accentSelectedBg,
    accentRing: accentRing ?? this.accentRing,
    accentCardBg: accentCardBg ?? this.accentCardBg,
    accentCardBorder: accentCardBorder ?? this.accentCardBorder,
    accentChipBg: accentChipBg ?? this.accentChipBg,
  );

  @override
  AccentPalette lerp(AccentPalette? other, double t) =>
      t < 0.5 || other == null ? this : other;
}

extension PaletteContext on BuildContext {
  AccentPalette get palette =>
      Theme.of(this).extension<AccentPalette>() ?? AccentPalette.coral;
}
