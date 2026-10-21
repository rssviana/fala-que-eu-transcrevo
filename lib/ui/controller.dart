import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../src/core/binary_locator.dart';
import '../src/core/catalog.dart';
import '../src/core/export.dart';
import '../src/core/model_store.dart';
import '../src/core/pdf_export.dart';
import '../src/core/progress_plan.dart';
import '../src/core/segment.dart';
import '../src/core/system.dart';
import '../src/core/transcriber.dart';

/// As 4 telas do handoff.
enum AppScreen { setup, home, progress, result }

/// Arquivo escolhido e o que o ffmpeg contou sobre ele.
class VideoFile {
  VideoFile(this.path, this.sizeBytes);
  final String path;
  final int sizeBytes;
  Duration? duration;
  String? thumbnailPath;

  String get name => p.basename(path);
}

/// Estado do app e orquestração das classes puras de `src/core`.
class AppController extends ChangeNotifier {
  AppController({
    this.os = '',
    Map<String, String>? environment,
    bool Function(String path)? isFile,
  }) : _environment = environment,
       _isFile = isFile ?? ((path) => File(path).existsSync());

  /// `Platform.operatingSystem`; vazio = detectar.
  final String os;
  final Map<String, String>? _environment;
  final bool Function(String path) _isFile;
  String get currentOs => os.isEmpty ? Platform.operatingSystem : os;

  bool ready = false;
  AppScreen screen = AppScreen.home;

  // ---------- dependências ----------
  String? ffmpegPath;
  String? whisperPath;
  bool get binariesFound => ffmpegPath != null && whisperPath != null;
  Set<Tool> get missingTools => {
    if (ffmpegPath == null) Tool.ffmpeg,
    if (whisperPath == null) Tool.whisper,
  };

  // ---------- Tela 1 ----------
  VideoFile? video;
  String languageCode = defaultLanguageCode;
  String modelId = defaultModelId;
  String? errorMessage;
  String? errorDetails;

  WhisperModel get model => modelById(modelId);
  Language get language => languageByCode(languageCode);
  bool isModelDownloaded(WhisperModel m) => _store?.isDownloaded(m) ?? false;

  // ---------- Tela 3 ----------
  PipelineStep step = PipelineStep.extract;
  double stepFraction = 0;
  bool needsDownload = false;
  int downloadReceived = 0;
  int? downloadTotal;
  @visibleForTesting
  DateTime? startedAt;
  final List<Segment> liveSegments = [];

  double get overall =>
      overallFraction(step, stepFraction, needsDownload: needsDownload);
  Duration? get remaining => startedAt == null
      ? null
      : estimateRemaining(
          elapsed: DateTime.now().difference(startedAt!),
          fraction: overall,
        );

  // ---------- Tela 4 ----------
  /// Trechos do resultado; editáveis na Tela 4 (as edições vão para a exportação).
  final List<Segment> segments = [];
  TranscriptInfo? info;
  Duration? elapsed;

  ModelStore? _store;
  Transcriber? _transcriber;
  Directory? _tempDir;

  Future<void> init({Directory? supportDir, Directory? tempDir}) async {
    final support = supportDir ?? await getApplicationSupportDirectory();
    _store = ModelStore(Directory(p.join(support.path, 'models')));
    _tempDir = Directory(
      p.join((tempDir ?? await getTemporaryDirectory()).path, 'transcritor'),
    );
    locateBinaries();
    screen = binariesFound ? AppScreen.home : AppScreen.setup;
    ready = true;
    notifyListeners();
  }

  void locateBinaries() {
    final locator = BinaryLocator(
      os: currentOs,
      executablePath: Platform.resolvedExecutable,
      environment: _environment ?? Platform.environment,
      isFile: _isFile,
    );
    ffmpegPath = locator.find(Tool.ffmpeg);
    whisperPath = locator.find(Tool.whisper);
    notifyListeners();
  }

  /// "Já instalei, verificar de novo". Devolve se está tudo ok.
  Future<bool> recheck() async {
    // Pausa curta para o giro do ícone ser perceptível.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    locateBinaries();
    if (binariesFound) {
      screen = AppScreen.home;
      notifyListeners();
    }
    return binariesFound;
  }

