import 'dart:convert';

import 'package:ownyourday/features/tasks/domain/task_priority.dart';
import 'package:ownyourday/features/tasks/domain/task_source.dart';
import 'package:ownyourday/features/tasks/domain/task_status.dart';

class Task {
  Task({
    required this.id,
    required this.title,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.priority,
    required this.importance,
    required this.estimatedMinutes,
    required this.source,
    this.dueAt,
    this.remindAt,
    this.status = TaskStatus.todo,
    this.notificationId,
  });

  final String id;
  final String title;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? dueAt;
  final DateTime? remindAt;
  final TaskPriority priority;
  final int importance;
  final int estimatedMinutes;
  final TaskSource source;
  final TaskStatus status;
  final int? notificationId;

  bool get isDone => status == TaskStatus.done;

  bool get isOverdue {
    if (dueAt == null || isDone) {
      return false;
    }
    return DateTime.now().isAfter(dueAt!);
  }

  Task copyWith({
    String? id,
    String? title,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dueAt,
    bool clearDueAt = false,
    DateTime? remindAt,
    bool clearRemindAt = false,
    TaskPriority? priority,
    int? importance,
    int? estimatedMinutes,
    TaskSource? source,
    TaskStatus? status,
    int? notificationId,
    bool clearNotificationId = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueAt: clearDueAt ? null : (dueAt ?? this.dueAt),
      remindAt: clearRemindAt ? null : (remindAt ?? this.remindAt),
      priority: priority ?? this.priority,
      importance: importance ?? this.importance,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      source: source ?? this.source,
      status: status ?? this.status,
      notificationId: clearNotificationId
          ? null
          : (notificationId ?? this.notificationId),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'dueAt': dueAt?.toIso8601String(),
      'remindAt': remindAt?.toIso8601String(),
      'priority': priority.name,
      'importance': importance,
      'estimatedMinutes': estimatedMinutes,
      'source': source.name,
      'status': status.name,
      'notificationId': notificationId,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      notes: map['notes'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      dueAt: map['dueAt'] == null
          ? null
          : DateTime.parse(map['dueAt'] as String),
      remindAt: map['remindAt'] == null
          ? null
          : DateTime.parse(map['remindAt'] as String),
      priority: TaskPriority.values.firstWhere(
        (value) => value.name == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      importance: map['importance'] as int? ?? 3,
      estimatedMinutes: map['estimatedMinutes'] as int? ?? 30,
      source: TaskSource.values.firstWhere(
        (value) => value.name == map['source'],
        orElse: () => TaskSource.manual,
      ),
      status: TaskStatus.values.firstWhere(
        (value) => value.name == map['status'],
        orElse: () => TaskStatus.todo,
      ),
      notificationId: map['notificationId'] as int?,
    );
  }

  String toJson() => json.encode(toMap());

  factory Task.fromJson(String source) =>
      Task.fromMap(json.decode(source) as Map<String, dynamic>);
}

class TaskDraft {
  TaskDraft({
    required this.title,
    this.notes = '',
    this.dueAt,
    this.remindAt,
    this.priority,
    this.importance = 3,
    this.estimatedMinutes = 30,
    this.source = TaskSource.manual,
  });

  final String title;
  final String notes;
  final DateTime? dueAt;
  final DateTime? remindAt;
  final TaskPriority? priority;
  final int importance;
  final int estimatedMinutes;
  final TaskSource source;
}
