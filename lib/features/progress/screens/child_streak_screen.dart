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

class ChildStreakScreen extends ConsumerWidget {
  const ChildStreakScreen({
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
        appBar: const AppAppBar(title: 'Streak'),
        body: EmptyState(
          title: 'No child selected',
          message: 'Pick a child to see streak details.',
          buttonLabel: 'Select child',
          onPressed: () => context.go('/parent/child/select'),
        ),
      );
    }

    final streakAsync = ref.watch(childStreakProvider(resolvedChildId));
    final basePath = childId == null ? '/child/progress' : '/parent/child/$resolvedChildId/progress';

    return AppScaffold(
      appBar: const AppAppBar(title: 'Streak'),
      body: streakAsync.when(
        data: (streak) {
          final lastPractice = streak.lastPracticeDate == null
              ? 'No practice yet'
              : MaterialLocalizations.of(context).formatShortDate(streak.lastPracticeDate!);
          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Keep the streak going!', style: AppTextStyles.title),
                        const SizedBox(height: AppSpacing.lg),
                        StatTile(
                          title: 'Current streak',
                          value: '${streak.currentStreak} days',
                          variant: StatTileVariant.streak,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        StatTile(
                          title: 'Best streak',
                          value: '${streak.bestStreak} days',
                          variant: StatTileVariant.streak,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppCard(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Last practice', style: AppTextStyles.caption),
                              const SizedBox(height: AppSpacing.xs),
                              Text(lastPractice, style: AppTextStyles.body),
                            ],
                          ),
                        ),
                        const Spacer(),
                        PrimaryButton(
                          label: 'Back to progress',
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
            Text('Unable to load streak', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            Text('Please try again.', style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }
}
