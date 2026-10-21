import 'package:flutter_test/flutter_test.dart';
import 'package:transcritor/src/core/catalog.dart';

void main() {
  test('pt-BR vira pt para o whisper; auto continua auto', () {
    expect(const Language('pt-BR', '', '').whisperCode, 'pt');
    expect(const Language('auto', '', '').whisperCode, 'auto');
    expect(const Language('en', '', '').whisperCode, 'en');
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

  test('modelos do design: 5, Small ideal, medidores e tamanhos', () {
    expect(whisperModels.map((m) => m.label), [
      'Tiny',
      'Base',
      'Small',
      'Medium',
      'Large',
    ]);
    expect(whisperModels.where((m) => m.recommended).single.id, 'small');
    expect(whisperModels.map((m) => m.speed), [5, 4, 3, 2, 1]);
    expect(whisperModels.map((m) => m.accuracy), [1, 2, 3, 4, 5]);
    expect(whisperModels.map((m) => m.sizeLabel), [
      '75 MB',
      '142 MB',
      '466 MB',
      '1,5 GB',
      '2,9 GB',
    ]);
  });

  test('idiomas começam na ordem do design', () {
    expect(languages.take(4).map((l) => l.label), [
      'Português (Brasil)',
      'Detectar automaticamente',
      'Inglês',
      'Espanhol',
    ]);
    expect(languageByCode('xx').code, 'pt-BR');
  });

  test('formatThousands usa ponto', () {
    expect(formatThousands(6840), '6.840');
    expect(formatThousands(999), '999');
    expect(formatThousands(1234567), '1.234.567');
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
