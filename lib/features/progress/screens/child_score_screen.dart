import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/ui/app_app_bar.dart';
import '../../../core/ui/app_card.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/empty_state.dart';
import '../../../core/ui/primary_button.dart';
import '../../../core/ui/stat_tile.dart';
import '../../child/providers/child_providers.dart';
import '../providers/progress_providers.dart';

class ChildScoreScreen extends ConsumerWidget {
  const ChildScoreScreen({
    super.key,
    this.childId,
  });

  final String? childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedChild = ref.watch(selectedChildProvider);
    final resolvedChildId = childId ?? selectedChild?.id;

    if (resolvedChildId == null) {
      return AppScaffold(
        appBar: const AppAppBar(title: 'Score'),
        body: EmptyState(
          title: 'No child selected',
          message: 'Pick a child to see score trends.',
          buttonLabel: 'Select child',
          onPressed: () => context.go('/parent/child/select'),
        ),
      );
    }

    final scoreAsync = ref.watch(childScoreSummaryProvider(resolvedChildId));
    final basePath = childId == null ? '/child/progress' : '/parent/child/$resolvedChildId/progress';

    return AppScaffold(
      appBar: const AppAppBar(title: 'Score'),
      body: scoreAsync.when(
        data: (summary) {
          final recentScores = summary.entries.take(5).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Score overview', style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.lg),
              StatTile(
                title: 'Average score',
                value: '${summary.averageScore}%',
                variant: StatTileVariant.score,
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Latest score', style: AppTextStyles.caption),
                    const SizedBox(height: AppSpacing.xs),
                    Text('${summary.latestScore}%', style: AppTextStyles.title),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Recent attempts', style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.sm),
              if (recentScores.isEmpty)
                Text('No attempts logged yet.', style: AppTextStyles.body)
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: recentScores.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final entry = recentScores[index];
                      final dateLabel = MaterialLocalizations.of(context).formatShortDate(entry.createdAt);
                      return AppCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(dateLabel, style: AppTextStyles.body),
                            Text('${entry.score}%', style: AppTextStyles.title),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              if (recentScores.isNotEmpty) const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Back to progress',
                onPressed: () => context.go(basePath),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Unable to load scores', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            Text('Please try again.', style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }
}
