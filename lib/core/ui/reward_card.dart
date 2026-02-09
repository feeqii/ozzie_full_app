import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_extensions.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

enum RewardCardVariant { hasanat, badge, trophy }

class RewardCard extends StatelessWidget {
  const RewardCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.variant,
  });

  final String title;
  final String subtitle;
  final RewardCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surfaces.card,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: surfaces.outlineStrong.withValues(alpha: 0.16), width: 1.4),
      ),
      child: Row(
        children: [
          _iconBadge(context),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBadge(BuildContext context) {
    final IconData icon;
    final Color color;

    switch (variant) {
      case RewardCardVariant.hasanat:
        icon = Icons.brightness_1;
        color = AppColors.progressActive;
      case RewardCardVariant.badge:
        icon = Icons.emoji_events_outlined;
        color = AppColors.success;
      case RewardCardVariant.trophy:
        icon = Icons.military_tech_outlined;
        color = AppColors.accentWarning;
    }

    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.4),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
