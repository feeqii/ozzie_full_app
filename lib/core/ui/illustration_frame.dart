import 'package:flutter/material.dart';

import '../theme/app_extensions.dart';
import '../theme/app_spacing.dart';

class IllustrationFrame extends StatelessWidget {
  const IllustrationFrame({
    super.key,
    this.child,
    this.size = 150,
    this.variant = IllustrationFrameVariant.standard,
  });

  final Widget? child;
  final double size;
  final IllustrationFrameVariant variant;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final scheme = Theme.of(context).colorScheme;

    final bg = switch (variant) {
      IllustrationFrameVariant.standard => surfaces.cardSubtle,
      IllustrationFrameVariant.map => surfaces.card.withValues(alpha: 0.18),
    };

    final border = switch (variant) {
      IllustrationFrameVariant.standard => surfaces.outlineStrong.withValues(alpha: 0.18),
      IllustrationFrameVariant.map => scheme.onSurface.withValues(alpha: 0.22),
    };

    return Container(
      height: size,
      width: size,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1.6),
      ),
      child: Center(child: child),
    );
  }
}

enum IllustrationFrameVariant { standard, map }

