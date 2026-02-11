import 'package:flutter/material.dart';

@immutable
class OzzieColorTokens {
  const OzzieColorTokens({
    required this.canvas,
    required this.canvasMuted,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.primary,
    required this.primaryPressed,
    required this.primaryGradient,
    required this.secondary,
    required this.secondaryPressed,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.outline,
    required this.outlineStrong,
    required this.focus,
    required this.shadow,
    required this.progressTrack,
    required this.progressFill,
    required this.heroGradient,
    required this.mapSky,
    required this.mapHaze,
  });

  final Color canvas;
  final Color canvasMuted;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceAccent;
  final Color textPrimary;
  final Color textSecondary;
  final Color primary;
  final Color primaryPressed;
  final LinearGradient primaryGradient;
  final Color secondary;
  final Color secondaryPressed;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color outline;
  final Color outlineStrong;
  final Color focus;
  final Color shadow;
  final Color progressTrack;
  final Color progressFill;
  final LinearGradient heroGradient;
  final Color mapSky;
  final Color mapHaze;

  static const OzzieColorTokens childLight = OzzieColorTokens(
    canvas: Color(0xFFF7F8F1),
    canvasMuted: Color(0xFFEBF6E2),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF8FFFB),
    surfaceAccent: Color(0xFFE9F8FF),
    textPrimary: Color(0xFF133041),
    textSecondary: Color(0xFF55707E),
    primary: Color(0xFF58CC02),
    primaryPressed: Color(0xFF49B301),
    primaryGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF7AE629), Color(0xFF58CC02)],
    ),
    secondary: Color(0xFF1CB0F6),
    secondaryPressed: Color(0xFF1591CA),
    success: Color(0xFF58CC02),
    warning: Color(0xFFFFC800),
    danger: Color(0xFFFF6B6B),
    info: Color(0xFF8A6FF6),
    outline: Color(0xFFCEE0D4),
    outlineStrong: Color(0xFF95B8A0),
    focus: Color(0xFF2A8DFF),
    shadow: Color(0x2B0F2430),
    progressTrack: Color(0xFFDDE9E0),
    progressFill: Color(0xFF58CC02),
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1CB0F6), Color(0xFF58CC02)],
    ),
    mapSky: Color(0xFF15395D),
    mapHaze: Color(0xFF6EC8F8),
  );

  static const OzzieColorTokens parentLight = OzzieColorTokens(
    canvas: Color(0xFFF4F5F7),
    canvasMuted: Color(0xFFE7ECF1),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF9FAFB),
    surfaceAccent: Color(0xFFEFF5FA),
    textPrimary: Color(0xFF1F2D3D),
    textSecondary: Color(0xFF5E7082),
    primary: Color(0xFF58CC02),
    primaryPressed: Color(0xFF49B301),
    primaryGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF7AE629), Color(0xFF58CC02)],
    ),
    secondary: Color(0xFF1997D2),
    secondaryPressed: Color(0xFF1577A6),
    success: Color(0xFF4FB700),
    warning: Color(0xFFE3A800),
    danger: Color(0xFFD96060),
    info: Color(0xFF7563D9),
    outline: Color(0xFFD4DCE3),
    outlineStrong: Color(0xFF95A2B1),
    focus: Color(0xFF2A8DFF),
    shadow: Color(0x1F0F2430),
    progressTrack: Color(0xFFDDE3E9),
    progressFill: Color(0xFF58CC02),
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF4A8FB9), Color(0xFF67A34A)],
    ),
    mapSky: Color(0xFF223A53),
    mapHaze: Color(0xFFA4BDD2),
  );
}

@immutable
class OzzieTypeTokens {
  const OzzieTypeTokens({
    required this.latinFamily,
    required this.displayFamily,
    required this.arabicFamily,
    required this.displayXL,
    required this.displayLG,
    required this.headline,
    required this.title,
    required this.body,
    required this.bodyStrong,
    required this.label,
    required this.caption,
    required this.arabicTitle,
    required this.arabicBody,
  });

  final String latinFamily;
  final String displayFamily;
  final String arabicFamily;
  final TextStyle displayXL;
  final TextStyle displayLG;
  final TextStyle headline;
  final TextStyle title;
  final TextStyle body;
  final TextStyle bodyStrong;
  final TextStyle label;
  final TextStyle caption;
  final TextStyle arabicTitle;
  final TextStyle arabicBody;

  static const List<String> latinFallback = <String>[
    'Inter',
    'Avenir Next',
    'Helvetica Neue',
    'Arial',
    'sans-serif',
  ];

  static const List<String> displayFallback = <String>[
    'Nunito',
    'Inter',
    'Avenir Next',
    'Helvetica Neue',
    'sans-serif',
  ];

  static const List<String> arabicFallback = <String>[
    'Noto Naskh Arabic',
    'Amiri',
    'Scheherazade New',
    'serif',
  ];

