import 'package:flutter/material.dart';

import '../theme/app_extensions.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import 'avatar.dart';

class ChildProfileCard extends StatelessWidget {
  const ChildProfileCard({
    super.key,
    required this.name,
    required this.subtitle,
    this.avatar,
    this.onTap,
  });

  final String name;
  final String subtitle;
  final Widget? avatar;
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
          border: Border.all(color: surfaces.outlineStrong.withValues(alpha: 0.16), width: 1.2),
        ),
        child: Row(
          children: [
            avatar ?? const Avatar(initials: 'OZ'),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: scheme.onSurface.withValues(alpha: 0.8)),
          ],
        ),
      ),
    );
  }
}
