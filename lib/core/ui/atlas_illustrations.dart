import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_extensions.dart';

enum AtlasIllustrationKind {
  lesson,
  recite,
  quiz,
  success,
  retry,
  sleep,
  hasanat,
  badge,
  trophy,
  locked,
}

/// Small, bespoke "Cosmic Atlas" glyphs used inside [IllustrationFrame] and
/// reward/feedback UI. Drawn with a painter to avoid relying on platform fonts.
class AtlasIllustration extends StatelessWidget {
  const AtlasIllustration({
    super.key,
    required this.kind,
    this.primary,
    this.accent,
    this.glow,
  });

  final AtlasIllustrationKind kind;
  final Color? primary;
  final Color? accent;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surfaces = context.surfaces;

    return RepaintBoundary(
      child: CustomPaint(
        painter: _AtlasIllustrationPainter(
          kind: kind,
          primary: primary ?? scheme.onSurface,
          accent: accent ?? scheme.primary,
          glow: glow ?? surfaces.mapGlow,
          fog: surfaces.mapFog,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _AtlasIllustrationPainter extends CustomPainter {
  const _AtlasIllustrationPainter({
    required this.kind,
    required this.primary,
    required this.accent,
    required this.glow,
    required this.fog,
  });

  final AtlasIllustrationKind kind;
  final Color primary;
  final Color accent;
  final Color glow;
  final Color fog;

  @override
  void paint(Canvas canvas, Size size) {
    final d = math.min(size.width, size.height);
    final dx = (size.width - d) / 2;
    final dy = (size.height - d) / 2;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(d / 100.0, d / 100.0);

    switch (kind) {
      case AtlasIllustrationKind.lesson:
        _paintLesson(canvas);
        break;
      case AtlasIllustrationKind.recite:
        _paintRecite(canvas);
        break;
      case AtlasIllustrationKind.quiz:
        _paintQuiz(canvas);
        break;
      case AtlasIllustrationKind.success:
        _paintSuccess(canvas);
        break;
      case AtlasIllustrationKind.retry:
        _paintRetry(canvas);
        break;
      case AtlasIllustrationKind.sleep:
        _paintSleep(canvas);
        break;
      case AtlasIllustrationKind.hasanat:
        _paintHasanat(canvas);
        break;
      case AtlasIllustrationKind.badge:
        _paintBadge(canvas);
        break;
      case AtlasIllustrationKind.trophy:
        _paintTrophy(canvas);
        break;
      case AtlasIllustrationKind.locked:
        _paintLocked(canvas);
        break;
    }

    canvas.restore();
  }

  Paint _stroke(Color color, double width) {
    return Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
  }

  Paint _fill(Color color) {
    return Paint()
      ..color = color
      ..style = PaintingStyle.fill;
  }

  void _sparkle(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r * 0.38, c.dy - r * 0.38)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx + r * 0.38, c.dy + r * 0.38)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r * 0.38, c.dy + r * 0.38)
      ..lineTo(c.dx - r, c.dy)
      ..lineTo(c.dx - r * 0.38, c.dy - r * 0.38)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _paintLesson(Canvas canvas) {
    final ink = _stroke(primary.withValues(alpha: 0.88), 3.4);
    final soft = _fill(accent.withValues(alpha: 0.10));

    final left = RRect.fromRectAndRadius(
      const Rect.fromLTWH(16, 26, 32, 46),
      const Radius.circular(8),
    );
    final right = RRect.fromRectAndRadius(
      const Rect.fromLTWH(52, 26, 32, 46),
      const Radius.circular(8),
    );
    canvas.drawRRect(left, soft);
    canvas.drawRRect(right, soft);
    canvas.drawRRect(left, ink);
    canvas.drawRRect(right, ink);

    // Spine + page lines.
    canvas.drawLine(
      const Offset(50, 28),
      const Offset(50, 70),
      _stroke(primary.withValues(alpha: 0.55), 2.2),
    );
    canvas.drawLine(
      const Offset(22, 38),
      const Offset(42, 38),
      _stroke(primary.withValues(alpha: 0.35), 2.0),
    );
    canvas.drawLine(
      const Offset(58, 44),
      const Offset(78, 44),
      _stroke(primary.withValues(alpha: 0.35), 2.0),
    );

    // Small "navigator star" bookmark.
    _sparkle(
      canvas,
      const Offset(76, 30),
      5.2,
      _fill(glow.withValues(alpha: 0.9)),
    );
    canvas.drawCircle(
      const Offset(28, 74),
      2.4,
      _fill(primary.withValues(alpha: 0.28)),
    );
  }

  void _paintRecite(Canvas canvas) {
    final shell = _stroke(primary.withValues(alpha: 0.9), 3.0);
    final shellSoft = _fill(primary.withValues(alpha: 0.06));
    final accentFill = _fill(accent.withValues(alpha: 0.2));

    // Soft backplate to make the icon feel less mechanical.
    canvas.drawCircle(
      const Offset(44, 42),
      24,
      _fill(accent.withValues(alpha: 0.1)),
    );

    // Capsule microphone body.
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(33, 18, 22, 40),
      const Radius.circular(12),
    );
    canvas.drawRRect(body, shellSoft);
    canvas.drawRRect(body, shell);

    // Inner grille hint.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(38, 28, 12, 18),
        const Radius.circular(6),
      ),
      accentFill,
    );
    canvas.drawLine(
      const Offset(44, 58),
      const Offset(44, 72),
      _stroke(primary.withValues(alpha: 0.86), 2.8),
    );

