import 'package:flutter/material.dart';

class ParentPalette {
  const ParentPalette._();

  static const Color dark = Color(0xFF141413);
  static const Color light = Color(0xFFFAF9F5);
  static const Color midGray = Color(0xFFB0AEA5);
  static const Color lightGray = Color(0xFFE8E6DC);

  static const Color orange = Color(0xFFD97757);
  static const Color blue = Color(0xFF6A9BCC);
  static const Color green = Color(0xFF788C5D);
  static const Color red = Color(0xFFCF6660);
}

class ParentColors {
  const ParentColors({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.shadow,
    required this.accent,
    required this.success,
    required this.danger,
    required this.chartBar,
  });

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color shadow;
  final Color accent;
  final Color success;
  final Color danger;
  final Color chartBar;

  static const ParentColors light = ParentColors(
    background: ParentPalette.light,
    surface: Color(0xFFF3F1E9),
    surfaceMuted: Color(0xFFEDEAE0),
    textPrimary: ParentPalette.dark,
    textSecondary: ParentPalette.midGray,
    border: Color(0xFFC4BFB2),
    shadow: Color(0x33141413),
    accent: ParentPalette.blue,
    success: ParentPalette.green,
    danger: ParentPalette.red,
    chartBar: Color(0xFF6E6A66),
  );

  static const ParentColors dark = ParentColors(
    background: ParentPalette.dark,
    surface: Color(0xFF1D1C1A),
    surfaceMuted: Color(0xFF262421),
    textPrimary: ParentPalette.light,
    textSecondary: ParentPalette.midGray,
    border: Color(0xFF656059),
    shadow: Color(0x55141413),
    accent: ParentPalette.blue,
    success: ParentPalette.green,
    danger: ParentPalette.red,
    chartBar: Color(0xFF9B968A),
  );

  factory ParentColors.resolve(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }
}

class ParentText {
  const ParentText._();

  static TextStyle heading(Color color) {
    return TextStyle(
      fontFamily: 'Poppins',
      fontFamilyFallback: const ['Arial'],
      fontWeight: FontWeight.w700,
      fontSize: 34,
      height: 1.1,
      letterSpacing: 0.2,
      color: color,
    );
  }

  static TextStyle title(Color color) {
    return TextStyle(
      fontFamily: 'Poppins',
      fontFamilyFallback: const ['Arial'],
      fontWeight: FontWeight.w700,
      fontSize: 18,
      height: 1.2,
      letterSpacing: 0.1,
      color: color,
    );
  }

  static TextStyle body(Color color) {
    return TextStyle(
      fontFamily: 'Lora',
      fontFamilyFallback: const ['Georgia'],
      fontWeight: FontWeight.w500,
      fontSize: 16,
      height: 1.4,
      color: color,
    );
  }

  static TextStyle label(Color color) {
    return TextStyle(
      fontFamily: 'Poppins',
      fontFamilyFallback: const ['Arial'],
      fontWeight: FontWeight.w600,
      fontSize: 14,
      letterSpacing: 0.4,
      color: color,
    );
  }

  static TextStyle micro(Color color) {
    return TextStyle(
      fontFamily: 'Poppins',
      fontFamilyFallback: const ['Arial'],
      fontWeight: FontWeight.w600,
      fontSize: 12,
      letterSpacing: 0.3,
      color: color,
    );
  }

  static TextStyle number(Color color) {
    return TextStyle(
      fontFamily: 'Poppins',
      fontFamilyFallback: const ['Arial'],
      fontWeight: FontWeight.w700,
      fontSize: 44,
      height: 1,
      color: color,
    );
  }
}

class ParentSpacing {
  const ParentSpacing._();

  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 44;
}

class ParentRadius {
  const ParentRadius._();

  static const double sm = 12;
  static const double md = 16;
  static const double lg = 22;
}
