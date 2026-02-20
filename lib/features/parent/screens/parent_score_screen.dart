import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../progress/models/child_progress_summary.dart';
import '../../progress/providers/progress_providers.dart';
import '../ui/parent_scaffold.dart';
import '../ui/parent_tokens.dart';
import '../ui/parent_widgets.dart';

class ParentScoreScreen extends ConsumerStatefulWidget {
  const ParentScoreScreen({super.key, required this.childId});

  final String childId;

  @override
  ConsumerState<ParentScoreScreen> createState() => _ParentScoreScreenState();
}

class _ParentScoreScreenState extends ConsumerState<ParentScoreScreen> {
  int? _selectedSurahId;

  @override
  Widget build(BuildContext context) {
    final scoreAsync = ref.watch(childScoreSummaryProvider(widget.childId));
    final sessionAsync = ref.watch(childSessionSummaryProvider(widget.childId));
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return ParentScaffold(
      child: scoreAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ScoreError(colors: colors),
        data: (scoreSummary) {
          final entries = scoreSummary.entries;
          final totalAyahs = entries
              .where((entry) => entry.ayahId != null)
              .length;
          final totalErrors = entries.fold<int>(
            0,
            (sum, entry) =>
                sum + ((100 - entry.score).clamp(0, 100) / 25).round(),
          );

          final surahIds =
              entries
                  .map((entry) => entry.surahId)
                  .whereType<int>()
                  .toSet()
                  .toList()
                ..sort();
          if (_selectedSurahId == null && surahIds.isNotEmpty) {
            _selectedSurahId = surahIds.first;
          }

          final selectedEntries = _selectedSurahId == null
              ? entries
              : entries
                    .where((entry) => entry.surahId == _selectedSurahId)
                    .toList();

          final doneAyahs = selectedEntries
              .map((entry) => entry.ayahId)
              .whereType<int>()
              .toSet()
              .length;
          final avgScore = selectedEntries.isEmpty
              ? 0
              : (selectedEntries.fold<int>(
                          0,
                          (sum, entry) => sum + entry.score,
                        ) /
                        selectedEntries.length)
                    .round();
          final estimatedErrors = (100 - avgScore).clamp(0, 100);

          final daily = _dailyAverages(entries);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ParentHeaderBar(title: 'Score', onBack: () => context.pop()),
              const SizedBox(height: ParentSpacing.lg),
              ParentPanel(
                child: Row(
                  children: [
                    Expanded(
                      child: _TopMetric(
                        title: 'Total Ayahs',
                        value: '$totalAyahs',
                      ),
                    ),
                    Container(width: 1, height: 72, color: colors.border),
                    Expanded(
                      child: _TopMetric(
                        title: 'Total Errors',
                        value: '$totalErrors',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ParentSpacing.lg),
              Text('Daily score', style: ParentText.title(colors.textPrimary)),
              const SizedBox(height: ParentSpacing.sm),
              _ScoreBarChart(dailyAverages: daily),
              const SizedBox(height: ParentSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Activity Log',
                      style: ParentText.title(colors.textPrimary),
                    ),
                  ),
                  if (surahIds.isNotEmpty)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(ParentRadius.sm),
                        border: Border.all(color: colors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ParentSpacing.sm,
                        ),
                        child: DropdownButton<int>(
                          value: _selectedSurahId,
                          underline: const SizedBox.shrink(),
                          items: [
                            for (final surahId in surahIds)
                              DropdownMenuItem(
                                value: surahId,
                                child: Text(
                                  'SURAH $surahId',
                                  style: ParentText.micro(colors.textPrimary),
                                ),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _selectedSurahId = value),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: ParentSpacing.sm),
              ParentPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _selectedSurahId == null
                          ? 'ALL SURAHS'
                          : 'SURAH ${_selectedSurahId!}',
                      textAlign: TextAlign.center,
                      style: ParentText.heading(colors.textPrimary),
                    ),
                    const SizedBox(height: ParentSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniMetric(
                            title: 'Ayahs',
                            primary: '$doneAyahs Done',
                            secondary: '-- Left',
                          ),
                        ),
                        const SizedBox(width: ParentSpacing.xs),
                        Expanded(
                          child: _MiniMetric(
                            title: 'Sessions',
                            primary: '${selectedEntries.length}',
                            secondary: _recentDateLabel(selectedEntries),
                          ),
                        ),
                        const SizedBox(width: ParentSpacing.xs),
                        Expanded(
                          child: sessionAsync.when(
                            loading: () => const _MiniMetric(
                              title: 'Duration',
                              primary: '--',
                              secondary: '...',
                            ),
                            error: (_, __) => const _MiniMetric(
                              title: 'Duration',
                              primary: '--',
                              secondary: '--',
                            ),
                            data: (sessions) {
                              final duration = sessions.sessionCount == 0
                                  ? 0
                                  : (sessions.totalMinutes /
                                            sessions.sessionCount)
                                        .round();
                              // TODO(parent-score): replace with surah-specific duration when per-surah timing is available.
                              return _MiniMetric(
                                title: 'Duration',
                                primary: '${duration}m',
                                secondary: 'Avg',
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: ParentSpacing.xs),
                        Expanded(
                          child: _MiniMetric(
                            title: 'Score',
                            primary: '$avgScore%',
                            secondary: 'Avg',
                          ),
                        ),
                        const SizedBox(width: ParentSpacing.xs),
                        Expanded(
                          child: _MiniMetric(
                            title: 'Errors',
                            primary: '$estimatedErrors',
                            secondary: 'Est.',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Map<int, int> _dailyAverages(List<ScoreEntry> entries) {
    final buckets = <int, List<int>>{
      for (var day = 1; day <= 7; day++) day: <int>[],
    };

    for (final entry in entries) {
      buckets[entry.createdAt.weekday]?.add(entry.score);
    }

    return {
      for (var day = 1; day <= 7; day++)
        day: buckets[day]!.isEmpty
            ? 0
            : (buckets[day]!.fold<int>(0, (sum, score) => sum + score) /
                      buckets[day]!.length)
                  .round(),
    };
  }

  String _recentDateLabel(List<ScoreEntry> entries) {
    if (entries.isEmpty) {
      return '--';
    }
    return MaterialLocalizations.of(
      context,
    ).formatShortDate(entries.first.createdAt);
  }
}

class _TopMetric extends StatelessWidget {
  const _TopMetric({required this.title, required this.value});

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

class _ScoreBarChart extends StatelessWidget {
  const _ScoreBarChart({required this.dailyAverages});

  final Map<int, int> dailyAverages;

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);
    final labels = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SizedBox(
      height: 186,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${dailyAverages[i + 1] ?? 0}%',
                    style: ParentText.micro(colors.textSecondary),
                  ),
                  const SizedBox(height: ParentSpacing.xs),
                  Container(
                    width: 32,
                    height: math.max(
                      2,
                      (dailyAverages[i + 1] ?? 0).toDouble() * 1.2,
                    ),
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
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.title,
    required this.primary,
    required this.secondary,
  });

  final String title;
  final String primary;
  final String secondary;

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return ParentPanel(
      padding: const EdgeInsets.all(ParentSpacing.sm),
      child: Column(
        children: [
          Text(title, style: ParentText.micro(colors.textSecondary)),
          const SizedBox(height: ParentSpacing.xs),
          Text(
            primary,
            textAlign: TextAlign.center,
            style: ParentText.label(colors.textPrimary),
          ),
          const SizedBox(height: ParentSpacing.xs),
          Text(
            secondary,
            textAlign: TextAlign.center,
            style: ParentText.micro(colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ScoreError extends StatelessWidget {
  const _ScoreError({required this.colors});

  final ParentColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ParentHeaderBar(title: 'Score', onBack: () => context.pop()),
        const SizedBox(height: ParentSpacing.xl),
        ParentPanel(
          child: Text(
            'Unable to load score details right now.',
            style: ParentText.body(colors.textSecondary),
          ),
        ),
      ],
    );
  }
}
