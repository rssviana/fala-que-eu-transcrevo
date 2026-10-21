import 'package:flutter/material.dart';

/// Tokens de cor de design/HANDOFF.md (mesmos nomes, em camelCase).
/// Os que derivam do accent também estão em [AccentPalette], que é trocável.
abstract final class AppColors {
  // superfícies
  static const bg = Color(0xFF2F243A);
  static const surface = Color(0xFF3A3047);
  static const surfaceSunken = Color(0xFF281E32);
  static const surfaceRaised = Color(0xFF444054);
  static const surfaceCode = Color(0xFF241B2D);
  static const surfaceHoverRow = Color(0xFF3F354C);
  static const iconTile = Color(0xFF444054);
  static const track = Color(0xFF4A4259);
  // bordas
  static const border = Color(0xFF4A4259);
  static const borderSubtle = Color(0xFF3F354C);
  static const borderHeader = Color(0xFF3A3047);
  static const borderStrong = Color(0xFF5A5468);
  static const borderButton = Color(0xFF565068);
  // texto
  static const text = Color(0xFFF6EEEA);
  static const textBody = Color(0xFFE9E2E0);
  static const textStrongMuted = Color(0xFFD6D2D2);
  static const textMuted = Color(0xFFBEBBBB);
  static const textFaint = Color(0xFFA9A3AC);
  // accent (Salmon) — valores padrão; use context.palette para o atual
  static const accent = Color(0xFFDB8A74);
  static const onAccent = Color(0xFF2F243A);
  static const accentText = Color(0xFFFAC9B8);
  static const accentTextHover = Color(0xFFFFE3D8);
  static const accentSoftText = Color(0xFFFAC9B8);
  static const accentSelectedBg = Color(0xFF47343F);
  static const accentRing = Color(0x38DB8A74); // rgba(219,138,116,0.22)
  static const accentCardBg = Color(0xFF3D2C3E);
  static const accentCardBorder = Color(0xFF5E4049);
  static const accentChipBg = Color(0xFF4A3342);
  // status
  static const success = Color(0xFF7FD69A);
  static const successText = Color(0xFFA7E3B5);
  static const successBg = Color(0xFF2E3A3B);
  static const warning = Color(0xFFEBC062);
  static const warningText = Color(0xFFF5D58A);
  static const warningBg = Color(0xFF45383A);
  // decorativos
  static const waveIdle = Color(0xFF5A5468);
  static const meterOff = Color(0xFF565068);
  static const meterSpeedOn = Color(0xFFD6D2D2);
}

/// Tokens derivados do accent. Fica no tema como extensão para dar para trocar
/// o accent depois. Paleta da marca: Midnight Violet #2F243A, Vintage Grape
/// #444054, Silver #BEBBBB, Almond Silk #FAC9B8, Salmon #DB8A74.
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

  static const salmon = AccentPalette(
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
      Theme.of(this).extension<AccentPalette>() ?? AccentPalette.salmon;
}
