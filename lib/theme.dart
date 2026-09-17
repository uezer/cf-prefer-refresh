import 'package:flutter/material.dart';

class AppColors {
  static const rust = Color(0xFFC45C26);
  static const rustDeep = Color(0xFF8E3F16);
  static const ink = Color(0xFF161B22);
  static const pine = Color(0xFF2F6F5E);
  static const paper = Color(0xFFF6F1EA);
  static const card = Color(0xFFFFFBF6);
  static const line = Color(0xFFE6D9C8);
  static const danger = Color(0xFFB42318);
}

ThemeData buildLightTheme() {
  final base = ColorScheme.fromSeed(
    seedColor: AppColors.rust,
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: base.copyWith(
      primary: AppColors.rust,
      secondary: AppColors.pine,
      surface: AppColors.paper,
    ),
    scaffoldBackgroundColor: AppColors.paper,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: AppColors.paper,
      foregroundColor: AppColors.ink,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

ThemeData buildDarkTheme() {
  final base = ColorScheme.fromSeed(
    seedColor: AppColors.rust,
    brightness: Brightness.dark,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: base,
    appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
    ),
  );
}
