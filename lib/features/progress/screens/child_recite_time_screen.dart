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

    return AppScaffold(
      appBar: const AppAppBar(title: 'Recite time'),
      background: const AtlasBackground(seed: 45),
      body: sessionsAsync.when(
        data: (summary) {
          final recentSessions = summary.entries.take(5).toList();
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
                        Text('Recitation time this week', style: Theme.of(context).textTheme.displayLarge),
                        const SizedBox(height: AppSpacing.lg),
                        StatTile(
                          title: 'Total time',
                          value: '${summary.totalMinutes} min',
                          variant: StatTileVariant.time,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppCard(
                          variant: AppCardVariant.soft,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Sessions', style: Theme.of(context).textTheme.labelMedium),
                              const SizedBox(height: AppSpacing.xs),
                              Text('${summary.sessionCount} sessions', style: Theme.of(context).textTheme.headlineSmall),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text('Recent sessions', style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: AppSpacing.sm),
                        if (recentSessions.isEmpty)
                          Text(
                            'No sessions logged yet.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurface.withValues(alpha: 0.78),
                                ),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var index = 0; index < recentSessions.length; index++) ...[
                                Builder(
                                  builder: (context) {
                                    final session = recentSessions[index];
                                    final duration = session.duration;
                                    final durationLabel = duration == null
                                        ? 'In progress'
                                        : '${duration.inMinutes} min';
                                    final dateLabel = MaterialLocalizations.of(context)
                                        .formatShortDate(session.startedAt);
                                    return AppCard(
                                      variant: AppCardVariant.soft,
                                      padding: const EdgeInsets.all(AppSpacing.md),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            dateLabel,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: scheme.onSurface.withValues(alpha: 0.78),
                                                ),
                                          ),
                                          Text(durationLabel, style: Theme.of(context).textTheme.headlineSmall),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                if (index != recentSessions.length - 1)
                                  const SizedBox(height: AppSpacing.sm),
                              ],
                            ],
                          ),
                        if (recentSessions.isNotEmpty) const SizedBox(height: AppSpacing.lg),
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
            Text('Unable to load recitation time', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text('Please try again.', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
