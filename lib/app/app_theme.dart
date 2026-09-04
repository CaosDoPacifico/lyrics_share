import 'package:flutter/material.dart';

class AppTheme {
  static const background = Color(0xFF0B0C10);
  static const surface = Color(0xFF14161C);
  static const glass = Color(0x331C1F28);
  static const text = Color(0xFFF4F1EA);
  static const muted = Color(0x99F4F1EA);
  static const accent = Color(0xFFD4B483);

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: accent,
        onPrimary: Color(0xFF0B0C10),
        onSurface: text,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: Color(0x33D4B483),
        elevation: 0,
      ),
    );
  }
}