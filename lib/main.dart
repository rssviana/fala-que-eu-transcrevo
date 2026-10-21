import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'theme/app_colors.dart';
import 'theme/app_text.dart';
import 'ui/controller.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/progress_screen.dart';
import 'ui/screens/result_screen.dart';
import 'ui/screens/setup_screen.dart';
import 'ui/widgets/common.dart';

const appTitle = 'Fala que eu transcrevo!';

void main() {
  // Tamanho da janela (1120 × 780, mínimo 720 × 600) e título ficam no código
  // nativo de cada plataforma: macos/Runner/MainFlutterWindow.swift,
  // windows/runner/main.cpp e linux/runner/my_application.cc.
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController()..init();
  runApp(FalaQueEuTranscrevoApp(controller: controller));
}

/// Accent atual (trocável: #FF7A55 coral, #7C9CFF, #5EEAD4, #FACC15).
final accentPalette = ValueNotifier<AccentPalette>(AccentPalette.coral);

ThemeData buildTheme(AccentPalette palette) {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: AppColors.bg,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    focusColor: Colors.transparent,
    colorScheme: ColorScheme.dark(
      primary: palette.accent,
      onPrimary: palette.onAccent,
      surface: AppColors.surface,
      onSurface: AppColors.text,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: palette.accent,
      selectionColor: palette.accent.withValues(alpha: 0.35),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(AppColors.borderStrong),
      radius: const Radius.circular(999),
      thickness: WidgetStateProperty.all(6),
    ),
    extensions: [palette],
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: 'Inter',
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
  );
}

class FalaQueEuTranscrevoApp extends StatelessWidget {
  const FalaQueEuTranscrevoApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: accentPalette,
      builder: (context, palette, _) => MaterialApp(
        title: appTitle,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(palette),
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: AppShell(controller: controller),
      ),
    );
  }
}

/// Header + tela atual, conforme o estado do controller.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (!controller.ready) {
            return Center(child: Text('Carregando…', style: AppText.hint));
          }
          final (Widget trailing, Widget body) = switch (controller.screen) {
            AppScreen.setup => (
              const SetupHeaderActions(),
              SetupScreen(controller: controller),
            ),
            AppScreen.home => (
              const HomeHeaderActions(),
              HomeScreen(controller: controller),
            ),
            AppScreen.progress => (
              ProgressHeaderActions(controller: controller),
              ProgressScreen(controller: controller),
            ),
            AppScreen.result => (
              ResultHeaderActions(controller: controller),
              ResultScreen(controller: controller),
            ),
          };
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppHeader(trailing: trailing),
              Expanded(
                child: AnimatedSwitcher(
                  duration: motion(context, const Duration(milliseconds: 200)),
                  // Padrão centraliza: as telas começam no topo e ocupam tudo.
                  layoutBuilder: (current, previous) => Stack(
                    fit: StackFit.expand,
                    children: [...previous, ?current],
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(controller.screen),
                    child: body,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
