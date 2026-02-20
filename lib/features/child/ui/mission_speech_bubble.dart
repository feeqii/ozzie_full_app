import 'package:flutter/material.dart';

import 'mission_tokens.dart';

class MissionSpeechBubble extends StatelessWidget {
  const MissionSpeechBubble({
    super.key,
    required this.text,
    this.align = Alignment.center,
  });

  final String text;
  final Alignment align;

  @override
  Widget build(BuildContext context) {
    final colors = MissionColors.resolve(Theme.of(context).brightness);

    return Align(
      alignment: align,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(
              horizontal: MissionSpacing.md,
              vertical: MissionSpacing.md,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(MissionRadius.sm),
              border: Border.all(color: colors.textPrimary, width: 1.1),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: MissionText.title(
                colors.textPrimary,
              ).copyWith(fontSize: 17),
            ),
          ),
          CustomPaint(
            size: const Size(26, 14),
            painter: _BubbleTailPainter(
              fill: colors.surface,
              stroke: colors.textPrimary,
              shadow: colors.shadow,
            ),
          ),
        ],
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  const _BubbleTailPainter({
    required this.fill,
    required this.stroke,
    required this.shadow,
  });

  final Color fill;
  final Color stroke;
  final Color shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawShadow(path, shadow, 2.2, false);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) {
    return fill != oldDelegate.fill ||
        stroke != oldDelegate.stroke ||
        shadow != oldDelegate.shadow;
  }
}
