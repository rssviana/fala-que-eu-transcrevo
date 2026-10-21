import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../src/core/catalog.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../controller.dart';
import '../widgets/app_icon.dart';
import '../widgets/common.dart';
import '../widgets/file_card.dart';

class HomeHeaderActions extends StatelessWidget {
  const HomeHeaderActions({super.key});

  void _soon(BuildContext context, String title) => showAppDialog<void>(
    context,
    title: title,
    message: 'Esta tela ainda está sendo desenhada. Em breve.',
    actions: (ctx) => [
      OutlineButton(
        label: 'Fechar',
        height: 44,
        onTap: () => Navigator.of(ctx).pop(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 10,
    children: [
      const StatusPill(ok: true),
      HeaderIconButton(
        icon: AppIcons.history,
        label: 'Histórico',
        onTap: () => _soon(context, 'Histórico'),
      ),
      HeaderIconButton(
        icon: AppIcons.settings,
        label: 'Configurações',
        onTap: () => _soon(context, 'Configurações'),
      ),
    ],
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppController get c => widget.controller;
  bool _dragging = false;

  Future<void> _pickVideo() async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(label: 'Vídeos e áudios', extensions: videoExtensions),
      ],
    );
    if (file != null) await c.setVideo(file.path);
  }

  void _onDrop(DropDoneDetails details) {
    setState(() => _dragging = false);
    if (details.files.isEmpty) return;
    final path = details.files.first.path;
    if (!isSupportedMedia(path)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceRaised,
          content: Text(
            'Formato não suportado: ${p.extension(path)}',
            style: AppText.ui(14, 500),
          ),
        ),
      );
      return;
    }
    c.setVideo(path);
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        SingleActivator(
          LogicalKeyboardKey.keyO,
          meta: Platform.isMacOS,
          control: !Platform.isMacOS,
        ): _pickVideo,
      },
      child: Focus(
        autofocus: true,
        child: SingleChildScrollView(
          child: MainArea(
            maxWidth: 1040,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 22,
              children: [
                if (c.errorMessage != null) _ErrorCard(controller: c),
                _dropzone(context),
                _options(),
                _footer(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dropzone(BuildContext context) {
    final pal = context.palette;
    final video = c.video;
    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: _onDrop,
      child: Pressable(
        onTap: _pickVideo,
        radius: 22,
        semanticLabel: video == null
            ? 'Solte seu vídeo aqui ou escolha um arquivo no computador'
            : 'Vídeo escolhido: ${video.name}. Trocar vídeo',
        builder: (context, hovered, _) => CustomPaint(
          foregroundPainter: DashedBorderPainter(
            color: _dragging
                ? pal.accent
                : (hovered ? AppColors.textFaint : AppColors.borderStrong),
            radius: 22,
            dashed: !_dragging,
          ),
          child: AnimatedContainer(
            duration: motion(context),
            width: double.infinity,
            padding: video == null
                ? const EdgeInsets.fromLTRB(24, 44, 24, 40)
                : const EdgeInsets.fromLTRB(24, 32, 24, 30),
            decoration: BoxDecoration(
              color: _dragging ? pal.accentSelectedBg : AppColors.surfaceSunken,
              borderRadius: BorderRadius.circular(22),
            ),
            child: video == null ? _emptyDrop(context) : _fileDrop(context),
          ),
        ),
      ),
    );
  }

  Widget _emptyDrop(BuildContext context) {
    final pal = context.palette;
    return Column(
      spacing: 18,
      children: [
        const _Wave(),
        Text(
          'Solte seu vídeo aqui',
          style: AppText.dropzoneTitle,
          textAlign: TextAlign.center,
        ),
        Text.rich(
          TextSpan(
            style: AppText.ui(15, 400, color: AppColors.textMuted),
            children: [
              const TextSpan(text: 'ou '),
              TextSpan(
                text: 'escolha um arquivo',
                style: TextStyle(
                  color: pal.accentText,
                  decoration: TextDecoration.underline,
                  decorationColor: pal.accentText,
                ),
              ),
              const TextSpan(text: ' no computador'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final f in featuredFormats)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    f,
                    style: AppText.mono(11.5, color: AppColors.textMuted),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fileDrop(BuildContext context) {
    final pal = context.palette;
    return Column(
      spacing: 16,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: FileCard(controller: c),
        ),
        Text(
          'Trocar vídeo',
          style: AppText.ui(14, 500, color: pal.accentText).copyWith(
            decoration: TextDecoration.underline,
            decorationColor: pal.accentText,
          ),
        ),
      ],
    );
  }

  Widget _options() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final lang = _LanguageColumn(controller: c);
        final models = _ModelGrid(controller: c);
        // Idioma 240 + Qualidade 560 + gap 22 → em linha a partir de 822.
        // flex 1 vs 999: o idioma fica praticamente nos 240px da base.
        if (constraints.maxWidth >= 822) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 22,
            children: [
              SizedBox(
                width: 240 + (constraints.maxWidth - 822) / 1000,
                child: lang,
              ),
              Expanded(child: models),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 22,
          children: [lang, models],
        );
      },
    );
  }

  Widget _footer(BuildContext context) {
    final hasVideo = c.video != null;
    final downloaded = c.isModelDownloaded(c.model);
    final hint = !hasVideo
        ? 'Escolha um vídeo para começar'
        : downloaded
        ? null
        : 'O modelo será baixado antes (${c.model.sizeLabel})';
    return Container(
      padding: const EdgeInsets.only(top: 18),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderHeader)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              const AppIcon(
                AppIcons.lock,
                size: 18,
                color: AppColors.successText,
              ),
              Flexible(
                child: Text(
                  'Tudo acontece no seu computador. Nenhum arquivo é enviado para a internet.',
                  style: AppText.ui(13, 400, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 14,
            children: [
              if (hint != null) Text(hint, style: AppText.hint),
              PrimaryButton(
                icon: AppIcons.transcribe,
                label: 'Transcrever',
                horizontalPadding: 26,
                fontSize: 15.5,
                onTap: hasVideo ? c.start : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Onda sonora decorativa do dropzone.
class _Wave extends StatelessWidget {
  const _Wave();

  static const _heights = [
    14, 22, 34, 26, 46, 58, 40, 28, 18, 30, 52, 64, 48, 36, //
    24, 40, 56, 44, 30, 20, 34, 50, 38, 26, 16, 24, 18, 12,
  ];

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    return ExcludeSemantics(
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 5,
          children: [
            for (var i = 0; i < _heights.length; i++)
              Container(
                width: 5,
                height: _heights[i].toDouble(),
                decoration: BoxDecoration(
                  color: i >= 9 && i <= 19 ? accent : AppColors.waveIdle,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LanguageColumn extends StatelessWidget {
  const _LanguageColumn({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final pal = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        const SectionLabel('Idioma do vídeo'),
        Semantics(
          label: 'Idioma do vídeo',
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: controller.languageCode,
                isExpanded: true,
                focusColor: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                dropdownColor: AppColors.surfaceRaised,
                padding: const EdgeInsets.only(left: 16, right: 16),
                icon: const AppIcon(
                  AppIcons.chevronDown,
                  size: 18,
                  strokeWidth: 2,
                  color: AppColors.textMuted,
                ),
                style: AppText.ui(15, 500),
                selectedItemBuilder: (context) => [
                  for (final l in languages)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Text(
                          l.label,
                          style: AppText.ui(15, 500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
                items: [
                  for (final l in languages)
                    DropdownMenuItem(
                      value: l.code,
                      child: Text(
                        l.label,
                        style: AppText.ui(
                          15,
                          500,
                          color: l.code == controller.languageCode
                              ? pal.accent
                              : AppColors.text,
                        ),
                      ),
                    ),
                ],
                onChanged: (v) => controller.setLanguage(v!),
              ),
            ),
          ),
        ),
        Text(
          'Escolher o idioma certo deixa a transcrição mais precisa.',
          style: AppText.hintSmall,
        ),
      ],
    );
  }
}

class _ModelGrid extends StatelessWidget {
  const _ModelGrid({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Qualidade da transcrição'),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            // repeat(auto-fit, minmax(120px, 1fr)), gap 8
            final cols = ((constraints.maxWidth + 8) / 128).floor().clamp(
              1,
              whisperModels.length,
            );
            final rows = <List<WhisperModel>>[];
            for (var i = 0; i < whisperModels.length; i += cols) {
              rows.add(
                whisperModels.sublist(
                  i,
                  (i + cols).clamp(0, whisperModels.length),
                ),
              );
            }
            return Column(
              spacing: 8,
              children: [
                for (final row in rows)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 8,
                      children: [
                        for (var i = 0; i < cols; i++)
                          Expanded(
                            child: i < row.length
                                ? _ModelCard(
                                    model: row[i],
                                    selected: row[i].id == controller.modelId,
                                    downloaded: controller.isModelDownloaded(
                                      row[i],
                                    ),
                                    onTap: () => controller.setModel(row[i].id),
                                  )
                                : const SizedBox.shrink(),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ModelCard extends StatelessWidget {
  const _ModelCard({
    required this.model,
    required this.selected,
    required this.downloaded,
    required this.onTap,
  });

  final WhisperModel model;
  final bool selected;
  final bool downloaded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pal = context.palette;
    final size = downloaded
        ? '✓ Já baixado · ${model.sizeLabel}'
        : 'Baixar · ${model.sizeLabel}';
    return Pressable(
      onTap: onTap,
      radius: 14,
      selected: selected,
      semanticLabel:
          '${model.label}${model.recommended ? ', ideal' : ''}. '
          'Rapidez ${model.speed} de 5, precisão ${model.accuracy} de 5. $size',
      builder: (context, hovered, _) => AnimatedContainer(
        duration: motion(context),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? pal.accentSelectedBg : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            width: 1.5,
            color: selected
                ? pal.accent
                : (hovered ? AppColors.borderStrong : AppColors.border),
          ),
          boxShadow: selected
              ? [BoxShadow(color: pal.accentRing, spreadRadius: 4)]
              : const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Row(
              children: [
                Expanded(child: Text(model.label, style: AppText.modelName)),
                if (model.recommended)
                  Text(
                    'IDEAL',
                    style: AppText.ui(
                      10.5,
                      600,
                      color: pal.accentSoftText,
                      letterSpacingEm: 0.06,
                    ),
                  ),
              ],
            ),
            Column(
              spacing: 6,
              children: [
                _Meter('Rapidez', model.speed, AppColors.meterSpeedOn),
                _Meter('Precisão', model.accuracy, pal.accent),
              ],
            ),
            Text(
              size,
              style: AppText.mono(
                11.5,
                color: downloaded ? AppColors.successText : AppColors.textFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter(this.label, this.value, this.onColor);
  final String label;
  final int value;
  final Color onColor;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: AppText.ui(11.5, 400, color: AppColors.textMuted),
        ),
      ),
      Row(
        spacing: 3,
        children: [
          for (var i = 0; i < 5; i++)
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: i < value ? onColor : AppColors.meterOff,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    ],
  );
}

/// Erro da última tentativa (não está no mock): mesmo estilo dos selos de aviso.
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: AppIcon(
              AppIcons.alert,
              size: 18,
              strokeWidth: 2.2,
              color: AppColors.warningText,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Text(
                  controller.errorMessage!,
                  style: AppText.ui(14, 600, color: AppColors.warningText),
                ),
                if (controller.errorDetails != null)
                  SelectableText(
                    controller.errorDetails!,
                    maxLines: 6,
                    style: AppText.mono(11.5, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
          Pressable(
            onTap: controller.dismissError,
            semanticLabel: 'Fechar aviso',
            tooltip: 'Fechar',
            builder: (context, hovered, _) => SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: AppIcon(
                  AppIcons.close,
                  size: 16,
                  strokeWidth: 2,
                  color: hovered ? AppColors.text : AppColors.warningText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
