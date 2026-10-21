import 'dart:async';

import 'package:flutter/material.dart';

import '../../src/core/catalog.dart';
import '../../src/core/export.dart';
import '../../src/core/progress_plan.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../controller.dart';
import '../widgets/app_icon.dart';
import '../widgets/common.dart';
import '../widgets/file_card.dart';

class ProgressHeaderActions extends StatelessWidget {
  const ProgressHeaderActions({super.key, required this.controller});
  final AppController controller;

  Future<void> _confirmCancel(BuildContext context) async {
    final ok = await showAppDialog<bool>(
      context,
      title: 'Cancelar a transcrição?',
      message: 'O que já foi transcrito até agora será descartado.',
      actions: (ctx) => [
        OutlineButton(
          label: 'Continuar transcrevendo',
          height: 44,
          onTap: () => Navigator.of(ctx).pop(false),
        ),
        PrimaryButton(
          icon: AppIcons.close,
          label: 'Cancelar',
          height: 44,
          onTap: () => Navigator.of(ctx).pop(true),
        ),
      ],
    );
    if (ok == true) controller.cancel();
  }

  @override
  Widget build(BuildContext context) => SecondaryButton(
    icon: AppIcons.close,
    label: 'Cancelar',
    onTap: () => _confirmCancel(context),
  );
}

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  AppController get c => widget.controller;
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    // Atualiza a estimativa de tempo mesmo sem novos eventos.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final left = _leftColumn(context);
        final live = _LivePreview(controller: c);
        final h = sidePadding(context);
        final inner = (constraints.maxWidth.clamp(0, 1080) - 2 * h).toDouble();
        // esquerda 320 + prévia 480 + gap 24 → em linha a partir de 824.
        // A prévia acompanha a altura da coluna da esquerda e rola por dentro.
        final Widget content = inner >= 824
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 24,
                  children: [
                    SizedBox(width: 320 + (inner - 824) / 1000, child: left),
                    Expanded(child: IgnoreIntrinsicHeight(child: live)),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 24,
                children: [
                  left,
                  SizedBox(height: 420, child: live),
                ],
              );
        return SingleChildScrollView(
          child: MainArea(maxWidth: 1080, child: content),
        );
      },
    );
  }

  Widget _leftColumn(BuildContext context) {
    final pct = (c.overall * 100).floor().clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 18,
      children: [
        FileCard(controller: c, withLanguage: true),
        AppCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text.rich(
                    TextSpan(
                      text: '$pct',
                      style: AppText.percent,
                      children: [
                        TextSpan(text: '%', style: AppText.percentSign),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      etaLabel(c.remaining),
                      textAlign: TextAlign.right,
                      style: AppText.ui(13, 400, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
              AppProgressBar(
                value: c.overall,
                label: 'Progresso da transcrição',
              ),
              const SizedBox(height: 10),
              _Steps(controller: c),
            ],
          ),
        ),
        Text(
          'Pode minimizar a janela. A gente avisa quando terminar.',
          style: AppText.hint,
        ),
      ],
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final m = c.model;
    final modelLabel = c.step == PipelineStep.model && c.needsDownload
        ? 'Baixando modelo ${m.label} · ${formatBytes(c.downloadReceived)} '
              'de ${formatBytes(c.downloadTotal ?? m.approxBytes)}'
        : 'Modelo ${m.label} pronto';
    final steps = [
      (PipelineStep.extract, 'Áudio separado do vídeo'),
      (PipelineStep.model, modelLabel),
      (PipelineStep.transcribe, 'Transcrevendo a fala'),
      (PipelineStep.done, 'Texto pronto para exportar'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 14,
      children: [
        for (final (s, label) in steps)
          _StepRow(
            label: label,
            state: s.index < c.step.index
                ? _StepState.done
                : s == c.step
                ? _StepState.current
                : _StepState.todo,
          ),
      ],
    );
  }
}

enum _StepState { done, current, todo }

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.state});
  final String label;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    final icon = switch (state) {
      _StepState.done => Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: AppColors.successBg,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const AppIcon(
          AppIcons.check,
          size: 14,
          strokeWidth: 2.6,
          color: AppColors.successText,
        ),
      ),
      _StepState.current => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: accent, width: 2),
        ),
        alignment: Alignment.center,
        child: _Pulse(
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
        ),
      ),
      _StepState.todo => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderStrong, width: 2),
        ),
      ),
    };
    final style = switch (state) {
      _StepState.done => AppText.ui(14, 400, color: AppColors.textMuted),
      _StepState.current => AppText.ui(14, 600),
      _StepState.todo => AppText.ui(14, 400, color: AppColors.textFaint),
    };
    return Semantics(
      label:
          '$label, ${switch (state) {
            _StepState.done => 'concluída',
            _StepState.current => 'em andamento',
            _StepState.todo => 'pendente',
          }}',
      excludeSemantics: true,
      child: Row(
        spacing: 12,
        children: [
          icon,
          Expanded(child: Text(label, style: style)),
        ],
      ),
    );
  }
}

/// Pulso de opacidade 1 → 0.35 (1.4s), desligado com movimento reduzido.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});
  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.value = 0;
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(
      begin: 1.0,
      end: 0.35,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
    child: widget.child,
  );
}

/// Cursor de 2×18px piscando (1s).
class _Caret extends StatefulWidget {
  const _Caret();

  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> {
  Timer? _t;
  bool _on = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _t?.cancel();
    if (!MediaQuery.of(context).disableAnimations) {
      _t = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (mounted) setState(() => _on = !_on);
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: _on ? 1 : 0,
    child: Container(
      width: 2,
      height: 18,
      margin: const EdgeInsets.only(left: 3),
      color: context.palette.accent,
    ),
  );
}

class _LivePreview extends StatefulWidget {
  const _LivePreview({required this.controller});
  final AppController controller;

  @override
  State<_LivePreview> createState() => _LivePreviewState();
}

class _LivePreviewState extends State<_LivePreview> {
  final _scroll = ScrollController();
  int _lastCount = 0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final segs = widget.controller.liveSegments;
    if (segs.length != _lastCount) {
      _lastCount = segs.length;
      // Acompanha o fim do texto.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: motion(context, const Duration(milliseconds: 250)),
            curve: Curves.easeOut,
          );
        }
      });
    }
    final pal = context.palette;
    return Semantics(
      label: 'Prévia ao vivo',
      container: true,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surfaceSunken,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Prévia ao vivo', style: AppText.ui(14, 600)),
                  ),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: pal.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'escrevendo…',
                    style: AppText.ui(12.5, 400, color: pal.accentSoftText),
                  ),
                ],
              ),
            ),
            Expanded(
              child: segs.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'O texto aparece aqui assim que a fala começar a ser transcrita.',
                          textAlign: TextAlign.center,
                          style: AppText.hint,
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: _scroll,
                      padding: const EdgeInsets.all(20),
                      itemCount: segs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 18),
                      itemBuilder: (context, i) => _line(segs, i),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(List segs, int i) {
    final s = segs[i];
    final n = segs.length;
    final writing = i == n - 1;
    final recent = i >= n - 4 && !writing; // 3 últimos antes do atual
    final color = writing
        ? AppColors.text
        : recent
        ? AppColors.textStrongMuted
        : AppColors.textFaint;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SizedBox(
          width: 64 + 14,
          child: Text(
            timestampLabel(s.start),
            style: AppText.mono(12, color: AppColors.textFaint),
          ),
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: s.text,
              style: AppText.ui(15.5, 400, color: color, height: 1.6),
              children: [
                if (writing)
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: _Caret(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
