import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'catalog.dart';

class DownloadCancelled implements Exception {
  @override
  String toString() => 'Download cancelado';
}

/// Guarda os modelos ggml numa pasta local e baixa os que faltam.
/// O download vai para `<arquivo>.part` e só é renomeado ao terminar,
/// então um download interrompido nunca parece um modelo válido.
class ModelStore {
  ModelStore(this.directory);

  final Directory directory;
  HttpClient? _client;
  bool _cancelled = false;

  String pathFor(WhisperModel model) => p.join(directory.path, model.fileName);

  bool isDownloaded(WhisperModel model) => File(pathFor(model)).existsSync();

  Future<void> delete(WhisperModel model) async {
    final f = File(pathFor(model));
    if (await f.exists()) await f.delete();
  }

  /// Baixa o modelo. [onProgress] recebe bytes recebidos e total (ou null).
  Future<String> download(
    WhisperModel model, {
    required void Function(int received, int? total) onProgress,
  }) async {
    await directory.create(recursive: true);
    final target = pathFor(model);
    final part = File('$target.part');
    _cancelled = false;
    final client = _client = HttpClient()
      ..userAgent = 'Transcritor (whisper.cpp model downloader)';
    IOSink? sink;
    try {
      final request = await client.getUrl(model.downloadUri);
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Falha ao baixar o modelo (HTTP ${response.statusCode})',
          uri: model.downloadUri,
        );
      }
      final total = response.contentLength > 0 ? response.contentLength : null;
      sink = part.openWrite();
      var received = 0;
      await for (final chunk in response) {
        if (_cancelled) throw DownloadCancelled();
        sink.add(chunk);
        received += chunk.length;
        onProgress(received, total);
      }
      await sink.close();
      sink = null;
      if (total != null && received != total) {
        throw const HttpException('Download incompleto');
      }
      await part.rename(target);
      return target;
    } catch (e) {
      await sink?.close();
      if (await part.exists()) await part.delete();
      if (_cancelled) throw DownloadCancelled();
      rethrow;
    } finally {
      client.close(force: true);
      _client = null;
    }
  }

  void cancel() {
    _cancelled = true;
    _client?.close(force: true);
  }
}
