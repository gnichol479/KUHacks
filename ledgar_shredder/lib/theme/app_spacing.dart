import 'package:flutter/material.dart';

class AppSpacing {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: md,
  );

  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(16),
  );
}