import 'package:flutter/material.dart';

import '../theme/app_extensions.dart';
import 'ozzie_tokens.dart';

@immutable
class OzzieTokensTheme extends ThemeExtension<OzzieTokensTheme> {
  const OzzieTokensTheme({required this.tokens});

  final OzzieTokensV2 tokens;

  @override
  OzzieTokensTheme copyWith({OzzieTokensV2? tokens}) {
    return OzzieTokensTheme(tokens: tokens ?? this.tokens);
  }

  @override
  OzzieTokensTheme lerp(ThemeExtension<OzzieTokensTheme>? other, double t) {
    if (other is! OzzieTokensTheme) return this;
    return t < 0.5 ? this : other;
  }
}

extension OzzieContext on BuildContext {
  OzzieTokensV2 get ozzieTokens {
    return Theme.of(this).extension<OzzieTokensTheme>()?.tokens ??
        OzzieTokensV2.childLight;
  }
}

class OzzieTheme {
  const OzzieTheme._();

  static ThemeData childLight() {
    return _buildTheme(OzzieTokensV2.childLight, Brightness.light);
  }

  static ThemeData parentLight() {
    return _buildTheme(OzzieTokensV2.parentLight, Brightness.light);
  }

  static ThemeData _buildTheme(OzzieTokensV2 tokens, Brightness brightness) {
    final c = tokens.colors;
    final t = tokens.type;

    final scheme = ColorScheme.fromSeed(
      seedColor: c.primary,
      brightness: brightness,
      primary: c.primary,
      secondary: c.secondary,
      error: c.danger,
      surface: c.surface,
      onSurface: c.textPrimary,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onError: Colors.white,
    );

    final textTheme = TextTheme(
      displayLarge: t.displayXL.copyWith(color: c.textPrimary),
      displayMedium: t.displayLG.copyWith(color: c.textPrimary),
      headlineSmall: t.headline.copyWith(color: c.textPrimary),
      titleMedium: t.title.copyWith(color: c.textPrimary),
      bodyLarge: t.bodyStrong.copyWith(color: c.textPrimary),
      bodyMedium: t.body.copyWith(color: c.textSecondary),
      labelMedium: t.label.copyWith(color: c.textSecondary),
      labelSmall: t.caption.copyWith(color: c.textSecondary),
    );

    final legacySurfaces = AppSurfaces(
      canvas: c.canvas,
      canvasSubtle: c.canvasMuted,
      card: c.surface,
      cardSubtle: c.surfaceAccent,
      sheet: c.surface,
      outline: c.outline,
      outlineStrong: c.outlineStrong,
      shadow: c.shadow,
      mapGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          c.mapSky,
          c.mapSky.withValues(alpha: 0.90),
          c.mapHaze.withValues(alpha: 0.70),
          c.canvas,
        ],
      ),
      mapGlow: c.secondary,
      mapFog: c.mapHaze.withValues(alpha: 0.55),
    );

    final legacyMotion = AppMotion(
      fast: tokens.motion.fast,
      medium: tokens.motion.medium,
      slow: tokens.motion.slow,
      standard: tokens.motion.standard,
      emphasized: tokens.motion.emphasized,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: c.canvas,
      colorScheme: scheme,
      textTheme: textTheme,
      fontFamily: t.latinFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: c.canvas,
        foregroundColor: c.textPrimary,
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      cardColor: c.surface,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: t.body.copyWith(
          color: c.textSecondary.withValues(alpha: 0.85),
        ),
        labelStyle: t.label.copyWith(color: c.textSecondary),
        helperStyle: t.caption.copyWith(color: c.textSecondary),
        errorStyle: t.caption.copyWith(color: c.danger),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radius.md),
          borderSide: BorderSide(color: c.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radius.md),
          borderSide: BorderSide(color: c.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radius.md),
          borderSide: BorderSide(color: c.focus, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radius.md),
          borderSide: BorderSide(color: c.danger, width: 1.3),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radius.md),
          borderSide: BorderSide(color: c.danger, width: 1.6),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[
        OzzieTokensTheme(tokens: tokens),
        legacySurfaces,
        legacyMotion,
      ],
    );

    return base;
  }
}
