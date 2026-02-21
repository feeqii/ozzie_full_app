import 'package:flutter/material.dart';

import 'app_colors.dart';

@immutable
class AppSurfaces extends ThemeExtension<AppSurfaces> {
  const AppSurfaces({
    required this.canvas,
    required this.canvasSubtle,
    required this.card,
    required this.cardSubtle,
    required this.sheet,
    required this.outline,
    required this.outlineStrong,
    required this.shadow,
    required this.mapGlow,
    required this.mapFog,
  });

  /// Standard app background for non-map screens.
  final Color canvas;

  /// Subtle background layer, used for pills and soft cards.
  final Color canvasSubtle;

  /// Card surface color.
  final Color card;

  /// Softer card surface used behind controls and as secondary panels.
  final Color cardSubtle;

  /// Bottom sheets / modals.
  final Color sheet;

  /// Light outline for interactive surfaces.
  final Color outline;

  /// Strong outline for key controls (CTA, selected).
  final Color outlineStrong;

  /// Shadow tint (not the shadow itself).
  final Color shadow;

  /// Glow tint used on active nodes and progress paths.
  final Color mapGlow;

  /// Fog tint used for locked content.
  final Color mapFog;

  static AppSurfaces light() {
    return AppSurfaces(
      canvas: const Color(0xFFFFFCF6),
      canvasSubtle: const Color(0xFFF1F3F6),
      card: const Color(0xFFFFFEFB),
      cardSubtle: const Color(0xFFF2F5F8),
      sheet: const Color(0xFFFFFEFB),
      outline: const Color(0x1A042748),
      outlineStrong: AppColors.textNavy,
      shadow: const Color(0x33000000),
      mapGlow: const Color(0xFF7AE7FF),
      mapFog: const Color(0x99C8D3DE),
    );
  }

  static AppSurfaces dark() {
    return AppSurfaces(
      canvas: const Color(0xFF07162B),
      canvasSubtle: const Color(0xFF0B213B),
      card: const Color(0xFF0B213B),
      cardSubtle: const Color(0xFF0E2A47),
      sheet: const Color(0xFF0B213B),
      outline: const Color(0x33F6F3E6),
      outlineStrong: const Color(0xFFF6F3E6),
      shadow: const Color(0xAA000000),
      mapGlow: const Color(0xFF7AE7FF),
      mapFog: const Color(0x660B213B),
    );
  }

  @override
  AppSurfaces copyWith({
    Color? canvas,
    Color? canvasSubtle,
    Color? card,
    Color? cardSubtle,
    Color? sheet,
    Color? outline,
    Color? outlineStrong,
    Color? shadow,
    Color? mapGlow,
    Color? mapFog,
  }) {
    return AppSurfaces(
      canvas: canvas ?? this.canvas,
      canvasSubtle: canvasSubtle ?? this.canvasSubtle,
      card: card ?? this.card,
      cardSubtle: cardSubtle ?? this.cardSubtle,
      sheet: sheet ?? this.sheet,
      outline: outline ?? this.outline,
      outlineStrong: outlineStrong ?? this.outlineStrong,
      shadow: shadow ?? this.shadow,
      mapGlow: mapGlow ?? this.mapGlow,
      mapFog: mapFog ?? this.mapFog,
    );
  }

  @override
  AppSurfaces lerp(ThemeExtension<AppSurfaces>? other, double t) {
    if (other is! AppSurfaces) return this;
    return AppSurfaces(
      canvas: Color.lerp(canvas, other.canvas, t) ?? canvas,
      canvasSubtle: Color.lerp(canvasSubtle, other.canvasSubtle, t) ?? canvasSubtle,
      card: Color.lerp(card, other.card, t) ?? card,
      cardSubtle: Color.lerp(cardSubtle, other.cardSubtle, t) ?? cardSubtle,
      sheet: Color.lerp(sheet, other.sheet, t) ?? sheet,
      outline: Color.lerp(outline, other.outline, t) ?? outline,
      outlineStrong: Color.lerp(outlineStrong, other.outlineStrong, t) ?? outlineStrong,
      shadow: Color.lerp(shadow, other.shadow, t) ?? shadow,
      mapGlow: Color.lerp(mapGlow, other.mapGlow, t) ?? mapGlow,
      mapFog: Color.lerp(mapFog, other.mapFog, t) ?? mapFog,
    );
  }
}

@immutable
class AppMotion extends ThemeExtension<AppMotion> {
  const AppMotion({
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

  static const AppMotion defaults = AppMotion(
    fast: Duration(milliseconds: 120),
    medium: Duration(milliseconds: 220),
    slow: Duration(milliseconds: 420),
    standard: Curves.easeOutCubic,
    emphasized: Curves.easeOutBack,
  );

  @override
  AppMotion copyWith({
    Duration? fast,
    Duration? medium,
    Duration? slow,
    Curve? standard,
    Curve? emphasized,
  }) {
    return AppMotion(
      fast: fast ?? this.fast,
      medium: medium ?? this.medium,
      slow: slow ?? this.slow,
      standard: standard ?? this.standard,
      emphasized: emphasized ?? this.emphasized,
    );
  }

  @override
  AppMotion lerp(ThemeExtension<AppMotion>? other, double t) {
    if (other is! AppMotion) return this;
    Duration lerpDuration(Duration a, Duration b) {
      return Duration(
        milliseconds: (a.inMilliseconds + (b.inMilliseconds - a.inMilliseconds) * t).round(),
      );
    }

    // Curves cannot be lerped meaningfully; switch at halfway.
    return AppMotion(
      fast: lerpDuration(fast, other.fast),
      medium: lerpDuration(medium, other.medium),
      slow: lerpDuration(slow, other.slow),
      standard: t < 0.5 ? standard : other.standard,
      emphasized: t < 0.5 ? emphasized : other.emphasized,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppSurfaces get surfaces => Theme.of(this).extension<AppSurfaces>() ?? AppSurfaces.light();
  AppMotion get motion => Theme.of(this).extension<AppMotion>() ?? AppMotion.defaults;
}
