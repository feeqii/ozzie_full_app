import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.white,
      fontFamily: AppTextStyles.latinFont,
      colorScheme: const ColorScheme.light(
        primary: AppColors.textNavy,
        secondary: AppColors.primaryGradientEnd,
        surface: AppColors.white,
        onSurface: AppColors.neutralGray,
        error: AppColors.danger,
      ),
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.display,
        headlineSmall: AppTextStyles.title,
        bodyMedium: AppTextStyles.body,
        labelMedium: AppTextStyles.caption,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textNavy,
        centerTitle: true,
      ),
    );
  }
}
