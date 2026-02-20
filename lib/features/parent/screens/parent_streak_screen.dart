import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../progress/providers/progress_providers.dart';
import '../ui/parent_scaffold.dart';
import '../ui/parent_tokens.dart';
import '../ui/parent_widgets.dart';

class ParentStreakScreen extends ConsumerStatefulWidget {
  const ParentStreakScreen({super.key, required this.childId});

  final String childId;

  @override
  ConsumerState<ParentStreakScreen> createState() => _ParentStreakScreenState();
}

class _ParentStreakScreenState extends ConsumerState<ParentStreakScreen> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final streakAsync = ref.watch(childStreakProvider(widget.childId));
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return ParentScaffold(
      child: streakAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _StreakError(colors: colors),
        data: (streak) {
          final anchor = streak.lastPracticeDate ?? DateTime.now();
          final activeDays = <DateTime>{
            for (var i = 0; i < streak.currentStreak; i++)
              DateTime(anchor.year, anchor.month, anchor.day - i),
          };

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ParentHeaderBar(title: 'Streak', onBack: () => context.pop()),
              const SizedBox(height: ParentSpacing.xl),
              Center(
                child: Container(
                  width: 164,
                  height: 164,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surface,
                    border: Border.all(color: colors.border, width: 1.1),
                  ),
                  child: Icon(
                    Icons.local_fire_department_outlined,
                    size: 88,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: ParentSpacing.md),
              Text(
                '${streak.currentStreak}',
                textAlign: TextAlign.center,
                style: ParentText.number(colors.textPrimary),
              ),
              Text(
                'DAYS',
                textAlign: TextAlign.center,
                style: ParentText.heading(colors.textPrimary),
              ),
              const SizedBox(height: ParentSpacing.xl),
              ParentSectionTitle('Calendar'),
              const SizedBox(height: ParentSpacing.md),
              _MonthSelector(
                month: _visibleMonth,
                onPrevious: () {
                  setState(() {
                    _visibleMonth = DateTime(
                      _visibleMonth.year,
                      _visibleMonth.month - 1,
                    );
                  });
                },
                onNext: () {
                  setState(() {
                    _visibleMonth = DateTime(
                      _visibleMonth.year,
                      _visibleMonth.month + 1,
                    );
                  });
                },
              ),
              const SizedBox(height: ParentSpacing.sm),
              Expanded(
                child: _CalendarGrid(
                  visibleMonth: _visibleMonth,
                  activeDays: activeDays,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);
    final label = MaterialLocalizations.of(context).formatMonthYear(month);

    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: Icon(Icons.chevron_left_rounded, color: colors.textSecondary),
        ),
        Expanded(
          child: Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: ParentText.title(colors.textPrimary),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({required this.visibleMonth, required this.activeDays});

  final DateTime visibleMonth;
  final Set<DateTime> activeDays;

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final startOffset = (firstDay.weekday + 6) % 7;
    final startDate = firstDay.subtract(Duration(days: startOffset));

    final cells = [
      for (var i = 0; i < 42; i++)
        DateTime(startDate.year, startDate.month, startDate.day + i),
    ];

    return ParentPanel(
      child: Column(
        children: [
          Row(
            children: const [
              _WeekLabel('MON'),
              _WeekLabel('TUE'),
              _WeekLabel('WED'),
              _WeekLabel('THU'),
              _WeekLabel('FRI'),
              _WeekLabel('SAT'),
              _WeekLabel('SUN'),
            ],
          ),
          const SizedBox(height: ParentSpacing.sm),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: ParentSpacing.sm,
                crossAxisSpacing: ParentSpacing.sm,
              ),
              itemCount: cells.length,
              itemBuilder: (context, index) {
                final day = cells[index];
                final inMonth = day.month == visibleMonth.month;
                final isActive = activeDays.contains(day);
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? colors.textPrimary.withValues(alpha: 0.16)
                        : colors.surfaceMuted,
                    border: Border.all(
                      color: isActive ? colors.textPrimary : colors.border,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: isActive
                        ? Icon(
                            Icons.local_fire_department,
                            size: 14,
                            color: colors.textPrimary,
                          )
                        : Text(
                            '${day.day}',
                            style: ParentText.micro(
                              inMonth ? colors.textSecondary : colors.border,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekLabel extends StatelessWidget {
  const _WeekLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: ParentText.micro(colors.textSecondary),
      ),
    );
  }
}

class _StreakError extends StatelessWidget {
  const _StreakError({required this.colors});

  final ParentColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ParentHeaderBar(title: 'Streak', onBack: () => context.pop()),
        const SizedBox(height: ParentSpacing.xl),
        ParentPanel(
          child: Text(
            'Unable to load streak right now.',
            style: ParentText.body(colors.textSecondary),
          ),
        ),
      ],
    );
  }
}
