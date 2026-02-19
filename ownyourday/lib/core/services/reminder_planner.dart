import 'package:ownyourday/features/tasks/domain/task.dart';
import 'package:ownyourday/features/tasks/domain/task_priority.dart';

class ReminderPlan {
  const ReminderPlan({required this.primaryAt, this.followUpAt});

  final DateTime primaryAt;
  final DateTime? followUpAt;
}

class ReminderPlanner {
  ReminderPlan buildPlan(TaskDraft draft, DateTime now, TaskPriority priority) {
    final explicitReminder = draft.remindAt;
    if (explicitReminder != null) {
      final primary = _clampToFuture(explicitReminder, now);
      return ReminderPlan(
        primaryAt: primary,
        followUpAt: primary.add(const Duration(minutes: 45)),
      );
    }

    final dueAt = draft.dueAt;
    if (dueAt != null) {
      final leadMinutes = switch (priority) {
        TaskPriority.high => 120,
        TaskPriority.medium => 75,
        TaskPriority.low => 45,
      };

      final primary = _clampToFuture(
        dueAt.subtract(Duration(minutes: leadMinutes)),
        now,
      );
      final followUp = _safeFollowUp(primary, dueAt, now);
      return ReminderPlan(primaryAt: primary, followUpAt: followUp);
    }

    final fallback = switch (priority) {
      TaskPriority.high => now.add(const Duration(minutes: 35)),
      TaskPriority.medium => now.add(const Duration(hours: 2)),
      TaskPriority.low => _tomorrowAt10(now),
    };

    return ReminderPlan(
      primaryAt: _clampToFuture(fallback, now),
      followUpAt: _clampToFuture(
        fallback.add(const Duration(minutes: 45)),
        now,
      ),
    );
  }

  DateTime _clampToFuture(DateTime date, DateTime now) {
    final min = now.add(const Duration(minutes: 10));
    return date.isBefore(min) ? min : date;
  }

  DateTime _tomorrowAt10(DateTime now) {
    final tomorrow = now.add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10);
  }

  DateTime? _safeFollowUp(DateTime primary, DateTime dueAt, DateTime now) {
    final candidate = primary.add(const Duration(minutes: 45));
    if (candidate.isAfter(dueAt.add(const Duration(minutes: 15)))) {
      return null;
    }
    if (candidate.isBefore(now.add(const Duration(minutes: 12)))) {
      return now.add(const Duration(minutes: 12));
    }
    return candidate;
  }
}
