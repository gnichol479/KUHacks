import 'package:flutter/material.dart';

class AppGradients {
  static const hero = LinearGradient(
    colors: [
      Color(0xFFEDEBFF),
      Color(0xFFFFEEF4),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accent = LinearGradient(
    colors: [
      Color(0xFF4F6EF7),
      Color(0xFF8E7CFF),
    ],
  );
}