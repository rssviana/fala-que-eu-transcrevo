import 'package:flutter/material.dart';

import 'src/ui/controller.dart';
import 'src/ui/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController()..init();
  runApp(FalaQueEuTranscrevoApp(controller: controller));
}

class FalaQueEuTranscrevoApp extends StatelessWidget {
  const FalaQueEuTranscrevoApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fala que eu transcrevo!',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),
      home: HomePage(controller: controller),
    );
  }
}
