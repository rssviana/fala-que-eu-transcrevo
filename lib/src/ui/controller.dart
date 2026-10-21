import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/binary_locator.dart';
import '../core/catalog.dart';
import '../core/export.dart';
import '../core/model_store.dart';
import '../core/pdf_export.dart';
import '../core/segment.dart';
import '../core/transcriber.dart';

enum Phase { idle, downloading, extracting, transcribing, done, error }

/// Estado da tela e orquestração das classes de `core`.
class AppController extends ChangeNotifier {
  AppController();

  String? videoPath;
  String languageCode = defaultLanguageCode;
  String modelId = defaultModelId;

  Phase phase = Phase.idle;
  double? progress;
  String status = '';
  String? errorDetails;
  final List<Segment> segments = [];

  String? ffmpegPath;
  String? whisperPath;
  ModelStore? _store;
  Transcriber? _transcriber;
  bool _ready = false;

  bool get ready => _ready;
  bool get busy =>
      phase == Phase.downloading ||
      phase == Phase.extracting ||
      phase == Phase.transcribing;
  bool get binariesFound => ffmpegPath != null && whisperPath != null;
  WhisperModel get model => modelById(modelId);
  String get modelsDir => _store?.directory.path ?? '';
  bool isModelDownloaded(WhisperModel m) => _store?.isDownloaded(m) ?? false;

  /// Cabeçalho do Markdown/PDF, fixado no início da transcrição (o usuário
  /// pode trocar idioma e modelo depois sem afetar o resultado).
  TranscriptInfo? info;

  String get plainText => toPlainText(segments);
  String get srt => toSrt(segments);
  String get markdown => toMarkdown(segments, info!);

  Future<Uint8List> pdf() async => toPdf(
    segments,
    info!,
    regularFont: await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
    boldFont: await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
  );
  String get baseName => videoPath == null
      ? 'transcricao'
      : p.basenameWithoutExtension(videoPath!);

  Future<void> init({Directory? supportDir}) async {
    final support = supportDir ?? await getApplicationSupportDirectory();
    _store = ModelStore(Directory(p.join(support.path, 'models')));
    locateBinaries();
    _ready = true;
    notifyListeners();
  }

  void locateBinaries() {
    final locator = BinaryLocator(
      os: Platform.operatingSystem,
      executablePath: Platform.resolvedExecutable,
      environment: Platform.environment,
      isFile: (path) => File(path).existsSync(),
    );
    ffmpegPath = locator.find(Tool.ffmpeg);
    whisperPath = locator.find(Tool.whisper);
    notifyListeners();
  }

  void setVideo(String path) {
    if (busy) return;
    videoPath = path;
    if (phase == Phase.error || phase == Phase.done) {
      phase = Phase.idle;
      status = '';
      errorDetails = null;
      segments.clear();
    }
    notifyListeners();
  }

  void setLanguage(String code) {
    languageCode = code;
    notifyListeners();
  }

  void setModel(String id) {
    modelId = id;
    notifyListeners();
  }

  Future<void> start() async {
    final store = _store;
    final video = videoPath;
    if (store == null || video == null || busy) return;
    locateBinaries();
    if (!binariesFound) {
      _fail(
        'ffmpeg ou whisper-cli não encontrado.',
        'Veja o README para instalar ou empacotar os binários.',
      );
      return;
    }
    segments.clear();
    errorDetails = null;
    final m = model;
    final language = languages.firstWhere((l) => l.code == languageCode);
    info = TranscriptInfo(
      fileName: p.basename(video),
      languageLabel: language.label,
      modelLabel: m.label,
      date: DateTime.now(),
    );
    try {
      if (!store.isDownloaded(m)) {
        _set(Phase.downloading, 0, 'Baixando modelo ${m.label}…');
        await store.download(
          m,
          onProgress: (received, total) {
            _set(
              Phase.downloading,
              total == null ? null : received / total,
              'Baixando modelo ${m.label}… ${formatBytes(received)}'
              '${total == null ? '' : ' de ${formatBytes(total)}'}',
            );
          },
        );
      }
      final temp = await getTemporaryDirectory();
      final t = _transcriber = Transcriber(
        ffmpegPath: ffmpegPath!,
        whisperPath: whisperPath!,
        tempDir: Directory(p.join(temp.path, 'transcritor')),
      );
      final result = await t.run(
        input: video,
        modelPath: store.pathFor(m),
        language: language.whisperCode,
        onProgress: (stage, overall) => _set(
          stage == Stage.extracting ? Phase.extracting : Phase.transcribing,
          overall,
          stage == Stage.extracting
              ? 'Extraindo áudio…'
              : 'Transcrevendo… ${(overall * 100).floor()}%',
        ),
        onSegment: (s) {
          segments.add(s);
          notifyListeners();
        },
      );
      segments
        ..clear()
        ..addAll(result);
      _set(
        Phase.done,
        1,
        result.isEmpty ? 'Nenhuma fala reconhecida.' : 'Transcrição concluída.',
      );
    } on DownloadCancelled {
      _set(Phase.idle, null, 'Download cancelado.');
    } on TranscriptionCancelled {
      segments.clear();
      _set(Phase.idle, null, 'Transcrição cancelada.');
    } on TranscriptionFailed catch (e) {
      _fail(e.message, e.details);
    } catch (e) {
      _fail('Algo deu errado.', e.toString());
    } finally {
      _transcriber = null;
    }
  }

  void cancel() {
    if (phase == Phase.downloading) _store?.cancel();
    _transcriber?.cancel();
  }

  void _set(Phase ph, double? prog, String msg) {
    phase = ph;
    progress = prog;
    status = msg;
    notifyListeners();
  }

  void _fail(String msg, String details) {
    errorDetails = details.isEmpty ? null : details;
    _set(Phase.error, null, msg);
  }
}
