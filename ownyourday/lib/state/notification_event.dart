import 'dart:convert';

class NotificationEvent {
  NotificationEvent({
    required this.id,
    required this.taskId,
    required this.kind,
    required this.createdAt,
    this.scheduledFor,
    this.details,
  });

  final String id;
  final String taskId;
  final String kind;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final String? details;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'taskId': taskId,
      'kind': kind,
      'createdAt': createdAt.toIso8601String(),
      'scheduledFor': scheduledFor?.toIso8601String(),
      'details': details,
    };
  }

  factory NotificationEvent.fromMap(Map<String, dynamic> map) {
    return NotificationEvent(
      id: map['id'] as String,
      taskId: map['taskId'] as String,
      kind: map['kind'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      scheduledFor: map['scheduledFor'] == null
          ? null
          : DateTime.parse(map['scheduledFor'] as String),
      details: map['details'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory NotificationEvent.fromJson(String source) =>
      NotificationEvent.fromMap(json.decode(source) as Map<String, dynamic>);
}
