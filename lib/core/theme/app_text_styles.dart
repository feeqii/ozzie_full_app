import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const String latinFont = 'Inter';
  static const String arabicFont = 'NotoNaskhArabic';

  static const TextStyle display = TextStyle(
    fontFamily: latinFont,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textNavy,
    height: 1.2,
  );

  static const TextStyle title = TextStyle(
    fontFamily: latinFont,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textNavy,
    height: 1.2,
  );

  static const TextStyle body = TextStyle(
    fontFamily: latinFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.neutralGray,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: latinFont,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    height: 1.3,
  );

  static const TextStyle arabicTitle = TextStyle(
    fontFamily: arabicFont,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textNavy,
    height: 1.6,
  );

  static const TextStyle arabicBody = TextStyle(
    fontFamily: arabicFont,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.neutralGray,
    height: 1.6,
  );
}
