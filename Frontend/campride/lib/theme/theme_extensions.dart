import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Dark-mode-aware color shortcuts, so screens don't need to hardcode
/// Colors.white/black/grey and silently ignore the active theme.
extension ThemeAwareColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get scaffoldBg =>
      isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

  Color get surface => isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

  Color get cardBg => isDark ? AppColors.cardDark : AppColors.cardLight;

  Color get textPrimary =>
      isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

  Color get textSecondary =>
      isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

  Color get divider => isDark ? AppColors.dividerDark : AppColors.dividerLight;

  /// Fill color for input fields / subtle containers (was Colors.grey[50/100]).
  Color get fieldFill => isDark ? AppColors.surfaceDark : const Color(0xFFF7F7F7);

  /// Border color for input fields / outlined containers (was Colors.grey[300]).
  Color get fieldBorder => isDark ? AppColors.dividerDark : const Color(0xFFE0E0E0);
}
