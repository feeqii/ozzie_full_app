import 'package:flutter/material.dart';

class OnboardingPalette {
  const OnboardingPalette._();

  static const Color dark = Color(0xFF141413);
  static const Color light = Color(0xFFFAF9F5);
  static const Color midGray = Color(0xFFB0AEA5);
  static const Color lightGray = Color(0xFFE8E6DC);

  static const Color orange = Color(0xFFD97757);
  static const Color blue = Color(0xFF6A9BCC);
  static const Color green = Color(0xFF788C5D);

  static const Color success = Color(0xFF3F8A54);
  static const Color danger = Color(0xFFB9483E);
}

class OnboardingColors {
  const OnboardingColors({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.decorationA,
    required this.decorationB,
  });

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color decorationA;
  final Color decorationB;

  static const OnboardingColors light = OnboardingColors(
    background: OnboardingPalette.light,
    surface: Color(0xFFFFFEFA),
    surfaceMuted: OnboardingPalette.lightGray,
    textPrimary: OnboardingPalette.dark,
    textSecondary: Color(0xFF6F6C63),
    border: Color(0xFFD8D3C7),
    primary: OnboardingPalette.orange,
    onPrimary: OnboardingPalette.light,
    secondary: OnboardingPalette.dark,
    onSecondary: OnboardingPalette.light,
    decorationA: Color(0x33D97757),
    decorationB: Color(0x336A9BCC),
  );

  static const OnboardingColors dark = OnboardingColors(
    background: Color(0xFF111110),
    surface: Color(0xFF1A1A19),
    surfaceMuted: Color(0xFF242422),
    textPrimary: OnboardingPalette.light,
    textSecondary: Color(0xFFBEBBAF),
    border: Color(0xFF3A3832),
    primary: Color(0xFFE18A6D),
    onPrimary: OnboardingPalette.dark,
    secondary: OnboardingPalette.blue,
    onSecondary: OnboardingPalette.light,
    decorationA: Color(0x3386AFCF),
    decorationB: Color(0x336F8E58),
  );

  factory OnboardingColors.resolve(Brightness brightness) {
    return brightness == Brightness.dark
        ? OnboardingColors.dark
        : OnboardingColors.light;
  }
}

class OnboardingTypography {
  const OnboardingTypography._();

  static const String headingFont = 'Poppins';
  static const String bodyFont = 'Lora';
  static const String arabicFont = 'NotoNaskhArabic';

  static TextStyle display(Color color) {
    return TextStyle(
      fontFamily: headingFont,
      fontFamilyFallback: const ['Arial'],
      fontSize: 34,
      fontWeight: FontWeight.w700,
      height: 1.08,
      letterSpacing: -0.4,
      color: color,
    );
  }

  static TextStyle headline(Color color) {
    return TextStyle(
      fontFamily: headingFont,
      fontFamilyFallback: const ['Arial'],
      fontSize: 26,
      fontWeight: FontWeight.w700,
      height: 1.15,
      letterSpacing: -0.2,
      color: color,
    );
  }

  static TextStyle title(Color color) {
    return TextStyle(
      fontFamily: headingFont,
      fontFamilyFallback: const ['Arial'],
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.2,
      color: color,
    );
  }

  static TextStyle body(Color color) {
    return TextStyle(
      fontFamily: bodyFont,
      fontFamilyFallback: const ['Georgia'],
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.45,
      color: color,
    );
  }

  static TextStyle bodyStrong(Color color) {
    return body(color).copyWith(fontWeight: FontWeight.w700);
  }

  static TextStyle label(Color color) {
    return TextStyle(
      fontFamily: headingFont,
      fontFamilyFallback: const ['Arial'],
      fontSize: 13,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: 0.2,
      color: color,
    );
  }
}

class OnboardingSpacing {
  const OnboardingSpacing._();

  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 30;
  static const double xxl = 44;
}

class OnboardingRadii {
  const OnboardingRadii._();

  static const double sm = 12;
  static const double md = 18;
  static const double lg = 24;
  static const double xl = 32;
}
