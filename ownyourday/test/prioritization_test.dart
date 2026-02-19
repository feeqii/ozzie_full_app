import 'package:flutter_test/flutter_test.dart';
import 'package:ownyourday/core/services/prioritization_service.dart';
import 'package:ownyourday/features/tasks/domain/task.dart';
import 'package:ownyourday/features/tasks/domain/task_priority.dart';

void main() {
  test('high importance and near deadline maps to high priority', () {
    final service = PrioritizationService();
    final now = DateTime(2026, 2, 19, 10);

    final priority = service.inferPriority(
      TaskDraft(
        title: 'Ship testflight build',
        dueAt: now.add(const Duration(hours: 4)),
        importance: 5,
        estimatedMinutes: 20,
      ),
      now,
    );

    expect(priority, TaskPriority.high);
  });

  test('lower importance with no due date maps to low/medium', () {
    final service = PrioritizationService();
    final now = DateTime(2026, 2, 19, 10);

    final priority = service.inferPriority(
      TaskDraft(title: 'Organize desk', importance: 1, estimatedMinutes: 40),
      now,
    );

    expect(<TaskPriority>[
      TaskPriority.low,
      TaskPriority.medium,
    ], contains(priority));
  });
}
