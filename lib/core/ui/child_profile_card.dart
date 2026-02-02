import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
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
          children: [
            avatar ?? const Avatar(initials: 'OZ'),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.title),
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
