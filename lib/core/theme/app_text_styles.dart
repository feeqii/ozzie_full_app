import 'package:flutter/material.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const String latinFont = 'Inter';
  static const String displayFont = 'Baloo2';
  static const String arabicFont = 'NotoNaskhArabic';

  static const TextStyle display = TextStyle(
    fontFamily: displayFont,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.05,
  );

  static const TextStyle title = TextStyle(
    fontFamily: displayFont,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.12,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: latinFont,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static const TextStyle body = TextStyle(
    fontFamily: latinFont,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: latinFont,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.35,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: latinFont,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    height: 1.2,
  );

  static const TextStyle micro = TextStyle(
    fontFamily: latinFont,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.35,
    height: 1.15,
  );

  static const TextStyle arabicTitle = TextStyle(
    fontFamily: arabicFont,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.6,
  );

  static const TextStyle arabicBody = TextStyle(
    fontFamily: arabicFont,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.6,
  );
}
