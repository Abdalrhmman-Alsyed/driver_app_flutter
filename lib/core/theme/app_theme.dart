import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(AppColors.light, Brightness.light);

  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);

    // خط النظام مؤقتًا. الخط المختار (IBM Plex Sans Arabic) يُحزَم داخل
    // التطبيق لاحقًا: جلبه وقت التشغيل يفشل حين تكون الشبكة ضعيفة، وهذه
    // حالة السائق الطبيعية داخل المستودع.
    final textTheme = base.textTheme
        .apply(bodyColor: p.textPrimary, displayColor: p.textPrimary);

    return base.copyWith(
      scaffoldBackgroundColor: p.background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: p.primary,
        onPrimary: p.onPrimary,
        primaryContainer: p.primaryContainer,
        onPrimaryContainer: p.onPrimaryContainer,
        secondary: p.primary,
        onSecondary: p.onPrimary,
        error: p.danger,
        onError: brightness == Brightness.light
            ? const Color(0xFFFFFFFF)
            : const Color(0xFF3A1000),
        errorContainer: p.dangerContainer,
        onErrorContainer: p.onDangerContainer,
        surface: p.background,
        onSurface: p.textPrimary,
        surfaceContainerLowest: p.background,
        surfaceContainerLow: p.surface,
        surfaceContainer: p.surface,
        surfaceContainerHigh: p.surfaceElevated,
        surfaceContainerHighest: p.surfaceElevated,
        onSurfaceVariant: p.textSecondary,
        outline: p.border,
        outlineVariant: p.border,
      ),
      textTheme: textTheme,
      dividerColor: p.border,
      dividerTheme: DividerThemeData(color: p.border, space: 1, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: p.textPrimary,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          disabledBackgroundColor: p.border,
          disabledForegroundColor: p.textMuted,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          side: BorderSide(color: p.border),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        hintStyle: textTheme.bodyMedium?.copyWith(color: p.textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.danger, width: 1.6),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surfaceElevated,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: p.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      extensions: [p],
    );
  }
}
