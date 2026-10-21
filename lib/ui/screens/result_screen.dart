import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../src/core/catalog.dart';
import '../../src/core/export.dart';
import '../../src/core/search.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../controller.dart';
import '../widgets/app_icon.dart';
import '../widgets/common.dart';

class ResultHeaderActions extends StatelessWidget {
  const ResultHeaderActions({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) => SecondaryButton(
    icon: AppIcons.plus,
    iconStroke: 2.2,
    label: 'Nova transcrição',
    strong: true,
    onTap: controller.newTranscription,
  );
}

/// Formatos de "Salvar como": TXT, SRT e VTT do handoff, mais MD e PDF.
const _exports = [
  ('txt', 'TXT', 'Texto simples', 'Para ler, colar ou editar'),
  ('srt', 'SRT', 'Legendas', 'YouTube, Premiere, DaVinci'),
  ('vtt', 'VTT', 'Legendas para web', 'Players HTML5 e Vimeo'),
  ('md', 'MD', 'Markdown', 'Notion, Obsidian, GitHub'),
  ('pdf', 'PDF', 'Documento PDF', 'Para imprimir ou compartilhar'),
];

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with CopyFeedback {
  AppController get c => widget.controller;
  final _search = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: AppColors.surfaceRaised,
      behavior: SnackBarBehavior.floating,
      width: 420,
      content: Text(msg, style: AppText.ui(14, 500)),
    ),
  );

  Future<void> _save(String ext) async {
    final location = await getSaveLocation(
      suggestedName: '${c.baseName}.$ext',
      initialDirectory: c.videoDir,
      acceptedTypeGroups: [
        XTypeGroup(label: ext.toUpperCase(), extensions: [ext]),
      ],
    );
    if (location == null) return;
    var path = location.path;
    if (p.extension(path).isEmpty) path = '$path.$ext';
    try {
      await File(path).writeAsBytes(await c.exportBytes(ext));
      _snack('Salvo em ${p.basename(path)}');
    } catch (e) {
      _snack('Não foi possível salvar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        SingleActivator(
          LogicalKeyboardKey.keyF,
          meta: Platform.isMacOS,
          control: !Platform.isMacOS,
        ): _searchFocus.requestFocus,
      },
      child: Focus(
        autofocus: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = sidePadding(context);
            final inner = (constraints.maxWidth.clamp(0, 1120) - 2 * h)
                .toDouble();
            // O painel acompanha o conteúdo, até a altura visível da janela;
            // daí em diante rola por dentro. A página toda rola se precisar.
            final maxPanel = (constraints.maxHeight - 60).clamp(
              320.0,
              double.infinity,
            );
            final transcript = ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxPanel),
              child: _transcript(context),
            );
            final side = _side(context);
            // transcrição 560 + lateral 300 + gap 24 → em linha a partir de 884.
            final Widget content = inner >= 884
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 24,
                    children: [
                      Expanded(child: transcript),
                      SizedBox(width: 300, child: side),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 24,
                    children: [transcript, side],
                  );
            return SingleChildScrollView(
              child: MainArea(maxWidth: 1120, child: content),
            );
          },
        ),
      ),
    );
  }

  Widget _transcript(BuildContext context) {
    final query = _search.text;
    return Semantics(
      label: 'Transcrição',
      container: true,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surfaceSunken,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    spacing: 3,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Text(
                          c.video?.name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.ui(15, 600),
                        ),
                      ),
                      Text(
                        'Clique em um trecho para editar',
                        style: AppText.ui(
                          12.5,
                          400,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 240, child: _searchField(context)),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 16),
                itemCount: c.segments.length,
                itemBuilder: (context, i) => _SegmentRow(
                  key: ValueKey(i),
                  index: i,
                  controller: c,
                  query: query,
                  onCopyTime: (label) {
                    copyText('ts$i', label);
                    _snack('Horário $label copiado');
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchField(BuildContext context) {
    final pal = context.palette;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );
    return SizedBox(
      height: 44,
      child: TextField(
        controller: _search,
        focusNode: _searchFocus,
        onChanged: (_) => setState(() {}),
        style: AppText.ui(14, 400),
        cursorColor: pal.accent,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          labelText: null,
          hintText: 'Buscar no texto',
          hintStyle: AppText.ui(14, 400, color: AppColors.textFaint),
          semanticCounterText: 'Buscar na transcrição',
          filled: true,
          fillColor: AppColors.surface,
          isDense: true,
          constraints: const BoxConstraints.tightFor(height: 44),
          contentPadding: const EdgeInsets.fromLTRB(0, 12, 14, 12),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 14, right: 8),
            child: AppIcon(
              AppIcons.search,
              size: 16,
              strokeWidth: 2,
              color: AppColors.textFaint,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 38),
          enabledBorder: border(AppColors.border),
          focusedBorder: border(pal.accent),
          border: border(AppColors.border),
        ),
      ),
    );
  }

  Widget _side(BuildContext context) {
    final pal = context.palette;
    final duration = c.video?.duration;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: pal.accentCardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: pal.accentCardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 14,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: pal.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: AppIcon(
                  AppIcons.check,
                  size: 22,
                  strokeWidth: 2.6,
                  color: pal.onAccent,
                ),
              ),
              Text('Pronto! Seu texto está aqui.', style: AppText.doneTitle),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  _stat(
                    duration == null ? '—' : timestampLabel(duration),
                    'de vídeo',
                  ),
                  _stat(formatThousands(c.words), 'palavras'),
                  _stat(
                    c.elapsed == null ? '—' : elapsedLabel(c.elapsed!),
                    'para fazer',
                  ),
                ],
              ),
            ],
          ),
        ),
        PrimaryButton(
          icon: AppIcons.copy,
          label: isCopied('all') ? 'Copiado!' : 'Copiar todo o texto',
          height: 52,
          expand: true,
          onTap: () => copyText('all', c.plainText),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            const SectionLabel('Salvar como'),
            for (final (ext, chip, title, desc) in _exports)
              _ExportButton(
                chip: chip,
                title: title,
                description: desc,
                onTap: () => _save(ext),
              ),
          ],
        ),
      ],
    );
  }

  Widget _stat(String value, String label) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(value, style: AppText.mono(15)),
        Text(label, style: AppText.ui(12, 400, color: AppColors.textMuted)),
      ],
    ),
  );
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.chip,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String chip;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pal = context.palette;
    return Pressable(
      onTap: onTap,
      radius: 14,
      semanticLabel: 'Salvar como $chip: $title',
      builder: (context, hovered, _) => AnimatedContainer(
        duration: motion(context),
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hovered ? AppColors.borderStrong : AppColors.border,
          ),
        ),
        child: Row(
          spacing: 12,
          children: [
            Container(
              constraints: const BoxConstraints(minWidth: 34),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: pal.accentChipBg,
                borderRadius: BorderRadius.circular(7),
              ),
              alignment: Alignment.center,
              child: Text(
                chip,
                style: AppText.mono(12, color: pal.accentSoftText),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(title, style: AppText.ui(14, 600)),
                  Text(
                    description,
                    style: AppText.ui(12.5, 400, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const AppIcon(
              AppIcons.download,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Trecho da transcrição: horário (clique copia) + texto (clique edita).
class _SegmentRow extends StatefulWidget {
  const _SegmentRow({
    super.key,
    required this.index,
    required this.controller,
    required this.query,
    required this.onCopyTime,
  });

  final int index;
  final AppController controller;
  final String query;
  final ValueChanged<String> onCopyTime;

  @override
  State<_SegmentRow> createState() => _SegmentRowState();
}

class _SegmentRowState extends State<_SegmentRow> {
  bool _hovered = false;
  bool _editing = false;
  late final _text = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus && _editing) _commit();
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _edit() {
    _text.text = widget.controller.segments[widget.index].text;
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _commit() {
    widget.controller.updateSegment(widget.index, _text.text);
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.controller.segments[widget.index];
    final pal = context.palette;
    final ts = timestampLabel(s.start);
    final textStyle = AppText.ui(
      15.5,
      400,
      color: AppColors.textBody,
      height: 1.65,
    );
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: motion(context),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _hovered || _editing
              ? AppColors.surfaceHoverRow
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 56 + 14,
              child: Align(
                alignment: Alignment.topLeft,
                child: Pressable(
                  onTap: () => widget.onCopyTime(ts),
                  radius: 4,
                  tooltip: 'Copiar horário',
                  semanticLabel: 'Copiar horário $ts',
                  builder: (context, hovered, _) => Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      ts,
                      style: AppText.mono(
                        12,
                        color: hovered
                            ? pal.accentTextHover
                            : pal.accentSoftText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _editing
                  ? CallbackShortcuts(
                      bindings: {
                        const SingleActivator(LogicalKeyboardKey.escape): () =>
                            setState(() => _editing = false),
                        const SingleActivator(LogicalKeyboardKey.enter):
                            _commit,
                      },
                      child: TextField(
                        controller: _text,
                        focusNode: _focus,
                        maxLines: null,
                        style: textStyle,
                        cursorColor: pal.accent,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                        ),
                      ),
                    )
                  : Pressable(
                      onTap: _edit,
                      radius: 6,
                      semanticLabel: 'Editar trecho: ${s.text}',
                      builder: (context, _, _) => Align(
                        alignment: Alignment.topLeft,
                        child: Text.rich(
                          _highlighted(s.text, widget.query, textStyle, pal),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  TextSpan _highlighted(
    String text,
    String query,
    TextStyle style,
    AccentPalette pal,
  ) {
    final ranges = matchRanges(text, query);
    if (ranges.isEmpty) return TextSpan(text: text, style: style);
    final spans = <TextSpan>[];
    var pos = 0;
    for (final (start, end) in ranges) {
      if (start > pos) spans.add(TextSpan(text: text.substring(pos, start)));
      spans.add(
        TextSpan(
          text: text.substring(start, end),
          style: TextStyle(
            color: pal.accentSoftText,
            backgroundColor: pal.accentSelectedBg,
          ),
        ),
      );
      pos = end;
    }
    if (pos < text.length) spans.add(TextSpan(text: text.substring(pos)));
    return TextSpan(style: style, children: spans);
  }
}
