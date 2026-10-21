import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import 'app_icon.dart';

const _fast = Duration(milliseconds: 150);

/// Duração das transições, zerada quando o sistema pede menos movimento.
Duration motion(BuildContext context, [Duration d = _fast]) =>
    MediaQuery.of(context).disableAnimations ? Duration.zero : d;

/// Base de todo elemento clicável: hover, foco por teclado com o contorno
/// accent (2px, offset 2px), Enter/Espaço, cursor de mão e semântica.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.builder,
    this.onTap,
    this.radius = 12,
    this.semanticLabel,
    this.selected,
    this.tooltip,
    this.focusNode,
    this.autofocus = false,
  });

  final Widget Function(BuildContext context, bool hovered, bool focused)
  builder;
  final VoidCallback? onTap;
  final double radius;
  final String? semanticLabel;
  final bool? selected;
  final String? tooltip;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final showRing =
        _focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    Widget child = FocusableActionDetector(
      enabled: enabled,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => widget.onTap?.call(),
        ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: CustomPaint(
          foregroundPainter: showRing
              ? _FocusRingPainter(context.palette.accent, widget.radius)
              : null,
          child: widget.builder(context, _hovered && enabled, showRing),
        ),
      ),
    );
    child = Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      child: child,
    );
    if (widget.tooltip != null) {
      child = AppTooltip(message: widget.tooltip!, child: child);
    }
    return child;
  }
}

class _FocusRingPainter extends CustomPainter {
  _FocusRingPainter(this.color, this.radius);
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    // offset 2px + metade do traço de 2px
    final rect = (Offset.zero & size).inflate(3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius + 3)),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_FocusRingPainter old) =>
      old.color != color || old.radius != radius;
}

class AppTooltip extends StatelessWidget {
  const AppTooltip({super.key, required this.message, required this.child});
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: message,
    decoration: BoxDecoration(
      color: AppColors.surfaceRaised,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.border),
    ),
    textStyle: AppText.ui(12.5, 400),
    waitDuration: const Duration(milliseconds: 400),
    child: child,
  );
}

/// Padding lateral de header e conteúdo: 32px, ou 20px abaixo de 640px.
double sidePadding(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 640 ? 20 : 32;

/// Header com a marca à esquerda e [trailing] à direita.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.trailing});
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final h = sidePadding(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: h, vertical: h == 20 ? 16 : 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderHeader)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: p.accent,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: AppIcon(
                  AppIcons.logo,
                  size: 22,
                  strokeWidth: 2.2,
                  color: p.onAccent,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: 2,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Fala que eu transcrevo!',
                      style: AppText.brandName,
                    ),
                  ),
                  Text(
                    'Vídeo vira texto, sem sair do seu computador',
                    style: AppText.brandSub,
                  ),
                ],
              ),
            ],
          ),
          trailing,
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.ok});
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final bg = ok ? AppColors.successBg : AppColors.warningBg;
    final fg = ok ? AppColors.successText : AppColors.warningText;
    final dot = ok ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          Text(
            ok ? 'Tudo pronto' : 'Configuração pendente',
            style: AppText.ui(13, 500, color: fg),
          ),
        ],
      ),
    );
  }
}

/// Caixa com borda `border` que vira `borderStrong` no hover.
class _OutlinedBox extends StatelessWidget {
  const _OutlinedBox({
    required this.hovered,
    required this.child,
    this.radius = 12,
    this.height,
    this.width,
    this.padding,
    this.background = AppColors.surface,
  });

  final bool hovered;
  final Widget child;
  final double radius;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final Color background;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: motion(context),
    height: height,
    width: width,
    padding: padding,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: hovered ? AppColors.borderStrong : AppColors.border,
      ),
    ),
    // Centraliza na altura fixa sem esticar na largura.
    child: height == null ? child : Center(widthFactor: 1, child: child),
  );
}

/// Botão só de ícone do header (44×44).
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final String icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap ?? () {},
    semanticLabel: label,
    tooltip: label,
    builder: (context, hovered, _) => _OutlinedBox(
      hovered: hovered,
      width: 44,
      height: 44,
      child: AppIcon(icon, color: AppColors.textStrongMuted),
    ),
  );
}

