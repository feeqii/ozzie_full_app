import 'package:flutter/material.dart';

class InnerShadow extends StatelessWidget {
  const InnerShadow({
    super.key,
    required this.child,
    this.color = const Color(0x33000000),
    this.blur = 8,
    this.offset = const Offset(0, 2),
  });

  final Widget child;
  final Color color;
  final double blur;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.0),
                    color.withValues(alpha: 0.4),
                  ],
                  radius: 1.1,
                  center: Alignment(-offset.dx / 20, -offset.dy / 20),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
