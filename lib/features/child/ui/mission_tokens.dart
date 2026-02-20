import 'package:flutter/material.dart';

class MissionPalette {
  const MissionPalette._();

  static const Color dark = Color(0xFF141413);
  static const Color light = Color(0xFFFAF9F5);
  static const Color midGray = Color(0xFFB0AEA5);
  static const Color lightGray = Color(0xFFE8E6DC);

  static const Color orange = Color(0xFFD97757);
  static const Color blue = Color(0xFF6A9BCC);
  static const Color green = Color(0xFF788C5D);
  static const Color red = Color(0xFFCF6660);
}

class MissionColors {
  const MissionColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.line,
    required this.shadow,
    required this.primaryGradient,
    required this.primaryText,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color line;
  final Color shadow;
  final Gradient primaryGradient;
  final Color primaryText;

  static const MissionColors light = MissionColors(
    background: MissionPalette.light,
    surface: Color(0xFFF1EFE6),
    surfaceElevated: Color(0xFFF5F3EC),
    textPrimary: MissionPalette.dark,
    textSecondary: MissionPalette.midGray,
    line: Color(0xFFB0AEA5),
    shadow: Color(0x4D141413),
    primaryGradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        MissionPalette.orange,
        MissionPalette.green,
        MissionPalette.blue,
      ],
    ),
    primaryText: MissionPalette.light,
  );

  static const MissionColors dark = MissionColors(
    background: MissionPalette.dark,
    surface: Color(0xFF1D1C1A),
    surfaceElevated: Color(0xFF252421),
    textPrimary: MissionPalette.light,
    textSecondary: MissionPalette.midGray,
    line: Color(0xFF64615A),
    shadow: Color(0x66141413),
    primaryGradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        MissionPalette.orange,
        MissionPalette.green,
        MissionPalette.blue,
      ],
    ),
    primaryText: MissionPalette.light,
  );

  factory MissionColors.resolve(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }
}

class MissionText {
  const MissionText._();

  static TextStyle hero(Color color) {
    return TextStyle(
      fontFamily: 'Poppins',
      fontFamilyFallback: const ['Arial'],
      fontWeight: FontWeight.w700,
      fontSize: 54,
      height: 1.04,
      letterSpacing: -0.7,
      color: color,
    );
  }

  static TextStyle heading(Color color) {
    return TextStyle(
      fontFamily: 'Poppins',
      fontFamilyFallback: const ['Arial'],
      fontWeight: FontWeight.w700,
      fontSize: 26,
      height: 1.12,
      color: color,
    );
  }

  static TextStyle title(Color color) {
    return TextStyle(
      fontFamily: 'Poppins',
      fontFamilyFallback: const ['Arial'],
      fontWeight: FontWeight.w600,
      fontSize: 18,
      height: 1.2,
      color: color,
    );
  }

  static TextStyle body(Color color) {
    return TextStyle(
      fontFamily: 'Lora',
      fontFamilyFallback: const ['Georgia'],
      fontWeight: FontWeight.w500,
      fontSize: 16,
      height: 1.42,
      color: color,
    );
  }

  static TextStyle label(Color color) {
    return TextStyle(
      fontFamily: 'Poppins',
      fontFamilyFallback: const ['Arial'],
      fontWeight: FontWeight.w600,
      fontSize: 14,
      letterSpacing: 0.2,
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
}

class MissionSpacing {
  const MissionSpacing._();

  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 30;
  static const double xxl = 44;
}

class MissionRadius {
  const MissionRadius._();

  static const double sm = 14;
  static const double md = 22;
  static const double lg = 30;
}
