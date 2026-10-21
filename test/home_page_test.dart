import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transcritor/main.dart';
import 'package:transcritor/src/core/segment.dart';
import 'package:transcritor/src/ui/controller.dart';

void main() {
  testWidgets('tela inicial em pt-BR com idioma e modelo padrão', (
    tester,
  ) async {
    final c = AppController();
    await tester.runAsync(
      () => c.init(supportDir: Directory.systemTemp.createTempSync()),
    );
    await tester.pumpWidget(TranscritorApp(controller: c));
    await tester.pump();

    expect(
      find.text('Arraste um vídeo aqui ou clique para escolher'),
      findsOneWidget,
    );
    expect(find.text('Português (Brasil)'), findsOneWidget);
    expect(find.textContaining('Small · 466 MB'), findsOneWidget);
  });

  testWidgets('mostra o resultado e os botões de exportar', (tester) async {
    final c = AppController();
    await tester.runAsync(
      () => c.init(supportDir: Directory.systemTemp.createTempSync()),
    );
    c
      ..ffmpegPath = '/bin/ffmpeg'
      ..whisperPath = '/bin/whisper-cli'
      ..setVideo('/videos/aula.mp4')
      ..segments.add(
        const Segment(
          start: Duration.zero,
          end: Duration(seconds: 2),
          text: 'Olá, mundo.',
        ),
      )
      ..phase = Phase.done
      ..status = 'Transcrição concluída.';
    await tester.pumpWidget(TranscritorApp(controller: c));
    await tester.pump();

    expect(find.text('aula.mp4'), findsOneWidget);
    expect(find.text('Olá, mundo.'), findsOneWidget);
    expect(find.text('Exportar .srt'), findsOneWidget);
    expect(find.text('Exportar .txt'), findsOneWidget);
    expect(find.text('Copiar'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}
