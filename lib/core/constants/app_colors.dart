import 'package:flutter/material.dart';

/// Warna-warna konsisten untuk seluruh aplikasi.
class AppColors {
  AppColors._();

  // Background
  static const Color background = Color(0xFF0A0E21);
  static const Color surface = Color(0xFF141829);
  static const Color surfaceLight = Color(0xFF1A1F38);
  static const Color cardDark = Color(0xFF1E2340);

  // Primary Accent (Teal)
  static const Color primary = Color(0xFF64FFDA);
  static const Color primaryDark = Color(0xFF00BFA5);
  static const Color primaryFaded = Color(0x2064FFDA);
  static const Color primaryBorder = Color(0x4064FFDA);

  // Error / Danger (Coral)
  static const Color error = Color(0xFFFF6B6B);
  static const Color errorFaded = Color(0x20FF6B6B);
  static const Color errorBorder = Color(0x40FF6B6B);

  // Success (Green)
  static const Color success = Color(0xFF66BB6A);
  static const Color successFaded = Color(0x2066BB6A);

  // Warning (Amber)
  static const Color warning = Color(0xFFFFB74D);
  static const Color warningFaded = Color(0x20FFB74D);

  // Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted = Colors.white38;
  static const Color textDisabled = Colors.white24;

  // Border
  static const Color border = Color(0xFF2A2F48);
}
