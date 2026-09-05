import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFFE53935);
  static const Color primaryRed = Color(0xFFE53935);
  static const Color primaryColor = Color(0xFFE53935);
  static const Color darkRed = Color(0xFFC62828);
  static const Color accentRed = Color(0xFFFFEBEE);

  static const Color surface = Colors.white;
  static const Color background = Color(0xFFF8F9FA);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color bgLight = Color(0xFFF8F9FA);
  static const Color scaffoldBackground = Color(0xFFF8F9FA);

  static const Color textDark = Color(0xFF212121);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textGrey = Color(0xFF757575);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: surface,
      ),
      fontFamily: 'Roboto',
    );
  }
}
