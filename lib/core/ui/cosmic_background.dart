import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_extensions.dart';

class CosmicBackground extends StatelessWidget {
  const CosmicBackground({
    super.key,
    this.parallax = 0,
    this.seed = 7,
  });

  /// Horizontal parallax offset in logical pixels.
  final double parallax;

  final int seed;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;

    return Stack(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(gradient: surfaces.mapGradient),
          child: const SizedBox.expand(),
        ),
        Positioned.fill(
          child: Transform.translate(
            offset: Offset(parallax, 0),
            child: CustomPaint(
              painter: _StarfieldPainter(
                seed: seed,
                tint: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ),
        ),
        // A soft, narrative glow. It gives depth without feeling "neon".
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.65, -0.6),
                radius: 1.1,
                colors: [
                  surfaces.mapGlow.withValues(alpha: 0.22),
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

class _StarfieldPainter extends CustomPainter {
  _StarfieldPainter({
    required this.seed,
    required this.tint,
  });

  final int seed;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Small stars.
    final count = (size.shortestSide * 0.35).clamp(120, 240).round();
    for (var i = 0; i < count; i++) {
      final x = _hash(i * 3, seed) * size.width;
      final y = _hash(i * 5, seed + 11) * size.height;
      final r = 0.6 + _hash(i * 7, seed + 23) * 1.6;
      final a = 0.08 + _hash(i * 9, seed + 37) * 0.35;
      paint.color = tint.withValues(alpha: a);
      canvas.drawCircle(Offset(x, y), r, paint);
    }

    // A few bright "anchor" stars with a tiny cross.
    for (var i = 0; i < 18; i++) {
      final x = _hash(i * 13, seed + 101) * size.width;
      final y = _hash(i * 17, seed + 203) * size.height;
      final r = 1.2 + _hash(i * 19, seed + 307) * 1.8;
      paint.color = Colors.white.withValues(alpha: 0.28);
      canvas.drawCircle(Offset(x, y), r, paint);

      paint
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.12);
      canvas.drawLine(Offset(x - r * 2.2, y), Offset(x + r * 2.2, y), paint);
      canvas.drawLine(Offset(x, y - r * 2.2), Offset(x, y + r * 2.2), paint);
      paint.style = PaintingStyle.fill;
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) {
    return oldDelegate.seed != seed || oldDelegate.tint != tint;
  }
}

// Intentionally no "checker grid" layer: the cosmic map background should read
// as space, not graph paper. The atlas vibe comes from stars + glow instead.
