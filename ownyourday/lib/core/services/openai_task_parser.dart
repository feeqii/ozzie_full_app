import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ownyourday/core/constants/app_constants.dart';
import 'package:ownyourday/features/tasks/domain/task.dart';
import 'package:ownyourday/features/tasks/domain/task_priority.dart';

class AiTaskSuggestion {
  AiTaskSuggestion({
    required this.title,
    required this.notes,
    required this.importance,
    required this.estimatedMinutes,
    required this.priority,
    this.dueAt,
    this.remindAt,
  });

  final String title;
  final String notes;
  final DateTime? dueAt;
  final DateTime? remindAt;
  final int importance;
  final int estimatedMinutes;
  final TaskPriority priority;

  TaskDraft toDraft() {
    return TaskDraft(
      title: title,
      notes: notes,
      dueAt: dueAt,
      remindAt: remindAt,
      priority: priority,
      importance: importance,
      estimatedMinutes: estimatedMinutes,
    );
  }
}

class OpenAiTaskParser {
  OpenAiTaskParser({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<AiTaskSuggestion?> parse({
    required String apiKey,
    required String rawText,
    required DateTime now,
  }) async {
    if (apiKey.trim().isEmpty || rawText.trim().isEmpty) {
      return null;
    }

    try {
      final response = await _client.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode(<String, dynamic>{
          'model': AppConstants.openAiModel,
          'temperature': 0.2,
          'response_format': <String, String>{'type': 'json_object'},
          'messages': <Map<String, String>>[
            <String, String>{
              'role': 'system',
              'content':
                  'You convert raw text into one actionable productivity task. '
                  'Return only strict JSON with keys: title, notes, dueAtISO, remindAtISO, '
                  'importance (1-5), estimatedMinutes, priority (high|medium|low). '
                  'If unknown dates, use null. Keep title under 48 chars. '
                  'Infer gentle reminder timing. Use user locale assumptions.',
            },
            <String, String>{
              'role': 'user',
              'content':
                  'Current timestamp: ${now.toIso8601String()}\nInput: "$rawText"\nReturn JSON only.',
            },
          ],
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _fallback(rawText: rawText);
      }

      final decoded = json.decode(response.body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        return _fallback(rawText: rawText);
      }

      final content =
          (choices.first as Map<String, dynamic>)['message']
              as Map<String, dynamic>?;
      final payload = content?['content'] as String?;
      if (payload == null || payload.isEmpty) {
        return _fallback(rawText: rawText);
      }

      final map = json.decode(payload) as Map<String, dynamic>;
      return AiTaskSuggestion(
        title: (map['title'] as String? ?? rawText).trim(),
        notes: (map['notes'] as String? ?? '').trim(),
        dueAt: _parseDate(map['dueAtISO']),
        remindAt: _parseDate(map['remindAtISO']),
        importance: _clampInt(
          map['importance'] as num?,
          min: 1,
          max: 5,
          fallback: 3,
        ),
        estimatedMinutes: _clampInt(
          map['estimatedMinutes'] as num?,
          min: 5,
          max: 480,
          fallback: 30,
        ),
        priority: _parsePriority(map['priority'] as String?),
      );
    } catch (_) {
      return _fallback(rawText: rawText);
    }
  }

  AiTaskSuggestion _fallback({required String rawText}) {
    final normalized = rawText.trim();
    final title = normalized.length > 60
        ? '${normalized.substring(0, 57)}...'
        : normalized;
    return AiTaskSuggestion(
      title: title,
      notes: 'AI parsing fallback used. Refine task details manually.',
      dueAt: null,
      remindAt: null,
      importance: 3,
      estimatedMinutes: 30,
      priority: TaskPriority.medium,
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    try {
      return DateTime.parse(text).toLocal();
    } catch (_) {
      return null;
    }
  }

  int _clampInt(
    num? value, {
    required int min,
    required int max,
    required int fallback,
  }) {
    if (value == null) {
      return fallback;
    }
    return value.round().clamp(min, max);
  }

  TaskPriority _parsePriority(String? raw) {
    final normalized = raw?.trim().toLowerCase();
    return switch (normalized) {
      'high' => TaskPriority.high,
      'low' => TaskPriority.low,
      _ => TaskPriority.medium,
    };
  }
}
