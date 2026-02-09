import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/ui/app_app_bar.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/atlas_background.dart';
import '../../../core/ui/child_profile_card.dart';
import '../../../core/ui/primary_button.dart';
import '../../../core/ui/secondary_button.dart';
import '../../child/providers/child_providers.dart';
import '../../progress/providers/progress_providers.dart';

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenProvider);

    return AppScaffold(
      appBar: const AppAppBar(title: 'Parent Dashboard'),
      background: const AtlasBackground(seed: 81, intensity: 0.7, showGrid: false),
      body: childrenAsync.when(
        data: (children) {
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
                        Text('Child summaries', style: Theme.of(context).textTheme.displayLarge),
                        const SizedBox(height: AppSpacing.lg),
                        ...children
                            .asMap()
                            .entries
                            .map(
                              (entry) {
                                final child = entry.value;
                                final progressAsync =
                                    ref.watch(childProgressSummaryProvider(child.id));
                                final subtitle = progressAsync.when(
                                  data: (summary) =>
                                      '${summary.streak.currentStreak} day streak · ${summary.score.averageScore}% avg · ${summary.sessions.totalMinutes} min',
                                  loading: () => 'Loading progress...',
                                  error: (_, __) => 'Progress unavailable',
                                );
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: entry.key == children.length - 1 ? 0 : AppSpacing.md,
                                  ),
                                  child: ChildProfileCard(
                                    name: child.name,
                                    subtitle: subtitle,
                                    onTap: () => context.push('/parent/child/${child.id}/progress'),
                                  ),
                                );
                              },
                            ),
                        const Spacer(),
                        PrimaryButton(
                          label: 'Add child',
                          onPressed: () => context.push('/parent/child/add'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SecondaryButton(
                          label: 'Select child for practice',
                          onPressed: () => context.push('/parent/child/select'),
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
            Text('Unable to load dashboard', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Please try again.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.78),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
