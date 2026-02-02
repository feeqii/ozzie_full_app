import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.black, width: 1.4),
      ),
      child: Row(
        children: [
          _iconBadge(),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle, style: AppTextStyles.body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBadge() {
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
