import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: Size(fullWidth ? double.infinity : 0, 48),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          side: const BorderSide(color: AppColors.black, width: 1.4),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textNavy,
          ),
        ),
      ),
    );
  }
}
