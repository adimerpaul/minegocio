import 'package:flutter/material.dart';

/// Paleta tomada del mockup ejemplo.html (GestiónPro).
abstract class AppColors {
  static const primary = Color(0xFFF4632C);
  static const primaryDark = Color(0xFFC94D1E);
  static const background = Color(0xFFFAF8F6);
  static const backgroundAlt = Color(0xFFECEAE7);
  static const dark = Color(0xFF221A15);
  static const textMuted = Color(0xFF8A7D73);
  static const textLabel = Color(0xFF5D5148);
  static const border = Color(0xFFE4DDD6);
  static const darkMuted = Color(0xFFB3A89F);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.background,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.dark),
    ),
  );
}
