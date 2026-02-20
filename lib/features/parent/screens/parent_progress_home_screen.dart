import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../child/providers/child_providers.dart';
import '../../progress/providers/progress_providers.dart';
import '../utils/parent_child_lookup.dart';
import '../ui/parent_scaffold.dart';
import '../ui/parent_tokens.dart';
import '../ui/parent_widgets.dart';

class ParentProgressHomeScreen extends ConsumerWidget {
  const ParentProgressHomeScreen({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenProvider);

    return ParentScaffold(
      child: childrenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _ProgressMissingState(),
        data: (children) {
          final child = findChildById(children, childId);
          if (child == null) {
            return const _ProgressMissingState();
          }

          final summaryAsync = ref.watch(childProgressSummaryProvider(childId));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ParentHeaderBar(
                title: 'Child Progress',
                onBack: () => context.pop(),
              ),
              const SizedBox(height: ParentSpacing.lg),
              ParentPanel(
                child: Text(
                  child.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: ParentText.title(
                    ParentColors.resolve(
                      Theme.of(context).brightness,
                    ).textPrimary,
                  ).copyWith(fontSize: 26),
                ),
              ),
              const SizedBox(height: ParentSpacing.md),
              summaryAsync.when(
                loading: () => const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => Expanded(
                  child: Center(
                    child: Text(
                      'Unable to load progress details.',
                      style: ParentText.body(
                        ParentColors.resolve(
                          Theme.of(context).brightness,
                        ).textSecondary,
                      ),
                    ),
                  ),
                ),
                data: (summary) {
                  return Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryBox(
                                title: 'Current Streak',
                                value: '${summary.streak.currentStreak} days',
                              ),
                            ),
                            const SizedBox(width: ParentSpacing.sm),
                            Expanded(
                              child: _SummaryBox(
                                title: 'Average Score',
                                value: '${summary.score.averageScore}%',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: ParentSpacing.sm),
                        _SummaryBox(
                          title: 'Recite Time',
                          value: '${summary.sessions.totalMinutes} min',
                        ),
                        const SizedBox(height: ParentSpacing.lg),
                        ParentActionTile(
                          label: 'Streak',
                          icon: Icons.local_fire_department_outlined,
                          onTap: () => context.push(
                            '/parent/child/$childId/progress/streak',
                          ),
                        ),
                        const SizedBox(height: ParentSpacing.sm),
                        ParentActionTile(
                          label: 'Recite Time',
                          icon: Icons.timer_outlined,
                          onTap: () => context.push(
                            '/parent/child/$childId/progress/time',
                          ),
                        ),
                        const SizedBox(height: ParentSpacing.sm),
                        ParentActionTile(
                          label: 'Score',
                          icon: Icons.insights_outlined,
                          onTap: () => context.push(
                            '/parent/child/$childId/progress/score',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return ParentPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: ParentText.micro(colors.textSecondary),
          ),
          const SizedBox(height: ParentSpacing.xs),
          Text(value, style: ParentText.title(colors.textPrimary)),
        ],
      ),
    );
  }
}

class _ProgressMissingState extends StatelessWidget {
  const _ProgressMissingState();

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ParentHeaderBar(
          title: 'Child Progress',
          onBack: () => context.go('/parent/dashboard'),
        ),
        const SizedBox(height: ParentSpacing.xl),
        ParentPanel(
          child: Text(
            'Child profile could not be loaded.',
            style: ParentText.body(colors.textSecondary),
          ),
        ),
      ],
    );
  }
}
