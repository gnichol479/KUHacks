import 'package:flutter/material.dart';
import '../old_stuff/screens/auth/auth_entry_screen.dart';

class LedgerShredderApp extends StatelessWidget {
  const LedgerShredderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ledger Shredder',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF7F7F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F6EF7),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const AuthEntryScreen(),
    );
  }
}
