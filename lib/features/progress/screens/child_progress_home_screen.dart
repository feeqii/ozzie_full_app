import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/ui/app_app_bar.dart';
import '../../../core/ui/app_card.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/atlas_background.dart';
import '../../../core/ui/empty_state.dart';
import '../../../core/ui/primary_button.dart';
import '../../../core/ui/stat_tile.dart';
import '../../child/providers/child_providers.dart';
import '../providers/progress_providers.dart';

class ChildProgressHomeScreen extends ConsumerWidget {
  const ChildProgressHomeScreen({
    super.key,
    this.childId,
  });

  final String? childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedChild = ref.watch(selectedChildProvider);
    final resolvedChildId = childId ?? selectedChild?.id;
    final childrenAsync = ref.watch(childrenProvider);

    if (resolvedChildId == null) {
      return AppScaffold(
        appBar: const AppAppBar(title: 'Progress'),
        body: EmptyState(
          title: 'No child selected',
          message: 'Pick a child to see progress details.',
          buttonLabel: 'Select child',
          onPressed: () => context.go('/parent/child/select'),
        ),
      );
    }

    final summaryAsync = ref.watch(childProgressSummaryProvider(resolvedChildId));
    String? childName;
    if (childId == null) {
      childName = selectedChild?.name;
    } else {
      final children = childrenAsync.asData?.value;
      if (children != null) {
        for (final child in children) {
          if (child.id == resolvedChildId) {
            childName = child.name;
            break;
          }
        }
      }
    }

    final basePath = childId == null ? '/child/progress' : '/parent/child/$resolvedChildId/progress';

    return AppScaffold(
      appBar: const AppAppBar(title: 'Progress'),
      background: const AtlasBackground(seed: 41),
      body: summaryAsync.when(
        data: (summary) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final scheme = Theme.of(context).colorScheme;

              return SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          childName == null ? 'Your progress' : 'Progress for $childName',
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Track streaks, score, and recitation time.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.78),
                              ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        StatTile(
                          title: 'Streak',
                          value: '${summary.streak.currentStreak} days',
                          variant: StatTileVariant.streak,
                          onTap: () => context.push('$basePath/streak'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        StatTile(
                          title: 'Recite time',
                          value: '${summary.sessions.totalMinutes} min',
                          variant: StatTileVariant.time,
                          onTap: () => context.push('$basePath/time'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        StatTile(
                          title: 'Score',
                          value: '${summary.score.averageScore}%',
                          variant: StatTileVariant.score,
                          onTap: () => context.push('$basePath/score'),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppCard(
                          variant: AppCardVariant.soft,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Best streak', style: Theme.of(context).textTheme.labelMedium),
                              const SizedBox(height: AppSpacing.xs),
                              Text('${summary.streak.bestStreak} days', style: Theme.of(context).textTheme.headlineSmall),
                            ],
                          ),
                        ),
                        const Spacer(),
                        PrimaryButton(
                          label: 'Back',
                          onPressed: () => context.pop(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Unable to load progress', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text('Please try again.', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