    // Base.
    final foot = RRect.fromRectAndRadius(
      const Rect.fromLTWH(30, 72, 28, 11),
      const Radius.circular(7),
    );
    canvas.drawRRect(foot, _fill(primary.withValues(alpha: 0.1)));
    canvas.drawRRect(foot, _stroke(primary.withValues(alpha: 0.62), 2.2));

    // Wave arcs are intentionally warm/neutral to avoid blue tones.
    final wave1 = _stroke(accent.withValues(alpha: 0.9), 2.6);
    final wave2 = _stroke(glow.withValues(alpha: 0.84), 2.4);
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(48, 39), radius: 24),
      -0.62,
      1.03,
      false,
      wave1,
    );
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(48, 39), radius: 31),
      -0.48,
      0.78,
      false,
      wave2,
    );

    canvas.drawCircle(
      const Offset(62, 24),
      3.0,
      _fill(accent.withValues(alpha: 0.58)),
    );
  }

  void _paintQuiz(Canvas canvas) {
    final outline = _stroke(primary.withValues(alpha: 0.86), 3.2);
    final soft = _fill(accent.withValues(alpha: 0.10));

    final bubble = RRect.fromRectAndRadius(
      const Rect.fromLTWH(18, 22, 64, 44),
      const Radius.circular(14),
    );
    canvas.drawRRect(bubble, soft);
    canvas.drawRRect(bubble, outline);

    // Tail.
    final tail = Path()
      ..moveTo(36, 66)
      ..lineTo(28, 76)
      ..lineTo(44, 70)
      ..close();
    canvas.drawPath(tail, soft);
    canvas.drawPath(tail, outline);

    // Question mark.
    final q = Path()
      ..moveTo(44, 36)
      ..cubicTo(44, 30, 50, 28, 55, 30)
      ..cubicTo(60, 32, 62, 38, 58, 42)
      ..cubicTo(55, 45, 51, 46, 51, 50)
      ..lineTo(51, 52);
    canvas.drawPath(q, _stroke(glow.withValues(alpha: 0.95), 4.4));
    canvas.drawCircle(
      const Offset(51, 58),
      2.7,
      _fill(glow.withValues(alpha: 0.95)),
    );

    _sparkle(
      canvas,
      const Offset(78, 18),
      4.0,
      _fill(primary.withValues(alpha: 0.18)),
    );
    canvas.drawCircle(
      const Offset(26, 18),
      2.6,
      _fill(primary.withValues(alpha: 0.22)),
    );
  }

  void _paintSuccess(Canvas canvas) {
    // Rays.
    final ray = _stroke(glow.withValues(alpha: 0.85), 2.2);
    for (var i = 0; i < 10; i++) {
      final a = i * (math.pi * 2 / 10);
      final p1 = Offset(50 + math.cos(a) * 24, 50 + math.sin(a) * 24);
      final p2 = Offset(50 + math.cos(a) * 32, 50 + math.sin(a) * 32);
      canvas.drawLine(p1, p2, ray);
    }

    // Seal ring.
    canvas.drawCircle(
      const Offset(50, 50),
      22,
      _stroke(primary.withValues(alpha: 0.22), 2.6),
    );

    // Check.
    final check = Path()
      ..moveTo(38, 52)
      ..lineTo(47, 61)
      ..lineTo(66, 40);
    canvas.drawPath(
      check,
      _stroke(AppColors.success.withValues(alpha: 0.95), 6.0),
    );

    canvas.drawCircle(
      const Offset(70, 64),
      2.2,
      _fill(primary.withValues(alpha: 0.22)),
    );
    canvas.drawCircle(
      const Offset(30, 38),
      2.6,
      _fill(primary.withValues(alpha: 0.18)),
    );
  }

  void _paintRetry(Canvas canvas) {
    final ring = _stroke(AppColors.danger.withValues(alpha: 0.9), 3.8);
    final soft = _fill(accent.withValues(alpha: 0.08));

    canvas.drawCircle(const Offset(50, 50), 24, soft);
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(50, 50), radius: 26),
      0.30,
      math.pi * 1.65,
      false,
      ring,
    );

    // Arrow head.
    final end = Offset(
      50 + math.cos(0.30 + math.pi * 1.65) * 26,
      50 + math.sin(0.30 + math.pi * 1.65) * 26,
    );
    final tip = end;
    final left = Offset(tip.dx - 6, tip.dy - 2);
    final right = Offset(tip.dx - 1, tip.dy - 7);
    final arrow = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(arrow, _fill(AppColors.danger.withValues(alpha: 0.9)));

    // Tiny star to hint "keep going".
    _sparkle(
      canvas,
      const Offset(34, 32),
      4.6,
      _fill(glow.withValues(alpha: 0.85)),
    );
  }

  void _paintSleep(Canvas canvas) {
    final moonFill = _fill(AppColors.warning.withValues(alpha: 0.18));
    final moonStroke = _stroke(primary.withValues(alpha: 0.72), 3.0);

    // Crescent via two circles.
    final big = Path()
      ..addOval(Rect.fromCircle(center: const Offset(46, 46), radius: 20));
    final cut = Path()
      ..addOval(Rect.fromCircle(center: const Offset(56, 40), radius: 18));
    final crescent = Path.combine(PathOperation.difference, big, cut);
    canvas.drawPath(crescent, moonFill);
    canvas.drawPath(crescent, moonStroke);

    // Little stars.
    _sparkle(
      canvas,
      const Offset(72, 28),
      4.2,
      _fill(glow.withValues(alpha: 0.8)),
    );
    canvas.drawCircle(
      const Offset(72, 66),
      2.2,
      _fill(primary.withValues(alpha: 0.22)),
    );

    // "Zzz" as three slanted marks.
    final z = _stroke(primary.withValues(alpha: 0.35), 2.2);
    canvas.drawLine(const Offset(22, 70), const Offset(30, 62), z);
    canvas.drawLine(const Offset(22, 62), const Offset(30, 54), z);
    canvas.drawLine(const Offset(22, 54), const Offset(30, 46), z);
  }

  void _paintHasanat(Canvas canvas) {
    final soft = _fill(accent.withValues(alpha: 0.12));
    final outline = _stroke(primary.withValues(alpha: 0.55), 2.4);

    // A gentle "swirl" coin.
    canvas.drawCircle(const Offset(50, 52), 22, soft);
    canvas.drawCircle(const Offset(50, 52), 22, outline);
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(50, 52), radius: 14),
      -0.6,
      3.2,
      false,
      _stroke(glow.withValues(alpha: 0.85), 3.2),
    );

    // Sparkles around.
    _sparkle(
      canvas,
      const Offset(76, 24),
      6.0,
      _fill(glow.withValues(alpha: 0.9)),
    );
    _sparkle(
      canvas,
      const Offset(26, 30),
      4.6,
      _fill(primary.withValues(alpha: 0.18)),
    );
    canvas.drawCircle(
      const Offset(30, 78),
      2.6,
      _fill(primary.withValues(alpha: 0.22)),
    );
  }

  void _paintBadge(Canvas canvas) {
    final outline = _stroke(primary.withValues(alpha: 0.82), 3.0);
    final medalFill = _fill(accent.withValues(alpha: 0.12));

    // Medal circle.
    canvas.drawCircle(const Offset(50, 42), 18, medalFill);
    canvas.drawCircle(const Offset(50, 42), 18, outline);
    _sparkle(
      canvas,
      const Offset(50, 42),
      7.2,
      _fill(glow.withValues(alpha: 0.9)),
    );

    // Ribbons.
    final ribbon = Path()
      ..moveTo(40, 58)
      ..lineTo(32, 84)
      ..lineTo(46, 78)
      ..lineTo(50, 62)
      ..close();
    canvas.drawPath(ribbon, _fill(primary.withValues(alpha: 0.08)));
    canvas.drawPath(ribbon, _stroke(primary.withValues(alpha: 0.55), 2.2));

    final ribbon2 = Path()
      ..moveTo(60, 58)
      ..lineTo(68, 84)
      ..lineTo(54, 78)
      ..lineTo(50, 62)
      ..close();
    canvas.drawPath(ribbon2, _fill(primary.withValues(alpha: 0.08)));
    canvas.drawPath(ribbon2, _stroke(primary.withValues(alpha: 0.55), 2.2));
  }

  void _paintTrophy(Canvas canvas) {
    final outline = _stroke(primary.withValues(alpha: 0.86), 3.0);
    final fill = _fill(accent.withValues(alpha: 0.12));

    final cup = Path()
      ..moveTo(34, 28)
      ..lineTo(66, 28)
      ..lineTo(62, 54)
      ..quadraticBezierTo(50, 64, 38, 54)
      ..close();
    canvas.drawPath(cup, fill);
    canvas.drawPath(cup, outline);

    // Handles.
    canvas.drawArc(
      const Rect.fromLTWH(22, 28, 18, 22),
      math.pi * 0.6,
      math.pi * 0.8,
      false,
      outline,
    );
    canvas.drawArc(
      const Rect.fromLTWH(60, 28, 18, 22),
      math.pi * 1.6,
      math.pi * 0.8,
      false,
      outline,
    );

    // Stem + base.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(44, 64, 12, 10),
        const Radius.circular(6),
      ),
      _fill(primary.withValues(alpha: 0.08)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(44, 64, 12, 10),
        const Radius.circular(6),
      ),
      _stroke(primary.withValues(alpha: 0.55), 2.2),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(32, 76, 36, 10),
        const Radius.circular(8),
      ),
      _fill(primary.withValues(alpha: 0.06)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(32, 76, 36, 10),
        const Radius.circular(8),
      ),
      _stroke(primary.withValues(alpha: 0.50), 2.2),
    );

    _sparkle(
      canvas,
      const Offset(50, 42),
      6.4,
      _fill(glow.withValues(alpha: 0.85)),
    );
  }

  void _paintLocked(Canvas canvas) {
    final outline = _stroke(primary.withValues(alpha: 0.78), 3.0);
    final bodyFill = _fill(fog.withValues(alpha: 0.35));

    // Body.
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(32, 48, 36, 30),
      const Radius.circular(10),
    );
    canvas.drawRRect(body, bodyFill);
    canvas.drawRRect(body, outline);

    // Shackle.
    canvas.drawArc(
      const Rect.fromLTWH(34, 26, 32, 32),
      math.pi,
      math.pi,
      false,
      outline,
    );

    // Keyhole.
    canvas.drawCircle(
      const Offset(50, 62),
      3.4,
      _fill(primary.withValues(alpha: 0.45)),
    );
    canvas.drawLine(
      const Offset(50, 65),
      const Offset(50, 72),
      _stroke(primary.withValues(alpha: 0.45), 2.0),
    );
  }

  @override
  bool shouldRepaint(covariant _AtlasIllustrationPainter oldDelegate) {
    return oldDelegate.kind != kind ||
        oldDelegate.primary != primary ||
        oldDelegate.accent != accent ||
        oldDelegate.glow != glow ||
        oldDelegate.fog != fog;
  }
}
