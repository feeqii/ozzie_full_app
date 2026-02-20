import 'dart:ui';

import 'package:flutter/material.dart';

import 'mission_tokens.dart';

class MissionScaffold extends StatelessWidget {
  const MissionScaffold({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: MissionSpacing.lg,
      vertical: MissionSpacing.md,
    ),
    this.extendToBottom = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool extendToBottom;

  @override
  Widget build(BuildContext context) {
    final colors = MissionColors.resolve(Theme.of(context).brightness);

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.background,
                    colors.background.withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -90,
            child: _GlowBlob(
              color: MissionPalette.blue.withValues(alpha: 0.14),
              size: 260,
            ),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: _GlowBlob(
              color: MissionPalette.orange.withValues(alpha: 0.14),
              size: 290,
            ),
          ),
          SafeArea(
            bottom: !extendToBottom,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(padding: padding, child: child),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
