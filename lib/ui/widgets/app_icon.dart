import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Ícones de traço do handoff (viewBox 24×24). Só o conteúdo do `<svg>`.
abstract final class AppIcons {
  static const logo =
      '<path d="M4 5.5A2.5 2.5 0 0 1 6.5 3h11A2.5 2.5 0 0 1 20 5.5v8a2.5 2.5 0 0 1-2.5 2.5H10l-4.5 4v-4A1.5 1.5 0 0 1 4 14.5z"/>'
      '<path d="M9 8v4"/><path d="M12 6.5v7"/><path d="M15 9v2"/>';
  static const history =
      '<path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5"/><path d="M12 7v5l3 2"/>';
  static const settings =
      '<path d="M4 7h10"/><path d="M18 7h2"/><circle cx="16" cy="7" r="2"/>'
      '<path d="M4 17h2"/><path d="M10 17h10"/><circle cx="8" cy="17" r="2"/>';
  static const chevronDown = '<path d="m6 9 6 6 6-6"/>';
  static const lock =
      '<rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>';
  static const transcribe =
      '<path d="M4 6h16"/><path d="M4 12h10"/><path d="M4 18h7"/><path d="m16 15 3 3 3-3"/>';
  static const film =
      '<rect x="3" y="5" width="18" height="14" rx="2"/><path d="M7 5v14"/>'
      '<path d="M17 5v14"/><path d="M3 12h18"/>';
  static const mic =
      '<rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5 11a7 7 0 0 0 14 0"/><path d="M12 18v3"/>';
  static const alert =
      '<circle cx="12" cy="12" r="9"/><path d="M12 8v5"/><path d="M12 16.5v.01"/>';
  static const check = '<path d="m5 12 5 5 9-10"/>';
  static const copy =
      '<rect x="9" y="9" width="12" height="12" rx="2"/><path d="M5 15V5a2 2 0 0 1 2-2h10"/>';
  static const refresh =
      '<path d="M21 12a9 9 0 1 1-3-6.7L21 8"/><path d="M21 3v5h-5"/>';
  static const close = '<path d="M6 6l12 12"/><path d="M18 6 6 18"/>';
  static const video =
      '<rect x="3" y="5" width="13" height="14" rx="2"/><path d="m16 10 5-3v10l-5-3"/>';
  static const plus = '<path d="M12 5v14"/><path d="M5 12h14"/>';
  static const search =
      '<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>';
  static const download =
      '<path d="M12 4v11"/><path d="m7 10 5 5 5-5"/><path d="M5 20h14"/>';
}

/// Desenha um ícone de [AppIcons] na cor e espessura pedidas. Decorativo:
/// fica fora da árvore de semântica (o rótulo vai no botão).
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.paths, {
    super.key,
    this.size = 20,
    this.strokeWidth = 1.8,
    required this.color,
  });

  final String paths;
  final double size;
  final double strokeWidth;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SvgPicture.string(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
        'stroke="#000" stroke-width="$strokeWidth" stroke-linecap="round" '
        'stroke-linejoin="round">$paths</svg>',
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}