/// Botão secundário com texto (altura 44).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconStroke = 2,
    this.strong = false,
  });

  final String icon;
  final String label;
  final VoidCallback? onTap;
  final double iconStroke;

  /// "Nova transcrição": texto `text` e peso 600.
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final color = strong ? AppColors.text : AppColors.textStrongMuted;
    return Pressable(
      onTap: onTap,
      builder: (context, hovered, _) => _OutlinedBox(
        hovered: hovered,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            AppIcon(icon, size: 16, strokeWidth: iconStroke, color: color),
            Text(
              label,
              style: AppText.ui(14, strong ? 600 : 500, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botão primário (accent). `onTap == null` = desabilitado (opacidade 0.45).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.height = 50,
    this.horizontalPadding = 24,
    this.fontSize = 15,
    this.expand = false,
    this.iconWidget,
  });

  final String icon;
  final String label;
  final VoidCallback? onTap;
  final double height;
  final double horizontalPadding;
  final double fontSize;
  final bool expand;

  /// Substitui o ícone (ex.: ícone girando).
  final Widget? iconWidget;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      radius: 14,
      builder: (context, hovered, _) => AnimatedOpacity(
        duration: motion(context),
        opacity: onTap == null ? 0.45 : 1,
        child: AnimatedContainer(
          duration: motion(context),
          height: height,
          width: expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          decoration: BoxDecoration(
            // brightness(1.06) no hover
            color: hovered
                ? Color.lerp(p.accent, Colors.white, 0.06)
                : p.accent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10,
            children: [
              iconWidget ??
                  AppIcon(icon, size: 18, strokeWidth: 2.2, color: p.onAccent),
              Text(label, style: AppText.ui(fontSize, 700, color: p.onAccent)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botão de contorno (link "Preciso de ajuda", "Continuar" em diálogos).
class OutlineButton extends StatelessWidget {
  const OutlineButton({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 50,
  });

  final String label;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    radius: 14,
    builder: (context, hovered, _) => _OutlinedBox(
      hovered: hovered,
      radius: 14,
      height: height,
      background: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Text(
        label,
        style: AppText.ui(
          14,
          500,
          color: hovered ? AppColors.text : AppColors.textStrongMuted,
        ),
      ),
    ),
  );
}

/// Cartão grande genérico (borda, raio 18, fundo surface).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.background = AppColors.surface,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.style});
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: style ?? AppText.sectionLabel);
}

/// Barra de progresso do handoff (trilho `track`, preenchimento accent).
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({super.key, required this.value, this.label});
  final double value;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return Semantics(
      label: label,
      value: '${(v * 100).round()}%',
      child: Container(
        height: 10,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.track,
          borderRadius: BorderRadius.circular(999),
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: v),
          duration: motion(context, const Duration(milliseconds: 300)),
          curve: Curves.ease,
          builder: (context, w, _) => Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: w,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.palette.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Borda tracejada arredondada (dropzone): traço 6, espaço 5.
class DashedBorderPainter extends CustomPainter {
  DashedBorderPainter({
    required this.color,
    required this.radius,
    this.strokeWidth = 1.5,
    this.dashed = true,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(strokeWidth / 2),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    if (!dashed) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final len = math.min(6.0, metric.length - d);
        canvas.drawPath(metric.extractPath(d, d + len), paint);
        d += 11;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter old) =>
      old.color != color || old.dashed != dashed || old.radius != radius;
}

/// Mostra "Copiado" por 2s depois de copiar.
mixin CopyFeedback<T extends StatefulWidget> on State<T> {
  final _copied = <Object>{};

  bool isCopied(Object key) => _copied.contains(key);

  Future<void> copyText(Object key, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied.add(key));
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied.remove(key));
  }
}

/// Conteúdo centralizado com largura máxima (já incluindo o padding, como no
/// `box-sizing: border-box` do HTML).
class MainArea extends StatelessWidget {
  const MainArea({
    super.key,
    required this.maxWidth,
    required this.child,
    this.top = 28,
    this.bottom = 32,
  });

  final double maxWidth;
  final Widget child;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    final h = sidePadding(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.fromLTRB(h, top, h, bottom),
          child: child,
        ),
      ),
    );
  }
}

/// Diálogo no estilo dos cartões do app.
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required String title,
  required String message,
  required List<Widget> Function(BuildContext context) actions,
}) => showDialog<T>(
  context: context,
  barrierColor: const Color(0xB3000000),
  builder: (context) => Dialog(
    backgroundColor: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: AppColors.border),
    ),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Text(
              title,
              style: AppText.display(22, 800, letterSpacingEm: -0.02),
            ),
            Text(
              message,
              style: AppText.ui(
                14.5,
                400,
                color: AppColors.textMuted,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 12,
              runSpacing: 12,
              children: actions(context),
            ),
          ],
        ),
      ),
    ),
  ),
);

/// Não conta para a altura intrínseca: dentro de um `IntrinsicHeight`, quem
/// define a altura da linha são os irmãos, e este filho só estica até ela
/// (como `align-items: stretch` no CSS, com rolagem própria).
class IgnoreIntrinsicHeight extends SingleChildRenderObjectWidget {
  const IgnoreIntrinsicHeight({super.key, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderIgnoreIntrinsicHeight();
}

class _RenderIgnoreIntrinsicHeight extends RenderProxyBox {
  @override
  double computeMinIntrinsicHeight(double width) => 0;

  @override
  double computeMaxIntrinsicHeight(double width) => 0;
}
