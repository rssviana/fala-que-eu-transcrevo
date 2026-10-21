import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transcritor/main.dart';
import 'package:transcritor/src/core/export.dart';
import 'package:transcritor/src/core/segment.dart';
import 'package:transcritor/ui/controller.dart';

void main() {
  late Set<String> files;

  Future<AppController> start(WidgetTester tester) async {
    final support = Directory.systemTemp.createTempSync('fala_app');
    final c = AppController(
      os: 'linux',
      environment: const {'PATH': '/x'},
      isFile: (p) => files.contains(p),
    );
    await tester.runAsync(
      () => c.init(supportDir: support, tempDir: Directory.systemTemp),
    );
    tester.view.physicalSize = const Size(1120, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(FalaQueEuTranscrevoApp(controller: c));
    await tester.pump();
    return c;
  }

  setUp(() => files = {});

  testWidgets(
    'sem ferramentas abre o Setup; verificar de novo leva ao Início',
    (tester) async {
      final c = await start(tester);
      expect(c.screen, AppScreen.setup);
      expect(find.text('Falta só um passo para começar'), findsOneWidget);
      expect(find.text('Configuração pendente'), findsOneWidget);
      expect(find.text('Não encontrado'), findsNWidgets(2));
      // Aba do SO atual (linux) pré-selecionada, com os dois comandos.
      expect(find.text('sudo apt install ffmpeg'), findsOneWidget);

      files.addAll({'/x/ffmpeg', '/x/whisper-cli'});
      final recheck = find.text('Já instalei, verificar de novo');
      await tester.ensureVisible(recheck);
      await tester.pump();
      await tester.tap(recheck);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 700)),
      );
      await tester.pumpAndSettle();
      expect(c.screen, AppScreen.home);
      expect(find.text('Solte seu vídeo aqui'), findsOneWidget);
      expect(find.text('Tudo pronto'), findsOneWidget);
    },
  );

  testWidgets('só mostra o comando da ferramenta que falta', (tester) async {
    files.add('/x/ffmpeg');
    await start(tester);
    expect(find.text('Encontrado'), findsOneWidget);
    expect(find.text('sudo apt install ffmpeg'), findsNothing);
    expect(find.textContaining('snap install whisper-cpp'), findsOneWidget);
  });

  testWidgets('Início: Small é o padrão, seleção única e dica do rodapé', (
    tester,
  ) async {
    files.addAll({'/x/ffmpeg', '/x/whisper-cli'});
    final c = await start(tester);
    expect(c.modelId, 'small');
    expect(find.text('Escolha um vídeo para começar'), findsOneWidget);

    await tester.tap(find.text('Medium'));
    await tester.pump();
    expect(c.modelId, 'medium');

    c.video = VideoFile('/v/aula.mp4', 1024);
    c.setModel('large-v3');
    await tester.pump();
    expect(find.text('O modelo será baixado antes (2,9 GB)'), findsOneWidget);
    expect(find.text('aula.mp4'), findsOneWidget);
    expect(find.text('Trocar vídeo'), findsOneWidget);
  });

  testWidgets('Resultado: editar trecho entra na exportação; busca destaca', (
    tester,
  ) async {
    files.addAll({'/x/ffmpeg', '/x/whisper-cli'});
    final c = await start(tester);
    c
      ..video = VideoFile('/v/aula.mp4', 1024)
      ..info = TranscriptInfo(
        fileName: 'aula.mp4',
        languageLabel: 'Português (Brasil)',
        modelLabel: 'Small',
        date: DateTime(2026),
      )
      ..elapsed = const Duration(seconds: 25)
      ..segments.addAll(const [
        Segment(
          start: Duration.zero,
          end: Duration(seconds: 2),
          text: 'Olá, mundo.',
        ),
        Segment(
          start: Duration(seconds: 2),
          end: Duration(seconds: 4),
          text: 'Tchau.',
        ),
      ])
      ..screen = AppScreen.result;
    c.setLanguage('pt-BR'); // notifica
    await tester.pump();

    expect(find.text('Pronto! Seu texto está aqui.'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // palavras
    expect(find.text('25 s'), findsOneWidget);
    for (final ext in ['TXT', 'SRT', 'VTT', 'MD', 'PDF']) {
      expect(find.text(ext), findsOneWidget);
    }

    await tester.tap(find.text('Tchau.'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'Até logo.');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    c.updateSegment(1, 'Até logo.');
    await tester.pump();
    expect(utf8.decode(await c.exportBytes('txt')), 'Olá, mundo.\nAté logo.');
    expect(utf8.decode(await c.exportBytes('vtt')), contains('Até logo.'));

    await tester.enterText(find.byType(TextField).first, 'MUNDO');
    await tester.pump();
    final rich = tester
        .widgetList<RichText>(find.byType(RichText))
        .where((r) => r.text.toPlainText() == 'Olá, mundo.');
    final spans = <InlineSpan>[];
    rich.first.text.visitChildren((s) {
      spans.add(s);
      return true;
    });
    expect(
      spans.whereType<TextSpan>().any(
        (s) => s.text == 'mundo' && s.style?.backgroundColor != null,
      ),
      isTrue,
    );
  });
}
