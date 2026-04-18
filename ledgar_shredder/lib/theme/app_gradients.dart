import 'package:flutter/material.dart';

class AppGradients {
  static const primaryCard = LinearGradient(
    colors: [
      Color(0xFF8E7CFF),
      Color(0xFFFF7CA8),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const subtleAccent = LinearGradient(
    colors: [
      Color(0xFFEDEBFF),
      Color(0xFFFFEEF4),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}