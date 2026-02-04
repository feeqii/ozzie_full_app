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

class ChildReciteTimeScreen extends ConsumerWidget {
  const ChildReciteTimeScreen({
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
        appBar: const AppAppBar(title: 'Recite time'),
        body: EmptyState(
          title: 'No child selected',
          message: 'Pick a child to see recitation time.',
          buttonLabel: 'Select child',
          onPressed: () => context.go('/parent/child/select'),
        ),
      );
    }

    final sessionsAsync = ref.watch(childSessionSummaryProvider(resolvedChildId));
    final basePath = childId == null ? '/child/progress' : '/parent/child/$resolvedChildId/progress';

    return AppScaffold(
      appBar: const AppAppBar(title: 'Recite time'),
      body: sessionsAsync.when(
        data: (summary) {
          final recentSessions = summary.entries.take(5).toList();
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
                        Text('Recitation time this week', style: AppTextStyles.title),
                        const SizedBox(height: AppSpacing.lg),
                        StatTile(
                          title: 'Total time',
                          value: '${summary.totalMinutes} min',
                          variant: StatTileVariant.time,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppCard(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Sessions', style: AppTextStyles.caption),
                              const SizedBox(height: AppSpacing.xs),
                              Text('${summary.sessionCount} sessions', style: AppTextStyles.title),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text('Recent sessions', style: AppTextStyles.title),
                        const SizedBox(height: AppSpacing.sm),
                        if (recentSessions.isEmpty)
                          Text('No sessions logged yet.', style: AppTextStyles.body)
                        else
                          ListView.separated(
                            itemCount: recentSessions.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final session = recentSessions[index];
                              final duration = session.duration;
                              final durationLabel = duration == null
                                  ? 'In progress'
                                  : '${duration.inMinutes} min';
                              final dateLabel =
                                  MaterialLocalizations.of(context).formatShortDate(session.startedAt);
                              return AppCard(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(dateLabel, style: AppTextStyles.body),
                                    Text(durationLabel, style: AppTextStyles.title),
                                  ],
                                ),
                              );
                            },
                          ),
                        if (recentSessions.isNotEmpty) const SizedBox(height: AppSpacing.lg),
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
            Text('Unable to load recitation time', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            Text('Please try again.', style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }
}
