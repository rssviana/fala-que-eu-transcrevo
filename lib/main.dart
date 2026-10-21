import 'package:flutter/material.dart';

import 'src/ui/controller.dart';
import 'src/ui/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController()..init();
  runApp(TranscritorApp(controller: controller));
}

class TranscritorApp extends StatelessWidget {
  const TranscritorApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transcritor',
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
