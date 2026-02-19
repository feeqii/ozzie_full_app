import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ownyourday/core/theme/app_colors.dart';

class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.selectedDate,
    required this.onSelect,
    this.weekStartsOnMonday = false,
  });

  final DateTime selectedDate;
  final bool weekStartsOnMonday;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final start = _startOfWeek(selectedDate, weekStartsOnMonday);
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List<Widget>.generate(7, (index) {
        final date = start.add(Duration(days: index));
        final isSelected = _sameDay(date, selectedDate);
        final isToday = _sameDay(date, DateTime.now());

        return GestureDetector(
          onTap: () => onSelect(date),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            width: 42,
            height: 74,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: isSelected
                  ? AppColors.lavender
                  : (isToday
                        ? AppColors.lavender.withValues(alpha: 0.18)
                        : Colors.transparent),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  DateFormat('E').format(date).substring(0, 1),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isSelected ? Colors.white : null,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  date.day.toString(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isSelected ? Colors.white : null,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  DateTime _startOfWeek(DateTime date, bool mondayFirst) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final weekday = dateOnly.weekday;
    final shift = mondayFirst ? weekday - DateTime.monday : weekday % 7;
    return dateOnly.subtract(Duration(days: shift));
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
