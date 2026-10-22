// Renderiza as 4 telas em 1120 × 780 com as fontes reais e salva PNGs em
// build/screens/, para comparar com design/referencia.html.
//
//   SCREENSHOTS=1 flutter test test/screens
@Tags(['screens'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transcritor/main.dart';
import 'package:transcritor/src/core/progress_plan.dart';
import 'package:transcritor/src/core/export.dart';
import 'package:transcritor/src/core/segment.dart';
import 'package:transcritor/ui/controller.dart';
import 'package:transcritor/ui/widgets/common.dart';
import 'package:desktop_drop/desktop_drop.dart';

Future<void> _loadFonts() async {
  Future<void> load(String family, String file) async {
    final bytes = File('assets/fonts/$file').readAsBytesSync();
    await (FontLoader(
      family,
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }

  await load('Inter', 'Inter.ttf');
  await load('Bricolage', 'BricolageGrotesque.ttf');
  await load('JetBrainsMono', 'JetBrainsMono.ttf');
}

Segment _s(int sec, String text) => Segment(
  start: Duration(seconds: sec),
  end: Duration(seconds: sec + 5),
  text: text,
);

void main() {
  final enabled = Platform.environment['SCREENSHOTS'] == '1';
  final key = GlobalKey();

  Future<AppController> controller(WidgetTester tester) async {
    final support = Directory.systemTemp.createTempSync('fala_support');
    Directory('${support.path}/models').createSync();
    for (final m in ['tiny', 'base']) {
      File('${support.path}/models/ggml-$m.bin').writeAsStringSync('x');
    }
    final c = AppController(os: 'macos', environment: const {'PATH': ''})
      // Os prints comparam com a referência, que não tem o aviso.
      ..disclaimerDismissed = Platform.environment['DISCLAIMER'] != '1';
    await tester.runAsync(
      () => c.init(supportDir: support, tempDir: Directory.systemTemp),
    );
    return c;
  }

  Future<void> shoot(WidgetTester tester, AppController c, String name) async {
    // SIZE=720x600 para conferir a janela mínima.
    final size = (Platform.environment['SIZE'] ?? '1120x780').split('x');
    tester.view.physicalSize = Size(
      double.parse(size[0]),
      double.parse(size[1]),
    );
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: FalaQueEuTranscrevoApp(controller: c),
      ),
    );
    // SVGs e imagens decodificam de forma assíncrona.
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(tester.takeException(), isNull);
    if (Platform.environment['RECTS'] == '1') {
      for (final t in [
        AppHeader,
        MainArea,
        DropTarget,
        SingleChildScrollView,
      ]) {
        for (final e in find.byType(t).evaluate()) {
          // ignore: avoid_print
          print('$name $t ${tester.getRect(find.byWidget(e.widget))}');
        }
      }
    }
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final suffix = Platform.environment['SIZE'] == null
          ? ''
          : '-${Platform.environment['SIZE']}';
      final out = File('build/screens/$name$suffix.png')
        ..createSync(recursive: true);
      out.writeAsBytesSync(data!.buffer.asUint8List());
    });
  }

  setUpAll(_loadFonts);

  testWidgets('tela 1 · início', (tester) async {
    final c = await controller(tester);
    c
      ..ffmpegPath = '/bin/ffmpeg'
      ..whisperPath = '/bin/whisper-cli'
      ..screen = AppScreen.home;
    await shoot(tester, c, 'tela-1');
  }, skip: !enabled);

  testWidgets('tela 2 · setup', (tester) async {
    final c = await controller(tester);
    // Na máquina de dev as ferramentas existem: simula que faltam.
    c
      ..ffmpegPath = null
      ..whisperPath = null
      ..screen = AppScreen.setup;
    await shoot(tester, c, 'tela-2');
  }, skip: !enabled);

  testWidgets('tela 3 · transcrevendo', (tester) async {
    final c = await controller(tester);
    c
      ..ffmpegPath = '/bin/ffmpeg'
      ..whisperPath = '/bin/whisper-cli'
      ..video = (VideoFile('/v/reuniao-de-planejamento.mp4', 612 * 1024 * 1024)
        ..duration = const Duration(minutes: 48, seconds: 12))
      ..screen = AppScreen.progress
      ..step = PipelineStep.transcribe
      ..stepFraction = (0.62 - 0.08) / 0.92
      ..startedAt = DateTime.now().subtract(const Duration(minutes: 5))
      ..liveSegments.addAll([
        _s(1742, 'Então, retomando o que ficou da semana passada.'),
        _s(
          1749,
          'A parte de exportação já está quase pronta, faltam só os testes.',
        ),
        _s(
          1760,
          'O que ainda preocupa é o tempo de processamento em vídeos longos.',
        ),
        _s(
          1774,
          'Dá para usar um modelo menor como padrão e deixar o maior como opção.',
        ),
        _s(1784, 'Faz sentido. Vou levantar os números até quinta'),
        _s(1791, 'e aí a gente decide se entra nessa sprint'),
      ]);
    await shoot(tester, c, 'tela-3');
  }, skip: !enabled);

  testWidgets('tela 4 · resultado', (tester) async {
    final c = await controller(tester);
    c
      ..ffmpegPath = '/bin/ffmpeg'
      ..whisperPath = '/bin/whisper-cli'
      ..video = (VideoFile('/v/reuniao-de-planejamento.mp4', 612 * 1024 * 1024)
        ..duration = const Duration(minutes: 48, seconds: 12))
      ..screen = AppScreen.result
      ..elapsed = const Duration(minutes: 7)
      ..info = TranscriptInfo(
        fileName: 'reuniao-de-planejamento.mp4',
        languageLabel: 'Português (Brasil)',
        modelLabel: 'Small',
        date: DateTime(2026),
      )
      ..segments.addAll([
        _s(
          0,
          'Bom dia, pessoal. Vamos começar que a pauta de hoje está cheia.',
        ),
        _s(7, 'Primeiro ponto é o lançamento do app para Windows e Linux.'),
        _s(
          15,
          'No Mac já está tudo funcionando, inclusive a instalação das dependências.',
        ),
        _s(
          26,
          'No Windows ainda falta assinar o instalador e testar em máquinas mais antigas.',
        ),
        _s(
          39,
          'Linux a ideia é sair com AppImage primeiro e depois ver os outros formatos.',
        ),
        _s(51, 'Alguém tem algum bloqueio que precisa resolver antes disso?'),
        _s(
          58,
          'Só a parte de legendas, que eu quero revisar o tempo das quebras.',
        ),
      ]);
    await shoot(tester, c, 'tela-4');
  }, skip: !enabled);
}
