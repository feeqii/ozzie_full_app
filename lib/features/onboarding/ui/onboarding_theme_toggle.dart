import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_mode.dart';
import '../theme/onboarding_tokens.dart';

class OnboardingThemeToggle extends ConsumerWidget {
  const OnboardingThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appThemeModeProvider);
    final brightness = Theme.of(context).brightness;
    final colors = OnboardingColors.resolve(Theme.of(context).brightness);

    final isDark = brightness == Brightness.dark;

    return Material(
      color: colors.surface.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: () {
          final nextMode = isDark ? ThemeMode.light : ThemeMode.dark;
          ref.read(appThemeModeProvider.notifier).setThemeMode(nextMode);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: OnboardingSpacing.sm,
            vertical: OnboardingSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                size: 16,
                color: colors.textPrimary,
              ),
              const SizedBox(width: OnboardingSpacing.xs),
              Text(
                isDark ? 'Dark' : 'Light',
                style: OnboardingTypography.label(colors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
