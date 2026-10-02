import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData build(Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: brightness,
      ),
      useMaterial3: true,
    );
  }
}
