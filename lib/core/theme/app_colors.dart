import 'package:flutter/material.dart';

abstract final class AppColors {
  const AppColors._();

  static const light = AppPalette(
    primary: Color(0xFF1A56E8),
    primaryHover: Color(0xFF174DD1),
    primaryPressed: Color(0xFF1545BA),
    primaryContainer: Color(0xFFE8EEFD),
    onPrimary: Color(0xFFFFFFFF),
    onPrimaryContainer: Color(0xFF1441AE),

    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF7F8FA),
    surfaceElevated: Color(0xFFFFFFFF),
    border: Color(0xFFE3E7EF),

    textPrimary: Color(0xFF0D1220),
    textSecondary: Color(0xFF5A6478),
    textMuted: Color(0xFF8B94A8),

    danger: Color(0xFFD23600),
    dangerContainer: Color(0xFFFBEBE6),
    onDangerContainer: Color(0xFF9E2900),

    success: Color(0xFF0F7A4D),
    successContainer: Color(0xFFE4F4EC),
    onSuccessContainer: Color(0xFF0A5436),
  );

  static const dark = AppPalette(
    primary: Color(0xFF7DA2F5),
    primaryHover: Color(0xFF94B4F8),
    primaryPressed: Color(0xFF6690E8),
    primaryContainer: Color(0xFF1441AE),
    onPrimary: Color(0xFF0C2768),
    onPrimaryContainer: Color(0xFFDDE6FC),

    background: Color(0xFF0F1219),
    surface: Color(0xFF171B24),
    surfaceElevated: Color(0xFF1F2430),
    border: Color(0xFF262D3B),

    textPrimary: Color(0xFFE8ECF5),
    textSecondary: Color(0xFF9AA4B8),
    textMuted: Color(0xFF6B7488),

    danger: Color(0xFFFF8A5C),
    dangerContainer: Color(0xFF3A1000),
    onDangerContainer: Color(0xFFF1C1B0),

    success: Color(0xFF5CC99A),
    successContainer: Color(0xFF0C3A28),
    onSuccessContainer: Color(0xFFA8E6C8),
  );
}

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primary,
    required this.primaryHover,
    required this.primaryPressed,
    required this.primaryContainer,
    required this.onPrimary,
    required this.onPrimaryContainer,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.danger,
    required this.dangerContainer,
    required this.onDangerContainer,
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
  });

  final Color primary;
  final Color primaryHover;
  final Color primaryPressed;
  final Color primaryContainer;
  final Color onPrimary;
  final Color onPrimaryContainer;

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color border;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  final Color danger;
  final Color dangerContainer;
  final Color onDangerContainer;

  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;

  @override
  AppPalette copyWith({
    Color? primary,
    Color? primaryHover,
    Color? primaryPressed,
    Color? primaryContainer,
    Color? onPrimary,
    Color? onPrimaryContainer,
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? danger,
    Color? dangerContainer,
    Color? onDangerContainer,
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
  }) {
    return AppPalette(
      primary: primary ?? this.primary,
      primaryHover: primaryHover ?? this.primaryHover,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimary: onPrimary ?? this.onPrimary,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      danger: danger ?? this.danger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      onDangerContainer: onDangerContainer ?? this.onDangerContainer,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    );
  }

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      primaryPressed: Color.lerp(primaryPressed, other.primaryPressed, t)!,
      primaryContainer:
          Color.lerp(primaryContainer, other.primaryContainer, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      onPrimaryContainer:
          Color.lerp(onPrimaryContainer, other.onPrimaryContainer, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      onDangerContainer:
          Color.lerp(onDangerContainer, other.onDangerContainer, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get colors => Theme.of(this).extension<AppPalette>()!;
}
