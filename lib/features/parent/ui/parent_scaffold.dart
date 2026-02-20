import 'dart:ui';

import 'package:flutter/material.dart';

import 'parent_tokens.dart';

class ParentScaffold extends StatelessWidget {
  const ParentScaffold({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(
      ParentSpacing.md,
      ParentSpacing.sm,
      ParentSpacing.md,
      ParentSpacing.lg,
    ),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

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
                    colors.background.withValues(alpha: 0.97),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -140,
            top: -140,
            child: _SoftGlow(
              color: ParentPalette.blue.withValues(alpha: 0.08),
              size: 300,
            ),
          ),
          Positioned(
            left: -140,
            bottom: -160,
            child: _SoftGlow(
              color: ParentPalette.orange.withValues(alpha: 0.08),
              size: 330,
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: Padding(padding: padding, child: child),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftGlow extends StatelessWidget {
  const _SoftGlow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
