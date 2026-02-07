import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
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
      appBar: const AppAppBar(title: 'Learning Journey', showBack: false),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  child == null ? 'Welcome' : 'Welcome, ${child.name}',
                  style: AppTextStyles.title,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Explore the map and continue your journey.', style: AppTextStyles.body),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
          if (summaryAsync != null)
            SliverToBoxAdapter(
              child: summaryAsync.when(
                data: (summary) {
                  return AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Today', style: AppTextStyles.caption),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: _StatPill(
                                label: 'Streak',
                                value: '${summary.streak.currentStreak}d',
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _StatPill(
                                label: 'Score',
                                value: '${summary.score.averageScore}%',
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _StatPill(
                                label: 'Time',
                                value: '${summary.sessions.totalMinutes}m',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          SliverToBoxAdapter(
            child: mapAsync.when(
              data: (mapState) {
                final active = mapState?.galaxies
                    .expand((g) => g.surahs)
                    .where((s) => s.isActive)
                    .toList();
                active?.sort((a, b) => (a.activeSlot ?? 99).compareTo(b.activeSlot ?? 99));
                final next = active != null && active.isNotEmpty ? active.first : null;
                if (next == null) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Continue', style: AppTextStyles.caption),
                        const SizedBox(height: AppSpacing.sm),
                        Text(next.name, style: AppTextStyles.title),
                        const SizedBox(height: AppSpacing.md),
                        PrimaryButton(
                          label: 'Resume',
                          onPressed: () => context.push('/child/surah/${next.id}'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'Explore map',
                  onPressed: () => context.push('/child/map'),
                ),
                const SizedBox(height: AppSpacing.sm),
                PrimaryButton(
                  label: 'View progress',
                  onPressed: () => context.push('/child/progress'),
                ),
                const SizedBox(height: AppSpacing.sm),
                SecondaryButton(
                  label: 'Change child',
                  onPressed: () => context.go('/parent/child/select'),
                ),
                const SizedBox(height: AppSpacing.sm),
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
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.gamificationLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTextStyles.title),
        ],
      ),
    );
  }
}
