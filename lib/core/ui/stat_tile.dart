import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.progressTrack, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(), style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.sm),
                Text(value, style: AppTextStyles.title),
              ],
            ),
            Icon(_iconForVariant(), color: AppColors.textNavy, size: 22),
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
