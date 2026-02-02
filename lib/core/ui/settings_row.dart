import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    this.value,
    this.showChevron = false,
    this.trailing,
    this.onTap,
  });

  final String label;
  final String? value;
  final bool showChevron;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.progressTrack, width: 1.2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: AppTextStyles.body),
            ),
            if (value != null) ...[
              Text(value!, style: AppTextStyles.caption),
              const SizedBox(width: AppSpacing.sm),
            ],
            if (trailing != null) trailing!,
            if (showChevron) const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
