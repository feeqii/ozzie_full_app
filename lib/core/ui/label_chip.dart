import 'package:flutter/material.dart';

import '../theme/app_extensions.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

class LabelChip extends StatelessWidget {
  const LabelChip({
    super.key,
    required this.label,
    this.background,
    this.borderColor,
    this.foregroundColor,
  });

  final String label;
  final Color? background;
  final Color? borderColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background ?? surfaces.card.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: borderColor ?? surfaces.outlineStrong.withValues(alpha: 0.22),
          width: 1.4,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foregroundColor ?? scheme.onSurface,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.35,
            ),
      ),
    );
  }
}

