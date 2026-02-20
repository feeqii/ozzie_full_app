import 'package:flutter/material.dart';

import '../theme/onboarding_tokens.dart';

class OnboardingHeroTile extends StatelessWidget {
  const OnboardingHeroTile({
    super.key,
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = OnboardingColors.resolve(Theme.of(context).brightness);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OnboardingSpacing.md,
        vertical: OnboardingSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(OnboardingRadii.md),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(OnboardingRadii.sm),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(width: OnboardingSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: OnboardingTypography.body(colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
