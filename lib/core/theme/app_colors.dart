import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color primaryGradientStart = Color(0xFF1DCFEB);
  static const Color primaryGradientEnd = Color(0xFF5BA9FF);

  static const Color progressActive = Color(0xFFFF9D00);
  static const Color progressTrack = Color(0xFF4F5457);
  static const Color gamificationLight = Color(0xFFE7EBEF);

  static const Color success = Color(0xFF03BF35);
  static const Color danger = Color(0xFFEC6361);
  static const Color warning = Color(0xFFFFD500);

  static const Color neutralGray = Color(0xFF3D3D3D);
  static const Color textMuted = Color(0xFF687D91);
  static const Color textNavy = Color(0xFF042748);

  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  static const Color accentSuccess = Color(0xFF05B734);
  static const Color accentWarning = Color(0xFFE88F00);
  static const Color accentPrimary = Color(0xFF0086FF);

  static const Color actionInnerShadowGreen = Color(0xFFA8F2BC);
  static const Color actionInnerShadowBlue = Color(0xFFAED2F3);
  static const Color actionInnerShadowYellow = Color(0xFFF3EBAB);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGradientStart, primaryGradientEnd],
  );
}
