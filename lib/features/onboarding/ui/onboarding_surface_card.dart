import 'package:flutter/material.dart';

import '../theme/onboarding_tokens.dart';

class OnboardingSurfaceCard extends StatelessWidget {
  const OnboardingSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(OnboardingSpacing.lg),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = OnboardingColors.resolve(Theme.of(context).brightness);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(OnboardingRadii.lg),
        border: Border.all(color: colors.border),
      ),
      child: child,
    );
  }
}
