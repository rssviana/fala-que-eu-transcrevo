/// Catálogo de modelos do Whisper e idiomas suportados pela UI.
library;

class WhisperModel {
  const WhisperModel({
    required this.id,
    required this.label,
    required this.approxBytes,
    required this.description,
  });

  /// Nome usado no arquivo `ggml-<id>.bin` do repositório do whisper.cpp.
  final String id;
  final String label;
  final int approxBytes;
  final String description;

  String get fileName => 'ggml-$id.bin';

  Uri get downloadUri => Uri.parse(
    'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/$fileName',
  );

  String get sizeLabel => formatBytes(approxBytes);
}

const _mb = 1024 * 1024;

const whisperModels = <WhisperModel>[
  WhisperModel(
    id: 'tiny',
    label: 'Tiny',
    approxBytes: 75 * _mb,
    description: 'Muito rápido, precisão baixa',
  ),
  WhisperModel(
    id: 'base',
    label: 'Base',
    approxBytes: 142 * _mb,
    description: 'Rápido, bom para testes',
  ),
  WhisperModel(
    id: 'small',
    label: 'Small',
    approxBytes: 466 * _mb,
    description: 'Equilíbrio entre velocidade e precisão',
  ),
  WhisperModel(
    id: 'medium',
    label: 'Medium',
    approxBytes: 1533 * _mb,
    description: 'Mais preciso, mais lento',
  ),
  WhisperModel(
    id: 'large-v3-turbo-q5_0',
    label: 'Large v3 Turbo (q5)',
    approxBytes: 547 * _mb,
    description: 'Ótima precisão, compacto',
  ),
  WhisperModel(
    id: 'large-v3-turbo',
    label: 'Large v3 Turbo',
    approxBytes: 1624 * _mb,
    description: 'Melhor precisão, arquivo grande',
  ),
];

const defaultModelId = 'small';

WhisperModel modelById(String id) =>
    whisperModels.firstWhere((m) => m.id == id, orElse: () => whisperModels[1]);

class Language {
  const Language(this.code, this.label);

  /// Código mostrado/salvo pela UI (ex.: `pt-BR`, `auto`).
  final String code;
  final String label;

  /// Código aceito pelo whisper-cli (`-l`): ele usa ISO 639-1 sem região.
  String get whisperCode => code == 'auto' ? 'auto' : code.split('-').first;
}

const languages = <Language>[
  Language('pt-BR', 'Português (Brasil)'),
  Language('auto', 'Detectar automaticamente'),
  Language('en', 'Inglês'),
  Language('es', 'Espanhol'),
  Language('fr', 'Francês'),
  Language('it', 'Italiano'),
  Language('de', 'Alemão'),
  Language('ja', 'Japonês'),
];

const defaultLanguageCode = 'pt-BR';

const videoExtensions = <String>[
  'mp4', 'mov', 'mkv', 'webm', 'avi', 'm4v', 'flv', 'wmv', 'mpg', 'mpeg',
  'ts', '3gp',
  // Áudio também funciona, já que o ffmpeg só extrai a trilha.
  'mp3', 'm4a', 'wav', 'ogg', 'flac',
];

bool isSupportedMedia(String path) {
  final dot = path.lastIndexOf('.');
  if (dot < 0) return false;
  return videoExtensions.contains(path.substring(dot + 1).toLowerCase());
}

String formatBytes(int bytes) {
  if (bytes >= 1024 * _mb) {
    return '${(bytes / (1024 * _mb)).toStringAsFixed(1).replaceAll('.', ',')} GB';
  }
  if (bytes >= _mb) return '${(bytes / _mb).round()} MB';
  if (bytes >= 1024) return '${(bytes / 1024).round()} KB';
  return '$bytes B';
}
