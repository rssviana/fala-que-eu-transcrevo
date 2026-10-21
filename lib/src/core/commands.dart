/// Montagem dos argumentos de linha de comando do ffmpeg e do whisper-cli.
library;

/// Extrai o áudio como WAV PCM 16 kHz mono, o formato que o whisper.cpp exige.
List<String> ffmpegExtractArgs({
  required String input,
  required String output,
}) => [
  '-hide_banner',
  '-nostdin',
  '-y',
  '-i',
  input,
  '-vn',
  '-ac',
  '1',
  '-ar',
  '16000',
  '-c:a',
  'pcm_s16le',
  output,
];

List<String> whisperArgs({
  required String model,
  required String audio,
  required String language,
  required int threads,
}) => [
  '-m', model,
  '-f', audio,
  '-l', language,
  '-t', '$threads',
  // Imprime "progress = N%" no stderr.
  '-pp',
];

/// Threads para o whisper: metade dos núcleos lógicos, entre 1 e 8.
int whisperThreads(int processors) => (processors ~/ 2).clamp(1, 8);
