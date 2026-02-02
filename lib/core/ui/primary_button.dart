import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum PrimaryButtonVariant { primary, success, warning, danger }

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = PrimaryButtonVariant.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final PrimaryButtonVariant variant;
  final bool isLoading;
  final bool isDisabled;
  final bool fullWidth;

  bool get _disabled => isDisabled || onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    final Size minSize = Size(fullWidth ? double.infinity : 0, 52);

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          gradient: _disabled ? null : _gradient(),
          color: _disabled ? AppColors.gamificationLight : _solidColor(),
          boxShadow: _disabled ? [] : AppShadows.buttonAccent,
        ),
        child: TextButton(
          style: TextButton.styleFrom(
            minimumSize: minSize,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              side: BorderSide(
                color: _disabled
                    ? AppColors.progressTrack
                    : _borderColor(),
                width: 1.4,
              ),
            ),
          ),
          onPressed: _disabled ? null : onPressed,
          child: isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                )
              : Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _disabled ? AppColors.textMuted : AppColors.white,
                  ),
                ),
        ),
      ),
    );
  }

  LinearGradient? _gradient() {
    if (variant != PrimaryButtonVariant.primary) {
      return null;
    }
    return AppColors.primaryGradient;
  }

  Color? _solidColor() {
    switch (variant) {
      case PrimaryButtonVariant.primary:
        return null;
      case PrimaryButtonVariant.success:
        return AppColors.success;
      case PrimaryButtonVariant.warning:
        return AppColors.warning;
      case PrimaryButtonVariant.danger:
        return AppColors.danger;
    }
  }

  Color _borderColor() {
    switch (variant) {
      case PrimaryButtonVariant.primary:
        return AppColors.black;
      case PrimaryButtonVariant.success:
        return AppColors.accentSuccess;
      case PrimaryButtonVariant.warning:
        return AppColors.accentWarning;
      case PrimaryButtonVariant.danger:
        return AppColors.danger;
    }
  }
}
