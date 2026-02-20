import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../child/providers/child_providers.dart';
import '../../onboarding/theme/onboarding_tokens.dart';
import '../../onboarding/ui/onboarding_button.dart';
import '../../onboarding/ui/onboarding_scaffold.dart';
import '../../onboarding/ui/onboarding_surface_card.dart';
import '../../onboarding/ui/onboarding_theme_toggle.dart';

class SelectChildScreen extends ConsumerWidget {
  const SelectChildScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenProvider);

    return OnboardingScaffold(
      showBack: false,
      trailing: const OnboardingThemeToggle(),
      child: childrenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            _ErrorState(onRetry: () => ref.invalidate(childrenProvider)),
        data: (children) {
          if (children.isEmpty) {
            return _EmptyState(
              onAddChild: () => context.go('/parent/child/add'),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Who is practicing today?',
                style: OnboardingTypography.headline(
                  OnboardingColors.resolve(
                    Theme.of(context).brightness,
                  ).textPrimary,
                ),
              ),
              const SizedBox(height: OnboardingSpacing.sm),
              Text(
                'Choose a child profile to begin.',
                style: OnboardingTypography.body(
                  OnboardingColors.resolve(
                    Theme.of(context).brightness,
                  ).textSecondary,
                ),
              ),
              const SizedBox(height: OnboardingSpacing.lg),
              Expanded(
                child: ListView.separated(
                  itemCount: children.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: OnboardingSpacing.sm),
                  itemBuilder: (context, index) {
                    final child = children[index];
                    return _ChildTile(
                      name: child.name,
                      onTap: () async {
                        await ref
                            .read(selectedChildIdProvider.notifier)
                            .selectChild(child.id);
                        if (context.mounted) {
                          context.go('/child/home');
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: OnboardingSpacing.md),
              OnboardingButton(
                label: 'Add another child',
                variant: OnboardingButtonVariant.secondary,
                onPressed: () => context.push('/parent/child/add'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChildTile extends StatelessWidget {
  const _ChildTile({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = OnboardingColors.resolve(Theme.of(context).brightness);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(OnboardingRadii.md),
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(OnboardingRadii.md),
            border: Border.all(color: colors.border),
          ),
          padding: const EdgeInsets.all(OnboardingSpacing.md),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: OnboardingPalette.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(OnboardingRadii.sm),
                ),
                child: const Icon(
                  Icons.child_friendly_rounded,
                  color: OnboardingPalette.blue,
                ),
              ),
              const SizedBox(width: OnboardingSpacing.sm),
              Expanded(
                child: Text(
                  name,
                  style: OnboardingTypography.title(colors.textPrimary),
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddChild});

  final VoidCallback onAddChild;

  @override
  Widget build(BuildContext context) {
    final colors = OnboardingColors.resolve(Theme.of(context).brightness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        OnboardingSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No child profile yet',
                style: OnboardingTypography.title(colors.textPrimary),
              ),
              const SizedBox(height: OnboardingSpacing.sm),
              Text(
                'Add your first child profile to complete onboarding.',
                style: OnboardingTypography.body(colors.textSecondary),
              ),
            ],
          ),
        ),
        const Spacer(),
        OnboardingButton(label: 'Add child profile', onPressed: onAddChild),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = OnboardingColors.resolve(Theme.of(context).brightness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        OnboardingSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unable to load child profiles',
                style: OnboardingTypography.title(colors.textPrimary),
              ),
              const SizedBox(height: OnboardingSpacing.sm),
              Text(
                'Please check your connection and try again.',
                style: OnboardingTypography.body(colors.textSecondary),
              ),
            ],
          ),
        ),
        const Spacer(),
        OnboardingButton(label: 'Retry', onPressed: onRetry),
      ],
    );
  }
}
