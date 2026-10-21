import 'package:flutter_test/flutter_test.dart';
import 'package:transcritor/src/core/catalog.dart';

void main() {
  test('pt-BR vira pt para o whisper; auto continua auto', () {
    expect(const Language('pt-BR', '').whisperCode, 'pt');
    expect(const Language('auto', '').whisperCode, 'auto');
    expect(const Language('en', '').whisperCode, 'en');
  });

  test('URL e nome de arquivo do modelo', () {
    final m = modelById('base');
    expect(m.fileName, 'ggml-base.bin');
    expect(
      m.downloadUri.toString(),
      'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin',
    );
  });

  test('padrões existem no catálogo', () {
    expect(modelById(defaultModelId).id, defaultModelId);
    expect(languages.first.code, defaultLanguageCode);
  });

  test('formatBytes', () {
    expect(formatBytes(142 * 1024 * 1024), '142 MB');
    expect(formatBytes(1533 * 1024 * 1024), '1,5 GB');
    expect(formatBytes(2048), '2 KB');
  });

  test('isSupportedMedia ignora caixa e rejeita outros formatos', () {
    expect(isSupportedMedia('/a/b/Video.MP4'), isTrue);
    expect(isSupportedMedia('clip.webm'), isTrue);
    expect(isSupportedMedia('doc.pdf'), isFalse);
    expect(isSupportedMedia('semextensao'), isFalse);
  });
}
