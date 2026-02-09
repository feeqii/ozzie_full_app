import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_extensions.dart';
import 'app_text_styles.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final surfaces = AppSurfaces.light();
    const motion = AppMotion.defaults;
    const scheme = ColorScheme.light(
      primary: AppColors.accentPrimary,
      secondary: AppColors.progressActive,
      surface: Color(0xFFFFFEFB),
      onSurface: AppColors.textNavy,
      error: AppColors.danger,
      onError: AppColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: surfaces.canvas,
      fontFamily: AppTextStyles.latinFont,
      colorScheme: scheme,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display.copyWith(color: scheme.onSurface),
        headlineSmall: AppTextStyles.title.copyWith(color: scheme.onSurface),
        titleMedium: AppTextStyles.subtitle.copyWith(color: scheme.onSurface),
        bodyLarge: AppTextStyles.bodyStrong.copyWith(color: scheme.onSurface),
        bodyMedium: AppTextStyles.body.copyWith(color: AppColors.neutralGray),
        labelMedium: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
        labelSmall: AppTextStyles.micro.copyWith(color: AppColors.textMuted),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: surfaces.canvas,
        foregroundColor: scheme.onSurface,
        centerTitle: true,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      extensions: <ThemeExtension<dynamic>>[
        surfaces,
        motion,
      ],
    );
  }

  static ThemeData dark() {
    final surfaces = AppSurfaces.dark();
    const motion = AppMotion.defaults;
    const scheme = ColorScheme.dark(
      primary: AppColors.primaryGradientStart,
      secondary: AppColors.progressActive,
      surface: Color(0xFF0B213B),
      onSurface: Color(0xFFF6F3E6),
      error: AppColors.danger,
      onError: AppColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: surfaces.canvas,
      fontFamily: AppTextStyles.latinFont,
      colorScheme: scheme,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display.copyWith(color: scheme.onSurface),
        headlineSmall: AppTextStyles.title.copyWith(color: scheme.onSurface),
        titleMedium: AppTextStyles.subtitle.copyWith(color: scheme.onSurface),
        bodyLarge: AppTextStyles.bodyStrong.copyWith(color: scheme.onSurface),
        bodyMedium: AppTextStyles.body.copyWith(color: const Color(0xFFB7C3D1)),
        labelMedium: AppTextStyles.caption.copyWith(color: const Color(0xFF8FA3B8)),
        labelSmall: AppTextStyles.micro.copyWith(color: const Color(0xFF8FA3B8)),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        centerTitle: true,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      extensions: <ThemeExtension<dynamic>>[
        surfaces,
        motion,
      ],
    );
  }
}
