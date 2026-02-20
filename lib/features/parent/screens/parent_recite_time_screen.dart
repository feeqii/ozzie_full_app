import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../progress/models/child_progress_summary.dart';
import '../../progress/providers/progress_providers.dart';
import '../ui/parent_scaffold.dart';
import '../ui/parent_tokens.dart';
import '../ui/parent_widgets.dart';

class ParentReciteTimeScreen extends ConsumerWidget {
  const ParentReciteTimeScreen({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(childSessionSummaryProvider(childId));
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return ParentScaffold(
      child: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ReciteError(colors: colors),
        data: (summary) {
          final totalHours = summary.totalMinutes ~/ 60;
          final totalMinutes = summary.totalMinutes % 60;
          final bars = _dailyMinutes(summary);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ParentHeaderBar(
                title: 'Recite Time',
                onBack: () => context.pop(),
              ),
              const SizedBox(height: ParentSpacing.lg),
              ParentPanel(
                child: Row(
                  children: [
                    Expanded(
                      child: _TopBox(
                        title: 'Total Time',
                        value: '${totalHours}h ${totalMinutes}m',
                      ),
                    ),
                    Container(width: 1, height: 72, color: colors.border),
                    Expanded(
                      child: _TopBox(
                        title: 'Sessions',
                        value: '${summary.sessionCount}',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ParentSpacing.xl),
              Text('Daily Time', style: ParentText.title(colors.textPrimary)),
              const SizedBox(height: ParentSpacing.sm),
              Expanded(child: _TimeBarChart(bars: bars)),
            ],
          );
        },
      ),
    );
  }

  Map<int, int> _dailyMinutes(SessionSummary summary) {
    final buckets = <int, int>{for (var day = 1; day <= 7; day++) day: 0};

    for (final entry in summary.entries) {
      final duration = entry.duration;
      if (duration == null) {
        continue;
      }
      final minutes = (duration.inSeconds / 60).round();
      buckets[entry.startedAt.weekday] =
          (buckets[entry.startedAt.weekday] ?? 0) + minutes;
    }

    return buckets;
  }
}

class _TopBox extends StatelessWidget {
  const _TopBox({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return Column(
      children: [
        Text(
          title.toUpperCase(),
          style: ParentText.label(colors.textSecondary),
        ),
        const SizedBox(height: ParentSpacing.sm),
        ParentPanel(
          child: Center(
            child: Text(value, style: ParentText.title(colors.textPrimary)),
          ),
        ),
      ],
    );
  }
}

class _TimeBarChart extends StatelessWidget {
  const _TimeBarChart({required this.bars});

  final Map<int, int> bars;

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);
    final labels = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxValue = bars.values.fold<int>(0, math.max);
    final scale = maxValue == 0 ? 1.0 : 100.0 / maxValue;

    return ParentPanel(
      child: Column(
        children: [
          for (final mark in [25, 20, 15, 10, 5, 0])
            Padding(
              padding: const EdgeInsets.only(bottom: ParentSpacing.sm),
              child: Row(
                children: [
                  SizedBox(
                    width: 34,
                    child: Text(
                      '${mark}m',
                      style: ParentText.micro(colors.textSecondary),
                    ),
                  ),
                  Expanded(child: Divider(color: colors.border, height: 1)),
                ],
              ),
            ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${bars[i + 1] ?? 0}m',
                        style: ParentText.micro(colors.textSecondary),
                      ),
                      const SizedBox(height: ParentSpacing.xs),
                      Container(
                        width: 32,
                        height: math.max(2, (bars[i + 1] ?? 0) * scale),
                        decoration: BoxDecoration(
                          color: colors.chartBar,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: ParentSpacing.xs),
                      Text(
                        labels[i],
                        style: ParentText.label(colors.textSecondary),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReciteError extends StatelessWidget {
  const _ReciteError({required this.colors});

  final ParentColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ParentHeaderBar(title: 'Recite Time', onBack: () => context.pop()),
        const SizedBox(height: ParentSpacing.xl),
        ParentPanel(
          child: Text(
            'Unable to load recitation time right now.',
            style: ParentText.body(colors.textSecondary),
          ),
        ),
      ],
    );
  }
}
