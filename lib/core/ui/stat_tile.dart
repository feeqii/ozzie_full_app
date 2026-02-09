import 'package:flutter/material.dart';

import '../theme/app_extensions.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

enum StatTileVariant { streak, time, score }

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.title,
    required this.value,
    required this.variant,
    this.onTap,
  });

  final String title;
  final String value;
  final StatTileVariant variant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: surfaces.card,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: surfaces.outlineStrong.withValues(alpha: 0.18), width: 1.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(), style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(value, style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
            Icon(_iconForVariant(), color: scheme.onSurface, size: 22),
          ],
        ),
      ),
    );
  }

  IconData _iconForVariant() {
    switch (variant) {
      case StatTileVariant.streak:
        return Icons.local_fire_department_outlined;
      case StatTileVariant.time:
        return Icons.timer_outlined;
      case StatTileVariant.score:
        return Icons.score_outlined;
    }
  }
}
