import 'package:flutter/material.dart';
import 'screens/auth/auth_entry_screen.dart';

void main() {
  runApp(const LedgarShredderApp());
}

class LedgarShredderApp extends StatelessWidget {
  const LedgarShredderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthScreen(),
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F1A),
      ),
    );
  }
}