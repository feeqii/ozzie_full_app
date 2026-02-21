import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_extensions.dart';

/// A subtle "atlas paper" background for lesson/engine screens.
///
/// This keeps the cartographic texture + tiny stars aesthetic, but tuned for
/// readability under content-heavy UI.
class AtlasBackground extends StatelessWidget {
  const AtlasBackground({
    super.key,
    this.seed = 13,
    this.intensity = 1.0,
    this.showGrid = true,
  });

  final int seed;

  /// 0..1 multiplier for pattern opacity.
  final double intensity;

  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        surfaces.canvas,
        Color.lerp(surfaces.canvas, scheme.primary.withValues(alpha: isDark ? 0.10 : 0.06), 0.55) ?? surfaces.canvas,
        surfaces.canvasSubtle,
      ],
      stops: const [0, 0.55, 1],
    );

    final dotTint = scheme.onSurface.withValues(alpha: (isDark ? 0.14 : 0.09) * intensity);
    final gridTint = scheme.onSurface.withValues(alpha: (isDark ? 0.06 : 0.035) * intensity);
    final glowTint = scheme.primary.withValues(alpha: (isDark ? 0.20 : 0.10) * intensity);

    return Stack(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(gradient: bg),
          child: const SizedBox.expand(),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _PaperSpecklePainter(
              seed: seed,
              tint: dotTint,
            ),
          ),
        ),
        if (showGrid)
          Positioned.fill(
            child: CustomPaint(
              painter: _SoftGridPainter(tint: gridTint),
            ),
          ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.75, -0.55),
                radius: 1.05,
                colors: [
                  glowTint,
                  Colors.transparent,
                ],
                stops: const [0, 1],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

double _fract(double x) => x - x.floorToDouble();

double _hash(int i, int seed) {
  final v = math.sin((i + seed) * 12.9898) * 43758.5453;
  return _fract(v.abs());
}

class _PaperSpecklePainter extends CustomPainter {
  _PaperSpecklePainter({required this.seed, required this.tint});

  final int seed;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Speckles and tiny "stars". Low-contrast on purpose.
    final count = (size.shortestSide * 0.42).clamp(140, 280).round();
    for (var i = 0; i < count; i++) {
      final x = _hash(i * 3, seed) * size.width;
      final y = _hash(i * 5, seed + 11) * size.height;
      final r = 0.5 + _hash(i * 7, seed + 23) * 1.35;
      final a = 0.10 + _hash(i * 9, seed + 37) * 0.55;
      paint.color = tint.withValues(alpha: tint.a * a);
      canvas.drawCircle(Offset(x, y), r, paint);
    }

    // A few anchor dots to give the background "constellation" character.
    for (var i = 0; i < 18; i++) {
      final x = _hash(i * 13, seed + 101) * size.width;
      final y = _hash(i * 17, seed + 203) * size.height;
      final r = 1.1 + _hash(i * 19, seed + 307) * 1.4;
      paint.color = tint.withValues(alpha: tint.a * 0.9);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PaperSpecklePainter oldDelegate) {
    return oldDelegate.seed != seed || oldDelegate.tint != tint;
  }
}

class _SoftGridPainter extends CustomPainter {
  _SoftGridPainter({required this.tint});

  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = tint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final gap = (size.shortestSide / 7).clamp(54.0, 110.0);

    for (double x = -gap; x < size.width + gap; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = -gap; y < size.height + gap; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SoftGridPainter oldDelegate) {
    return oldDelegate.tint != tint;
  }
}
