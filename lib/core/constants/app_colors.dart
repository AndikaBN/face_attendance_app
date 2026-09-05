import 'package:flutter/material.dart';

/// Warna-warna konsisten untuk seluruh aplikasi (Light Theme).
class AppColors {
  AppColors._();

  // Background
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF0F2F5);
  static const Color cardDark = Color(0xFFE8EDF2);

  // Primary Accent (Blue)
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryFaded = Color(0x201565C0);
  static const Color primaryBorder = Color(0x401565C0);

  // Error / Danger / Alpa (Red)
  static const Color error = Color(0xFFEF4444);
  static const Color errorFaded = Color(0x15EF4444);
  static const Color errorBorder = Color(0x30EF4444);

  // Success / Masuk (Green)
  static const Color success = Color(0xFF22C55E);
  static const Color successFaded = Color(0x1522C55E);
  static const Color successBorder = Color(0x3022C55E);

  // Warning / Izin (Amber)
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningFaded = Color(0x15F59E0B);
  static const Color warningBorder = Color(0x30F59E0B);

  // Info (Blue light)
  static const Color info = Color(0xFF3B82F6);
  static const Color infoFaded = Color(0x153B82F6);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textDisabled = Color(0xFFD1D5DB);

  // Border
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);

  // Shadow
  static const Color shadow = Color(0x0A000000);
  static const Color shadowMedium = Color(0x14000000);
}