  static const OzzieTypeTokens child = OzzieTypeTokens(
    latinFamily: 'Nunito',
    displayFamily: 'Baloo2',
    arabicFamily: 'NotoNaskhArabic',
    displayXL: TextStyle(
      fontFamily: 'Baloo2',
      fontSize: 38,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      height: 1.05,
      fontFamilyFallback: displayFallback,
    ),
    displayLG: TextStyle(
      fontFamily: 'Baloo2',
      fontSize: 30,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      height: 1.07,
      fontFamilyFallback: displayFallback,
    ),
    headline: TextStyle(
      fontFamily: 'Baloo2',
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.18,
      height: 1.1,
      fontFamilyFallback: displayFallback,
    ),
    title: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 18,
      fontWeight: FontWeight.w800,
      height: 1.24,
      fontFamilyFallback: latinFallback,
    ),
    body: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.4,
      fontFamilyFallback: latinFallback,
    ),
    bodyStrong: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 16,
      fontWeight: FontWeight.w800,
      height: 1.35,
      fontFamilyFallback: latinFallback,
    ),
    label: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 13,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.25,
      height: 1.2,
      fontFamilyFallback: latinFallback,
    ),
    caption: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
      height: 1.2,
      fontFamilyFallback: latinFallback,
    ),
    arabicTitle: TextStyle(
      fontFamily: 'NotoNaskhArabic',
      fontSize: 23,
      fontWeight: FontWeight.w700,
      height: 1.55,
      fontFamilyFallback: arabicFallback,
    ),
    arabicBody: TextStyle(
      fontFamily: 'NotoNaskhArabic',
      fontSize: 19,
      fontWeight: FontWeight.w600,
      height: 1.62,
      fontFamilyFallback: arabicFallback,
    ),
  );

  static const OzzieTypeTokens parent = OzzieTypeTokens(
    latinFamily: 'Nunito',
    displayFamily: 'Nunito',
    arabicFamily: 'NotoNaskhArabic',
    displayXL: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 34,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.2,
      height: 1.1,
      fontFamilyFallback: latinFallback,
    ),
    displayLG: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 28,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.1,
      height: 1.12,
      fontFamilyFallback: latinFallback,
    ),
    headline: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 22,
      fontWeight: FontWeight.w800,
      height: 1.16,
      fontFamilyFallback: latinFallback,
    ),
    title: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 18,
      fontWeight: FontWeight.w700,
      height: 1.3,
      fontFamilyFallback: latinFallback,
    ),
    body: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.45,
      fontFamilyFallback: latinFallback,
    ),
    bodyStrong: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 16,
      fontWeight: FontWeight.w700,
      height: 1.4,
      fontFamilyFallback: latinFallback,
    ),
    label: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      height: 1.22,
      fontFamilyFallback: latinFallback,
    ),
    caption: TextStyle(
      fontFamily: 'Nunito',
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      height: 1.2,
      fontFamilyFallback: latinFallback,
    ),
    arabicTitle: TextStyle(
      fontFamily: 'NotoNaskhArabic',
      fontSize: 22,
      fontWeight: FontWeight.w700,
      height: 1.6,
      fontFamilyFallback: arabicFallback,
    ),
    arabicBody: TextStyle(
      fontFamily: 'NotoNaskhArabic',
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.65,
      fontFamilyFallback: arabicFallback,
    ),
  );
}

@immutable
class OzzieMotionTokens {
  const OzzieMotionTokens({
    required this.fast,
    required this.medium,
    required this.slow,
    required this.standard,
    required this.emphasized,
  });

  final Duration fast;
  final Duration medium;
  final Duration slow;
  final Curve standard;
  final Curve emphasized;

  static const OzzieMotionTokens playful = OzzieMotionTokens(
    fast: Duration(milliseconds: 130),
    medium: Duration(milliseconds: 240),
    slow: Duration(milliseconds: 420),
    standard: Curves.easeOutCubic,
    emphasized: Curves.easeOutBack,
  );
}

@immutable
class OzzieRadiusTokens {
  const OzzieRadiusTokens({
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.pill,
  });

  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double pill;

  static const OzzieRadiusTokens standard = OzzieRadiusTokens(
    sm: 12,
    md: 16,
    lg: 22,
    xl: 28,
    pill: 999,
  );
}

@immutable
class OzzieElevationTokens {
  const OzzieElevationTokens({
    required this.card,
    required this.button,
    required this.floating,
  });

  final List<BoxShadow> card;
  final List<BoxShadow> button;
  final List<BoxShadow> floating;

  static const OzzieElevationTokens playful = OzzieElevationTokens(
    card: [
      BoxShadow(color: Color(0x1A0A1F2F), blurRadius: 18, offset: Offset(0, 9)),
    ],
    button: [
      BoxShadow(color: Color(0x360F2430), blurRadius: 0, offset: Offset(0, 5)),
    ],
    floating: [
      BoxShadow(
        color: Color(0x220A1F2F),
        blurRadius: 20,
        offset: Offset(0, 10),
      ),
    ],
  );
}

@immutable
class OzzieTokensV2 {
  const OzzieTokensV2({
    required this.colors,
    required this.type,
    required this.motion,
    required this.radius,
    required this.elevation,
  });

  final OzzieColorTokens colors;
  final OzzieTypeTokens type;
  final OzzieMotionTokens motion;
  final OzzieRadiusTokens radius;
  final OzzieElevationTokens elevation;

  static const OzzieTokensV2 childLight = OzzieTokensV2(
    colors: OzzieColorTokens.childLight,
    type: OzzieTypeTokens.child,
    motion: OzzieMotionTokens.playful,
    radius: OzzieRadiusTokens.standard,
    elevation: OzzieElevationTokens.playful,
  );

  static const OzzieTokensV2 parentLight = OzzieTokensV2(
    colors: OzzieColorTokens.parentLight,
    type: OzzieTypeTokens.parent,
    motion: OzzieMotionTokens.playful,
    radius: OzzieRadiusTokens.standard,
    elevation: OzzieElevationTokens.playful,
  );
}
