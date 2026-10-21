import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../core/catalog.dart';
import 'controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.controller});

  final AppController controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AppController get c => widget.controller;
  bool _dragging = false;

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _pickVideo() async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(label: 'Vídeos e áudios', extensions: videoExtensions),
      ],
    );
    if (file != null) c.setVideo(file.path);
  }

  void _onDrop(DropDoneDetails details) {
    setState(() => _dragging = false);
    if (c.busy || details.files.isEmpty) return;
    final path = details.files.first.path;
    if (!isSupportedMedia(path)) {
      _snack('Formato não suportado: ${p.extension(path)}');
      return;
    }
    c.setVideo(path);
  }

  Future<void> _export(String ext, String content) async {
    final location = await getSaveLocation(
      suggestedName: '${c.baseName}.$ext',
      acceptedTypeGroups: [
        XTypeGroup(label: ext.toUpperCase(), extensions: [ext]),
      ],
    );
    if (location == null) return;
    var path = location.path;
    if (p.extension(path).isEmpty) path = '$path.$ext';
    await File(path).writeAsString(content);
    _snack('Salvo em $path');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fala que eu transcrevo!')),
      body: ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          if (!c.ready) return const Center(child: CircularProgressIndicator());
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!c.binariesFound) _MissingBinaries(controller: c),
                _dropZone(context),
                const SizedBox(height: 16),
                _options(),
                const SizedBox(height: 16),
                _actions(),
                const SizedBox(height: 12),
                _statusArea(context),
                const SizedBox(height: 12),
                Expanded(child: _result(context)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _dropZone(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final video = c.videoPath;
    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: _onDrop,
      child: InkWell(
        onTap: c.busy ? null : _pickVideo,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _dragging ? scheme.primary : scheme.outlineVariant,
              width: _dragging ? 2 : 1,
            ),
            color: _dragging
                ? scheme.primaryContainer.withValues(alpha: 0.4)
                : scheme.surfaceContainerLow,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                video == null ? Icons.video_file_outlined : Icons.movie,
                size: 32,
                color: scheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                video == null
                    ? 'Arraste um vídeo aqui ou clique para escolher'
                    : p.basename(video),
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
              if (video != null)
                Text(
                  'Clique para trocar',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _options() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: c.languageCode,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Idioma',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final l in languages)
                DropdownMenuItem(
                  value: l.code,
                  child: Text(l.label, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: c.busy ? null : (v) => c.setLanguage(v!),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            initialValue: c.modelId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Modelo do Whisper',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final m in whisperModels)
                DropdownMenuItem(
                  value: m.id,
                  child: Text(
                    '${m.label} · ${m.sizeLabel} · ${m.description}'
                    '${c.isModelDownloaded(m) ? ' ✓' : ''}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: c.busy ? null : (v) => c.setModel(v!),
          ),
        ),
      ],
    );
  }

  Widget _actions() {
    final needsDownload = !c.isModelDownloaded(c.model);
    return Row(
      children: [
        FilledButton.icon(
          onPressed: c.busy || c.videoPath == null || !c.binariesFound
              ? null
              : c.start,
          icon: const Icon(Icons.subtitles_outlined),
          label: Text(
            needsDownload
                ? 'Baixar modelo (${c.model.sizeLabel}) e transcrever'
                : 'Transcrever',
          ),
        ),
        const SizedBox(width: 12),
        if (c.busy)
          OutlinedButton.icon(
            onPressed: c.cancel,
            icon: const Icon(Icons.close),
            label: const Text('Cancelar'),
          ),
      ],
    );
  }

  Widget _statusArea(BuildContext context) {
    if (c.status.isEmpty && !c.busy) return const SizedBox.shrink();
    final isError = c.phase == Phase.error;
    final color = isError ? Theme.of(context).colorScheme.error : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (c.busy) ...[
          LinearProgressIndicator(value: c.progress),
          const SizedBox(height: 6),
        ],
        Text(c.status, style: TextStyle(color: color)),
        if (isError && c.errorDetails != null)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Detalhes'),
            children: [
              SelectableText(
                c.errorDetails!,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ),
      ],
    );
  }

  Widget _result(BuildContext context) {
    if (c.segments.isEmpty) return const SizedBox.shrink();
    final done = c.phase == Phase.done;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Transcrição', style: Theme.of(context).textTheme.titleMedium),
            Wrap(
              children: [
                TextButton.icon(
                  onPressed: done
                      ? () {
                          Clipboard.setData(ClipboardData(text: c.plainText));
                          _snack('Texto copiado.');
                        }
                      : null,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar'),
                ),
                TextButton.icon(
                  onPressed: done ? () => _export('txt', c.plainText) : null,
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Exportar .txt'),
                ),
                TextButton.icon(
                  onPressed: done ? () => _export('srt', c.srt) : null,
                  icon: const Icon(Icons.closed_caption_outlined),
                  label: const Text('Exportar .srt'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                c.plainText,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MissingBinaries extends StatelessWidget {
  const _MissingBinaries({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final missing = [
      if (controller.ffmpegPath == null) 'ffmpeg',
      if (controller.whisperPath == null) 'whisper-cli',
    ].join(' e ');
    final hint = switch (Platform.operatingSystem) {
      'macos' => 'brew install ffmpeg whisper-cpp',
      'linux' =>
        'instale ffmpeg pelo gerenciador de pacotes e compile o whisper.cpp',
      _ => 'coloque ffmpeg.exe e whisper-cli.exe na pasta bin ao lado do app',
    };
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: const Icon(Icons.warning_amber),
        title: Text('Não encontrei $missing.'),
        subtitle: Text(
          'Para desenvolvimento: $hint. Depois clique em '
          '"Procurar de novo".',
        ),
        trailing: TextButton(
          onPressed: controller.locateBinaries,
          child: const Text('Procurar de novo'),
        ),
      ),
    );
  }
}
