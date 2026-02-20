import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../onboarding/theme/onboarding_tokens.dart';
import '../../onboarding/ui/onboarding_button.dart';
import '../../onboarding/ui/onboarding_scaffold.dart';
import '../../onboarding/ui/onboarding_surface_card.dart';
import '../../onboarding/ui/onboarding_theme_toggle.dart';

class AuthEntryScreen extends StatelessWidget {
  const AuthEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = OnboardingColors.resolve(Theme.of(context).brightness);

    return OnboardingScaffold(
      showBack: true,
      onBack: () => context.go('/auth/onboarding'),
      trailing: const OnboardingThemeToggle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Text(
            'Welcome to Ozzie',
            style: OnboardingTypography.display(colors.textPrimary),
          ),
          const SizedBox(height: OnboardingSpacing.md),
          Text(
            'Create your parent account or sign in to continue your child\'s learning journey.',
            style: OnboardingTypography.body(colors.textSecondary),
          ),
          const SizedBox(height: OnboardingSpacing.xl),
          const OnboardingSurfaceCard(child: _EntryHighlights()),
          const Spacer(),
          OnboardingButton(
            label: 'Create Account',
            onPressed: () => context.push('/auth/signup'),
          ),
          const SizedBox(height: OnboardingSpacing.sm),
          OnboardingButton(
            label: 'Sign In',
            variant: OnboardingButtonVariant.secondary,
            onPressed: () => context.push('/auth/signin'),
          ),
          const SizedBox(height: OnboardingSpacing.sm),
          Text(
            'Email + password access with secure parent PIN setup.',
            textAlign: TextAlign.center,
            style: OnboardingTypography.label(colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _EntryHighlights extends StatelessWidget {
  const _EntryHighlights();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HighlightRow(
          icon: Icons.lock_outline_rounded,
          text: 'Secure parent access',
          color: OnboardingPalette.orange,
        ),
        const SizedBox(height: OnboardingSpacing.sm),
        _HighlightRow(
          icon: Icons.child_care_rounded,
          text: 'Personalized child profiles',
          color: OnboardingPalette.blue,
        ),
        const SizedBox(height: OnboardingSpacing.sm),
        _HighlightRow(
          icon: Icons.timeline_rounded,
          text: 'Simple daily recitation momentum',
          color: OnboardingPalette.green,
        ),
      ],
    );
  }
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = OnboardingColors.resolve(Theme.of(context).brightness);

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: OnboardingSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: OnboardingTypography.body(colors.textPrimary),
          ),
        ),
      ],
    );
  }
}
