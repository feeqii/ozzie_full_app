import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/ui/app_app_bar.dart';
import '../../../core/ui/app_scaffold.dart';
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
      body: childrenAsync.when(
        data: (children) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Child summaries', style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: ListView.separated(
                  itemCount: children.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final child = children[index];
                    final progressAsync = ref.watch(childProgressSummaryProvider(child.id));
                    final subtitle = progressAsync.when(
                      data: (summary) =>
                          '${summary.streak.currentStreak} day streak · ${summary.score.averageScore}% avg · ${summary.sessions.totalMinutes} min',
                      loading: () => 'Loading progress...',
                      error: (_, __) => 'Progress unavailable',
                    );
                    return ChildProfileCard(
                      name: child.name,
                      subtitle: subtitle,
                      onTap: () => context.go('/parent/child/${child.id}/progress'),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Add child',
                onPressed: () => context.go('/parent/child/add'),
              ),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: 'Select child for practice',
                onPressed: () => context.go('/parent/child/select'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Unable to load dashboard', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            Text('Please try again.', style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }
}
