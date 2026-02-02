import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum AlertBannerVariant { info, warning, danger, success }

class AlertBanner extends StatelessWidget {
  const AlertBanner({
    super.key,
    required this.message,
    this.variant = AlertBannerVariant.info,
  });

  final String message;
  final AlertBannerVariant variant;

  @override
  Widget build(BuildContext context) {
    final Color color = _color();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body.copyWith(color: AppColors.textNavy),
            ),
          ),
        ],
      ),
    );
  }

  Color _color() {
    switch (variant) {
      case AlertBannerVariant.info:
        return AppColors.textNavy;
      case AlertBannerVariant.warning:
        return AppColors.warning;
      case AlertBannerVariant.danger:
        return AppColors.danger;
      case AlertBannerVariant.success:
        return AppColors.success;
    }
  }
}
