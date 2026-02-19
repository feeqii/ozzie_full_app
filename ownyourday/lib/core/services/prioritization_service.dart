import 'package:ownyourday/features/tasks/domain/task.dart';
import 'package:ownyourday/features/tasks/domain/task_priority.dart';

class PrioritizationService {
  TaskPriority inferPriority(TaskDraft draft, DateTime now) {
    final dueAt = draft.dueAt;
    var score = draft.importance * 1.4;

    if (dueAt != null) {
      final hours = dueAt.difference(now).inHours;
      if (hours <= 6) {
        score += 4.2;
      } else if (hours <= 24) {
        score += 3.2;
      } else if (hours <= 72) {
        score += 2.2;
      } else {
        score += 1.0;
      }
    } else {
      score += 1.2;
    }

    if (draft.estimatedMinutes <= 20) {
      score += 0.9;
    }

    if (score >= 8.2) {
      return TaskPriority.high;
    }
    if (score >= 5.5) {
      return TaskPriority.medium;
    }
    return TaskPriority.low;
  }
}
