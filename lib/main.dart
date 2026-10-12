import 'package:flutter/material.dart';

import 'screens/main_shell.dart';

void main() => runApp(const ResWaveApp());

class ResWaveApp extends StatelessWidget {
  const ResWaveApp({super.key});
  static const primary = Color(0xFF075E54);
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ResWave',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primary),
      scaffoldBackgroundColor: const Color(0xFFF4F7F5),
      fontFamily: 'Roboto',
    ),
    home: const MainShell(),
  );
}
