import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class LabelChip extends StatelessWidget {
  const LabelChip({
    super.key,
    required this.label,
    this.background = AppColors.white,
    this.borderColor = AppColors.black,
  });

  final String label;
  final Color background;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: AppColors.textNavy),
      ),
    );
  }
}
