import 'package:flutter/material.dart';
import 'screens/auth/splash_gate.dart';

class LedgarShredderApp extends StatelessWidget {
  const LedgarShredderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ledgar Shredder',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF7F7F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F6EF7),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const SplashGate(),
    );
  }
}