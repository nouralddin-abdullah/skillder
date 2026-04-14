import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary gradient (Tinder-inspired coral → rose)
  static const Color primary = Color(0xFFFF6B6B);
  static const Color primaryDark = Color(0xFFEE5A24);
  static const Color accent = Color(0xFFFF8E71);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E71)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFFFF5F5), Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Neutrals
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textHint = Color(0xFFBDBDC7);
  static const Color divider = Color(0xFFF0F0F5);
  static const Color inputFill = Color(0xFFF5F5F8);
  static const Color inputBorder = Color(0xFFE8E8ED);
  static const Color error = Color(0xFFFF3B30);
}
