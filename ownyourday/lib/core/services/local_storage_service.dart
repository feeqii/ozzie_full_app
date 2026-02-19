import 'dart:convert';

import 'package:ownyourday/core/constants/app_constants.dart';
import 'package:ownyourday/features/tasks/domain/task.dart';
import 'package:ownyourday/state/app_settings.dart';
import 'package:ownyourday/state/notification_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  LocalStorageService._(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService._(prefs);
  }

  Future<List<Task>> readTasks() async {
    final raw =
        _prefs.getStringList(AppConstants.storageTasksKey) ?? <String>[];
    return raw
        .map((value) {
          try {
            return Task.fromJson(value);
          } catch (_) {
            return null;
          }
        })
        .whereType<Task>()
        .toList();
  }

  Future<void> writeTasks(List<Task> tasks) {
    final encoded = tasks.map((task) => task.toJson()).toList();
    return _prefs.setStringList(AppConstants.storageTasksKey, encoded);
  }

  Future<AppSettings> readSettings() async {
    final raw = _prefs.getString(AppConstants.storageSettingsKey);
    if (raw == null || raw.isEmpty) {
      return AppSettings();
    }

    try {
      return AppSettings.fromJson(raw);
    } catch (_) {
      return AppSettings();
    }
  }

  Future<void> writeSettings(AppSettings settings) {
    return _prefs.setString(AppConstants.storageSettingsKey, settings.toJson());
  }

  Future<List<NotificationEvent>> readNotificationEvents() async {
    final raw =
        _prefs.getStringList(AppConstants.storageNotificationEventsKey) ??
        <String>[];
    return raw
        .map((value) {
          try {
            return NotificationEvent.fromJson(value);
          } catch (_) {
            return null;
          }
        })
        .whereType<NotificationEvent>()
        .toList();
  }

  Future<void> writeNotificationEvents(List<NotificationEvent> events) {
    final encoded = events.map((event) => json.encode(event.toMap())).toList();
    return _prefs.setStringList(
      AppConstants.storageNotificationEventsKey,
      encoded,
    );
  }
}
