import 'package:flutter/material.dart';

import '../theme/onboarding_tokens.dart';

enum OnboardingButtonVariant { primary, secondary, text }

class OnboardingButton extends StatelessWidget {
  const OnboardingButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = OnboardingButtonVariant.primary,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final OnboardingButtonVariant variant;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = OnboardingColors.resolve(Theme.of(context).brightness);
    final disabled = onPressed == null || isLoading;

    if (variant == OnboardingButtonVariant.text) {
      return TextButton(
        onPressed: disabled ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: colors.secondary,
          padding: const EdgeInsets.symmetric(
            horizontal: OnboardingSpacing.sm,
            vertical: OnboardingSpacing.xs,
          ),
        ),
        child: Text(
          label,
          style: OnboardingTypography.label(
            colors.secondary,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
      );
    }

    final isPrimary = variant == OnboardingButtonVariant.primary;
    final background = isPrimary ? colors.primary : colors.surface;
    final foreground = isPrimary ? colors.onPrimary : colors.textPrimary;
    final borderColor = isPrimary ? colors.primary : colors.border;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: disabled ? 0.55 : 1,
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(OnboardingRadii.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(OnboardingRadii.md),
            onTap: disabled ? null : onPressed,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(OnboardingRadii.md),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: OnboardingSpacing.lg,
                  vertical: OnboardingSpacing.md,
                ),
                child: Center(
                  child: isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              foreground,
                            ),
                          ),
                        )
                      : Text(
                          label,
                          style: OnboardingTypography.title(
                            foreground,
                          ).copyWith(fontSize: 17, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
