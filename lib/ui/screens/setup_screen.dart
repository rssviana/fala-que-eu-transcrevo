import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../src/core/system.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../controller.dart';
import '../widgets/app_icon.dart';
import '../widgets/common.dart';

final _helpUrl = Uri.parse('https://github.com/ggml-org/whisper.cpp');

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen>
    with SingleTickerProviderStateMixin, CopyFeedback {
  AppController get c => widget.controller;
  late String _os = defaultInstallTab(c.currentOs);
  bool _checking = false;
  late final _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  Future<void> _recheck() async {
    setState(() => _checking = true);
    if (!MediaQuery.of(context).disableAnimations) _spin.repeat();
    await c.recheck();
    if (!mounted) return;
    _spin.stop();
    setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final guide = installGuides[_os]!;
    final commands = installCommandsFor(_os, c.missingTools);
    return SingleChildScrollView(
      child: MainArea(
        maxWidth: 760,
        top: 36,
        bottom: 40,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 24,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Text(
                  'PRIMEIRA VEZ POR AQUI',
                  style: AppText.eyebrow.copyWith(
                    color: context.palette.accentSoftText,
                  ),
                ),
                Semantics(
                  header: true,
                  child: Text(
                    'Falta só um passo para começar',
                    style: AppText.setupH1,
                  ),
                ),
                Text(
                  'O app usa duas ferramentas gratuitas que rodam direto no seu '
                  'computador. Elas ainda não foram encontradas.',
                  style: AppText.lead,
                ),
              ],
            ),
            AppCard(
              child: Column(
                children: [
                  _DepRow(
                    name: 'ffmpeg',
                    description: 'Separa o áudio do vídeo',
                    icon: AppIcons.film,
                    found: c.ffmpegPath != null,
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.borderSubtle,
                  ),
                  _DepRow(
                    name: 'whisper-cli',
                    description: 'Transforma a fala em texto',
                    icon: AppIcons.mic,
                    found: c.whisperPath != null,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SectionLabel(
                      'Instale pelo terminal',
                      style: AppText.ui(
                        14,
                        600,
                        color: AppColors.textStrongMuted,
                      ),
                    ),
                    _OsTabs(
                      selected: _os,
                      onSelect: (os) => setState(() => _os = os),
                    ),
                  ],
                ),
                for (final cmd in commands) _commandRow(cmd),
                Text(guide.note, style: AppText.hint),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  PrimaryButton(
                    icon: AppIcons.refresh,
                    label: 'Já instalei, verificar de novo',
                    onTap: _checking ? null : _recheck,
                    iconWidget: RotationTransition(
                      turns: _spin,
                      child: AppIcon(
                        AppIcons.refresh,
                        size: 18,
                        strokeWidth: 2.2,
                        color: context.palette.onAccent,
                      ),
                    ),
                  ),
                  OutlineButton(
                    label: 'Preciso de ajuda',
                    onTap: () => launchUrl(_helpUrl),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _commandRow(String cmd) {
    final copied = isCopied(cmd);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceCode,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        spacing: 12,
        children: [
          ExcludeSemantics(
            child: Text(
              r'$',
              style: AppText.mono(13.5, color: AppColors.textFaint),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(cmd, style: AppText.mono(13.5)),
            ),
          ),
          Pressable(
            onTap: () => copyText(cmd, cmd),
            radius: 9,
            semanticLabel: 'Copiar comando',
            builder: (context, hovered, _) => AnimatedContainer(
              duration: motion(context),
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: hovered
                      ? AppColors.borderStrong
                      : AppColors.borderButton,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  AppIcon(
                    copied ? AppIcons.check : AppIcons.copy,
                    size: 16,
                    strokeWidth: copied ? 2.6 : 1.8,
                    color: copied
                        ? AppColors.successText
                        : AppColors.textStrongMuted,
                  ),
                  Text(
                    copied ? 'Copiado' : 'Copiar',
                    style: AppText.ui(
                      13,
                      500,
                      color: AppColors.textStrongMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SetupHeaderActions extends StatelessWidget {
  const SetupHeaderActions({super.key});

  @override
  Widget build(BuildContext context) => const StatusPill(ok: false);
}

class _DepRow extends StatelessWidget {
  const _DepRow({
    required this.name,
    required this.description,
    required this.icon,
    required this.found,
  });

  final String name;
  final String description;
  final String icon;
  final bool found;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        spacing: 14,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.iconTile,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: AppIcon(icon, color: AppColors.textStrongMuted),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3,
              children: [
                Text(name, style: AppText.mono(14.5)),
                Text(
                  description,
                  style: AppText.ui(13, 400, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          _Badge(found: found),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.found});
  final bool found;

  @override
  Widget build(BuildContext context) {
    final fg = found ? AppColors.successText : AppColors.warningText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: found ? AppColors.successBg : AppColors.warningBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          AppIcon(
            found ? AppIcons.check : AppIcons.alert,
            size: 14,
            strokeWidth: found ? 2.6 : 2.2,
            color: fg,
          ),
          Text(
            found ? 'Encontrado' : 'Não encontrado',
            style: AppText.ui(12.5, 500, color: fg),
          ),
        ],
      ),
    );
  }
}

class _OsTabs extends StatelessWidget {
  const _OsTabs({required this.selected, required this.onSelect});
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Sistema operacional',
      container: true,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            for (final os in installOsOrder)
              Pressable(
                onTap: () => onSelect(os),
                radius: 9,
                selected: os == selected,
                semanticLabel: installGuides[os]!.label,
                builder: (context, hovered, _) {
                  final active = os == selected;
                  return AnimatedContainer(
                    duration: motion(context),
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? AppColors.border : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      installGuides[os]!.label,
                      style: AppText.ui(
                        13,
                        600,
                        color: active || hovered
                            ? AppColors.text
                            : AppColors.textMuted,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
