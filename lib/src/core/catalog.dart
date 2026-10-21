/// Catálogo de modelos do Whisper e idiomas suportados pela UI.
library;

class WhisperModel {
  const WhisperModel({
    required this.id,
    required this.label,
    required this.approxBytes,
    required this.speed,
    required this.accuracy,
    required this.description,
    this.recommended = false,
  });

  /// Nome usado no arquivo `ggml-<id>.bin` do repositório do whisper.cpp.
  final String id;
  final String label;
  final int approxBytes;

  /// Medidores de 0 a 5 mostrados no cartão do modelo.
  final int speed;
  final int accuracy;

  /// O que o modelo significa na prática, mostrado abaixo dos cartões.
  final String description;

  /// Selo "Ideal".
  final bool recommended;

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
    speed: 5,
    accuracy: 1,
    description:
        'O mais rápido e leve. Bom para testar ou para áudio bem limpo, '
        'mas erra mais palavras.',
  ),
  WhisperModel(
    id: 'base',
    label: 'Base',
    approxBytes: 142 * _mb,
    speed: 4,
    accuracy: 2,
    description:
        'Rápido e leve. Funciona bem com uma pessoa falando claro, '
        'sem barulho de fundo.',
  ),
  WhisperModel(
    id: 'small',
    label: 'Small',
    approxBytes: 466 * _mb,
    speed: 3,
    accuracy: 3,
    recommended: true,
    description:
        'Equilíbrio entre velocidade e precisão. Recomendado para a maioria '
        'dos vídeos, como aulas, reuniões e entrevistas.',
  ),
  WhisperModel(
    id: 'medium',
    label: 'Medium',
    approxBytes: 1533 * _mb,
    speed: 2,
    accuracy: 4,
    description:
        'Mais preciso com sotaques, ruído e termos técnicos, '
        'mas bem mais lento que o Small.',
  ),
  WhisperModel(
    id: 'large-v3-turbo',
    label: 'Large Turbo',
    approxBytes: 1624555275,
    speed: 2,
    accuracy: 5,
    description:
        'A melhor precisão. Versão otimizada do maior modelo do Whisper: '
        'mais rápida que o Large original, mas pede mais memória.',
  ),
];

const defaultModelId = 'small';

WhisperModel modelById(String id) => whisperModels.firstWhere(
  (m) => m.id == id,
  orElse: () => modelById(defaultModelId),
);

class Language {
  const Language(this.code, this.label, this.shortLabel);

  /// Código mostrado/salvo pela UI (ex.: `pt-BR`, `auto`).
  final String code;
  final String label;

  /// Versão curta para a linha de detalhes do arquivo.
  final String shortLabel;

  /// Código aceito pelo whisper-cli (`-l`): ele usa ISO 639-1 sem região.
  String get whisperCode => code == 'auto' ? 'auto' : code.split('-').first;
}

/// Os quatro primeiros seguem a ordem do design; os demais vêm depois.
const languages = <Language>[
  Language('pt-BR', 'Português (Brasil)', 'Português'),
  Language('auto', 'Detectar automaticamente', 'Automático'),
  Language('en', 'Inglês', 'Inglês'),
  Language('es', 'Espanhol', 'Espanhol'),
  Language('fr', 'Francês', 'Francês'),
  Language('it', 'Italiano', 'Italiano'),
  Language('de', 'Alemão', 'Alemão'),
  Language('ja', 'Japonês', 'Japonês'),
];

const defaultLanguageCode = 'pt-BR';

Language languageByCode(String code) =>
    languages.firstWhere((l) => l.code == code, orElse: () => languages.first);

/// Chips mostrados no dropzone.
const featuredFormats = ['MP4', 'MOV', 'MKV', 'WEBM', 'MP3', 'WAV'];

const videoExtensions = <String>[
  'mp4', 'mov', 'mkv', 'webm', 'avi', 'm4v', 'flv', 'wmv', 'mpg', 'mpeg', //
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

/// Milhar com ponto: 6840 → `6.840`.
String formatThousands(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}
