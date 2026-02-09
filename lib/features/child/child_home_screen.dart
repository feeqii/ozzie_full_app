import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/ui/app_app_bar.dart';
import '../../core/ui/app_card.dart';
import '../../core/ui/app_scaffold.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/secondary_button.dart';
import '../auth/controllers/auth_controller.dart';
import '../child/providers/child_providers.dart';
import '../map/providers/map_providers.dart';
import '../progress/providers/progress_providers.dart';

class ChildHomeScreen extends ConsumerWidget {
  const ChildHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider);
    final mapAsync = ref.watch(mapStateProvider);
    final summaryAsync = child == null ? null : ref.watch(childProgressSummaryProvider(child.id));

    return AppScaffold(
      appBar: const AppAppBar(title: 'Mission Control', showBack: false),
      body: ListView(
        children: [
          Text(
            child == null ? 'Welcome' : 'Welcome, ${child.name}',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Pick up where you left off or explore the universe.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (summaryAsync != null)
            summaryAsync.when(
              data: (summary) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Today', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _StampChip(
                            icon: Icons.local_fire_department_outlined,
                            label: 'Streak',
                            value: '${summary.streak.currentStreak}d',
                            onTap: () => context.push('/child/progress/streak'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _StampChip(
                            icon: Icons.score_outlined,
                            label: 'Score',
                            value: '${summary.score.averageScore}%',
                            onTap: () => context.push('/child/progress/score'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _StampChip(
                            icon: Icons.timer_outlined,
                            label: 'Time',
                            value: '${summary.sessions.totalMinutes}m',
                            onTap: () => context.push('/child/progress/time'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const SizedBox(height: 82),
              error: (_, __) => const SizedBox.shrink(),
            ),
          const SizedBox(height: AppSpacing.lg),
          mapAsync.when(
            data: (mapState) {
              final active = mapState?.galaxies.expand((g) => g.surahs).where((s) => s.isActive).toList();
              active?.sort((a, b) => (a.activeSlot ?? 99).compareTo(b.activeSlot ?? 99));
              final next = active != null && active.isNotEmpty ? active.first : null;
              if (next == null) {
                return AppCard(
                  variant: AppCardVariant.soft,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your next mission', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Head to the map to start a new surah.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }

              return AppCard(
                variant: AppCardVariant.elevated,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Resume', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(next.name, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.sm),
                    Text(next.translation, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: AppSpacing.md),
                    PrimaryButton(
                      label: 'Continue mission',
                      onPressed: () => context.push('/child/surah/${next.id}'),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Explore the map',
            onPressed: () => context.push('/child/map'),
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: 'View all progress',
            onPressed: () => context.push('/child/progress'),
          ),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            label: 'Change child',
            onPressed: () => context.go('/parent/child/select'),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Log out',
            variant: PrimaryButtonVariant.danger,
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              await ref.read(selectedChildIdProvider.notifier).clear();
              if (context.mounted) {
                context.go('/auth/entry');
              }
            },
          ),
        ],
      ),
    );
  }
}

class _StampChip extends StatelessWidget {
  const _StampChip({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      variant: AppCardVariant.soft,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onSurface),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(value, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