  Future<void> setVideo(String path) async {
    if (screen != AppScreen.home) return;
    final file = File(path);
    final v = VideoFile(path, file.existsSync() ? file.lengthSync() : 0);
    video = v;
    errorMessage = null;
    errorDetails = null;
    notifyListeners();
    final ff = ffmpegPath;
    final temp = _tempDir;
    if (ff == null || temp == null) return;
    await temp.create(recursive: true);
    final thumb = p.join(
      temp.path,
      'thumb_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    final mediaInfo = await Transcriber(
      ffmpegPath: ff,
      whisperPath: whisperPath ?? '',
    ).probe(path, thumb);
    if (video != v) return; // trocou de vídeo enquanto lia
    v
      ..duration = mediaInfo.duration
      ..thumbnailPath = mediaInfo.thumbnailPath;
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

  void dismissError() {
    errorMessage = null;
    errorDetails = null;
    notifyListeners();
  }

  /// Linha `duração · tamanho` (+ ` · idioma` na Tela 3).
  String videoMeta({bool withLanguage = false}) {
    final v = video;
    if (v == null) return '';
    return [
      if (v.duration != null) timestampLabel(v.duration!),
      formatBytes(v.sizeBytes),
      if (withLanguage) language.shortLabel,
    ].join(' · ');
  }

  Future<void> start() async {
    final store = _store;
    final v = video;
    final temp = _tempDir;
    if (store == null || v == null || temp == null) return;
    locateBinaries();
    if (!binariesFound) {
      screen = AppScreen.setup;
      notifyListeners();
      return;
    }
    final m = model;
    final lang = language;
    info = TranscriptInfo(
      fileName: v.name,
      languageLabel: lang.label,
      modelLabel: m.label,
      date: DateTime.now(),
    );
    needsDownload = !store.isDownloaded(m);
    downloadReceived = 0;
    downloadTotal = null;
    liveSegments.clear();
    segments.clear();
    errorMessage = null;
    errorDetails = null;
    startedAt = DateTime.now();
    _setStep(PipelineStep.extract, 0);
    screen = AppScreen.progress;
    notifyListeners();

    final t = _transcriber = Transcriber(
      ffmpegPath: ffmpegPath!,
      whisperPath: whisperPath!,
    );
    await temp.create(recursive: true);
    final wav = File(
      p.join(temp.path, 'audio_${DateTime.now().microsecondsSinceEpoch}.wav'),
    );
    try {
      final duration =
          await t.extractAudio(
            v.path,
            wav.path,
            onProgress: (f) => _setStep(PipelineStep.extract, f),
          ) ??
          v.duration;
      v.duration ??= duration;

      _setStep(PipelineStep.model, 0);
      if (needsDownload) {
        await store.download(
          m,
          onProgress: (received, total) {
            downloadReceived = received;
            downloadTotal = total ?? m.approxBytes;
            _setStep(PipelineStep.model, received / downloadTotal!);
          },
        );
        if (t.cancelled) throw TranscriptionCancelled();
      }

      _setStep(PipelineStep.transcribe, 0);
      final result = await t.transcribe(
        wav.path,
        modelPath: store.pathFor(m),
        language: lang.whisperCode,
        duration: duration,
        onProgress: (f) => _setStep(PipelineStep.transcribe, f),
        onSegment: (s) {
          liveSegments.add(s);
          notifyListeners();
        },
      );
      segments
        ..clear()
        ..addAll(result);
      elapsed = DateTime.now().difference(startedAt!);
      _setStep(PipelineStep.done, 1);
      screen = AppScreen.result;
      notifyListeners();
      unawaited(_notifyDone());
    } on DownloadCancelled {
      _backHome();
    } on TranscriptionCancelled {
      _backHome();
    } on TranscriptionFailed catch (e) {
      _backHome(e.message, e.details);
    } catch (e) {
      _backHome('Algo deu errado.', e.toString());
    } finally {
      _transcriber = null;
      if (await wav.exists()) await wav.delete();
    }
  }

  void cancel() {
    _transcriber?.cancel();
    _store?.cancel();
  }

  void newTranscription() {
    video = null;
    segments.clear();
    liveSegments.clear();
    info = null;
    screen = AppScreen.home;
    notifyListeners();
  }

  void updateSegment(int index, String text) {
    final s = segments[index];
    segments[index] = Segment(start: s.start, end: s.end, text: text.trim());
    notifyListeners();
  }

  int get words => wordCount(segments);
  String get plainText => toPlainText(segments);
  String get baseName =>
      video == null ? 'transcricao' : p.basenameWithoutExtension(video!.path);
  String? get videoDir => video == null ? null : p.dirname(video!.path);

  /// Conteúdo de cada formato de exportação.
  Future<List<int>> exportBytes(String ext) async => switch (ext) {
    'txt' => _utf8(plainText),
    'srt' => _utf8(toSrt(segments)),
    'vtt' => _utf8(toVtt(segments)),
    'md' => _utf8(toMarkdown(segments, info!)),
    'pdf' => await toPdf(
      segments,
      info!,
      regularFont: await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
      boldFont: await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
    ),
    _ => throw ArgumentError(ext),
  };

  List<int> _utf8(String s) => utf8.encode(s);

  void _setStep(PipelineStep s, double f) {
    step = s;
    stepFraction = f;
    notifyListeners();
  }

  void _backHome([String? message, String? details]) {
    errorMessage = message;
    errorDetails = (details == null || details.isEmpty) ? null : details;
    liveSegments.clear();
    screen = AppScreen.home;
    notifyListeners();
  }

  /// Notificação do sistema ao terminar (o usuário pode ter minimizado).
  Future<void> _notifyDone() async {
    final cmd = notificationCommand(
      currentOs,
      'Fala que eu transcrevo!',
      'Pronto! ${info?.fileName ?? 'A transcrição'} foi transcrito.',
    );
    if (cmd == null) return;
    try {
      await Process.run(cmd.$1, cmd.$2);
    } catch (_) {
      // Sem notificação disponível: tudo bem, a tela já mostra o resultado.
    }
  }
}
