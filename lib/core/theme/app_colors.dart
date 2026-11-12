import 'package:flutter/material.dart';
import '../../state/notifiers/app_notifiers.dart';

class AppColors {
  const AppColors._();

  static String get mode => appThemeNotifier.value;
  static bool get isLight => mode == 'light';
  static bool get isAmoled => mode == 'amoled';
  static bool get isDark => mode == 'dark';

  static Color get bg => isLight
      ? const Color(0xFFF2F2F7)
      : (isAmoled ? const Color(0xFF000000) : const Color(0xFF111114));

  static Color get cardSurface => isLight
      ? const Color(0xFFFFFFFF).withValues(alpha: 0.86)
      : (isAmoled
      ? const Color(0xFF0A0A0D).withValues(alpha: 0.92)
      : const Color(0xFF1C1C1E).withValues(alpha: 0.78));

  static Color get secondarySurface => isLight
      ? const Color(0xFFE5E5EA)
      : (isAmoled ? const Color(0xFF121216) : const Color(0xFF2C2C2E));

  static Color get segmentThumb => isLight
      ? const Color(0xFFFFFFFF)
      : (isAmoled ? const Color(0xFF242429) : const Color(0xFF3A3A3C));

  static Color get border => isLight
      ? const Color(0xFFD1D1D6)
      : (isAmoled
      ? Colors.white.withValues(alpha: 0.09)
      : Colors.white.withValues(alpha: 0.14));

  static Color get divider => isLight
      ? const Color(0xFFD1D1D6)
      : (isAmoled ? const Color(0xFF1E1E24) : const Color(0xFF38383A));

  static Color get textPrimary =>
      isLight ? const Color(0xFF1C1C1E) : Colors.white;

  static Color get textSecondary =>
      isLight ? const Color(0xFF6C6C70) : const Color(0xFF8E8E93);

  static Color get textDisabled =>
      isLight ? const Color(0xFFAEAEB2) : Colors.white38;

  static const Color accent = Color(0xFF0A84FF);
}