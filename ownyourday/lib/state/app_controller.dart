import 'package:flutter/material.dart';
import 'package:ownyourday/core/services/local_storage_service.dart';
import 'package:ownyourday/core/services/notification_service.dart';
import 'package:ownyourday/core/services/openai_task_parser.dart';
import 'package:ownyourday/core/services/prioritization_service.dart';
import 'package:ownyourday/core/services/reminder_planner.dart';
import 'package:ownyourday/features/tasks/domain/task.dart';
import 'package:ownyourday/features/tasks/domain/task_priority.dart';
import 'package:ownyourday/features/tasks/domain/task_source.dart';
import 'package:ownyourday/features/tasks/domain/task_status.dart';
import 'package:ownyourday/state/app_settings.dart';
import 'package:ownyourday/state/notification_event.dart';
import 'package:uuid/uuid.dart';

class AppController extends ChangeNotifier {
  AppController({
    required LocalStorageService storage,
    required NotificationService notifications,
    required PrioritizationService prioritization,
    required ReminderPlanner reminderPlanner,
    required OpenAiTaskParser openAiTaskParser,
    required String environmentApiKey,
  }) : _storage = storage,
       _notifications = notifications,
       _prioritization = prioritization,
       _reminderPlanner = reminderPlanner,
       _openAiTaskParser = openAiTaskParser,
       _environmentApiKey = environmentApiKey;

  final LocalStorageService _storage;
  final NotificationService _notifications;
  final PrioritizationService _prioritization;
  final ReminderPlanner _reminderPlanner;
  final OpenAiTaskParser _openAiTaskParser;
  final String _environmentApiKey;
  final Uuid _uuid = const Uuid();

  bool _isBootstrapping = true;
  bool _isAiBusy = false;
  String? _lastError;
  int _tabIndex = 0;
  bool _showTimelineView = true;
  DateTime _selectedDate = DateTime.now();

  AppSettings _settings = AppSettings();
  List<Task> _tasks = <Task>[];
  List<NotificationEvent> _notificationEvents = <NotificationEvent>[];

  bool get isBootstrapping => _isBootstrapping;
  bool get isAiBusy => _isAiBusy;
  String? get lastError => _lastError;
  int get tabIndex => _tabIndex;
  bool get showTimelineView => _showTimelineView;
  DateTime get selectedDate => _selectedDate;
  AppSettings get settings => _settings;

  List<Task> get tasks => List<Task>.unmodifiable(_tasks);
  List<NotificationEvent> get notificationEvents =>
      List<NotificationEvent>.unmodifiable(_notificationEvents);

  List<Task> get openTasks {
    return _tasks.where((task) => task.status == TaskStatus.todo).toList();
  }

  List<Task> get completedTasks {
    return _tasks.where((task) => task.status == TaskStatus.done).toList();
  }

  List<Task> get todayAnytimeTasks {
    final selected = _dateOnly(_selectedDate);
    return openTasks
        .where(
          (task) => task.dueAt == null && _dateOnly(task.createdAt) == selected,
        )
        .toList()
      ..sort(_taskSort);
  }

  List<Task> get plannedTasks {
    final selected = _dateOnly(_selectedDate);
    return openTasks
        .where(
          (task) => task.dueAt != null && _dateOnly(task.dueAt!) == selected,
        )
        .toList()
      ..sort(_taskSort);
  }

  List<Task> get highPriorityOpenTasks {
    final selected = _dateOnly(_selectedDate);
    return openTasks
        .where(
          (task) =>
              task.priority == TaskPriority.high &&
              (task.dueAt == null || _dateOnly(task.dueAt!) == selected),
        )
        .toList()
      ..sort(_taskSort);
  }

  double get completionRate {
    if (_tasks.isEmpty) {
      return 0;
    }
    return completedTasks.length / _tasks.length;
  }

  int get streakDays {
    if (completedTasks.isEmpty) {
      return 0;
    }

    final completedDates =
        completedTasks.map((task) => _dateOnly(task.updatedAt)).toSet().toList()
          ..sort((a, b) => b.compareTo(a));

    var streak = 0;
    var cursor = _dateOnly(DateTime.now());

    while (completedDates.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  Future<void> initialize() async {
    _isBootstrapping = true;
    notifyListeners();

    _tasks = await _storage.readTasks();
    _settings = await _storage.readSettings();
    _notificationEvents = await _storage.readNotificationEvents();

    if (_settings.openAiApiKey.isEmpty && _environmentApiKey.isNotEmpty) {
      _settings = _settings.copyWith(openAiApiKey: _environmentApiKey);
      await _storage.writeSettings(_settings);
    }

    _isBootstrapping = false;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _settings = _settings.copyWith(hasCompletedOnboarding: true);
    await _storage.writeSettings(_settings);
    notifyListeners();
  }

  Future<void> completeMockLogin() async {
    _settings = _settings.copyWith(hasMockLoggedIn: true);
    await _storage.writeSettings(_settings);
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    await _storage.writeSettings(_settings);
    notifyListeners();
  }

  Future<void> updateOpenAiApiKey(String key) async {
    _settings = _settings.copyWith(openAiApiKey: key.trim());
    await _storage.writeSettings(_settings);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    var granted = enabled;
    if (enabled) {
      granted = await _notifications.requestPermissions();
    }

    _settings = _settings.copyWith(notificationsEnabled: granted);
    await _storage.writeSettings(_settings);

    if (granted) {
      for (final task in openTasks) {
        await _rescheduleTask(task);
      }
      await _persistAll();
    } else {
      for (final task in _tasks) {
        await _notifications.cancelTaskNotifications(task.id);
      }
    }

    notifyListeners();
  }

  Future<void> setTab(int index) async {
    _tabIndex = index;
    notifyListeners();
  }

  void setTodayView(bool timeline) {
    _showTimelineView = timeline;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = _dateOnly(date);
    notifyListeners();
  }

  Future<Task> addTaskFromDraft(TaskDraft draft) async {
    _lastError = null;
    final now = DateTime.now();
    final priority =
        draft.priority ?? _prioritization.inferPriority(draft, now);
    final reminderPlan = _reminderPlanner.buildPlan(draft, now, priority);

    Task task = Task(
      id: _uuid.v4(),
      title: draft.title.trim(),
      notes: draft.notes.trim(),
      createdAt: now,
      updatedAt: now,
      dueAt: draft.dueAt,
      remindAt: reminderPlan.primaryAt,
      priority: priority,
      importance: draft.importance.clamp(1, 5),
      estimatedMinutes: draft.estimatedMinutes.clamp(5, 480),
      source: draft.source,
    );

    if (_settings.notificationsEnabled) {
      await _notifications.scheduleGentleNudge(
        taskId: task.id,
        title: task.title,
        primaryAt: reminderPlan.primaryAt,
        followUpAt: reminderPlan.followUpAt,
      );

      task = task.copyWith(
        notificationId: _notifications.notificationIdForTask(task.id),
      );

      _appendNotificationEvent(
        taskId: task.id,
        kind: 'scheduled_primary',
        scheduledFor: reminderPlan.primaryAt,
      );

      if (reminderPlan.followUpAt != null) {
        _appendNotificationEvent(
          taskId: task.id,
          kind: 'scheduled_follow_up',
          scheduledFor: reminderPlan.followUpAt,
        );
      }
    }

    _tasks = <Task>[task, ..._tasks]..sort(_taskSort);
    await _persistAll();
    notifyListeners();
    return task;
  }

  Future<AiTaskSuggestion?> parseCaptureText(String rawText) async {
    if (rawText.trim().isEmpty) {
      _lastError = 'Add text to parse first.';
      notifyListeners();
      return null;
    }

    final key = _settings.openAiApiKey.isNotEmpty
        ? _settings.openAiApiKey
        : _environmentApiKey;

    if (key.isEmpty) {
      _lastError =
          'OpenAI key missing. Add it in profile settings or pass --dart-define=OYD_OPENAI_KEY=...';
      notifyListeners();
      return null;
    }

    _isAiBusy = true;
    _lastError = null;
    notifyListeners();

    final suggestion = await _openAiTaskParser.parse(
      apiKey: key,
      rawText: rawText,
      now: DateTime.now(),
    );

    _isAiBusy = false;
    if (suggestion == null) {
      _lastError = 'Could not parse this capture. Try rewording it.';
    }
    notifyListeners();
    return suggestion;
  }

  Future<Task?> addTaskFromAiText(String rawText) async {
    final suggestion = await parseCaptureText(rawText);
    if (suggestion == null) {
      return null;
    }
    final draft = TaskDraft(
      title: suggestion.title,
      notes: suggestion.notes,
      dueAt: suggestion.dueAt,
      remindAt: suggestion.remindAt,
      priority: suggestion.priority,
      importance: suggestion.importance,
      estimatedMinutes: suggestion.estimatedMinutes,
      source: TaskSource.ai,
    );
    return addTaskFromDraft(draft);
  }

  Future<void> toggleTaskStatus(String taskId) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index == -1) {
      return;
    }

    final task = _tasks[index];
    final nextStatus = task.status == TaskStatus.todo
        ? TaskStatus.done
        : TaskStatus.todo;

    final updated = task.copyWith(
      status: nextStatus,
      updatedAt: DateTime.now(),
    );

    _tasks[index] = updated;

    if (nextStatus == TaskStatus.done) {
      await _notifications.cancelTaskNotifications(task.id);
      _appendNotificationEvent(taskId: task.id, kind: 'completed');
    } else if (_settings.notificationsEnabled) {
      await _rescheduleTask(updated);
    }

    await _persistAll();
    notifyListeners();
  }

  Future<void> removeTask(String taskId) async {
    _tasks.removeWhere((task) => task.id == taskId);
    await _notifications.cancelTaskNotifications(taskId);
    _appendNotificationEvent(taskId: taskId, kind: 'deleted');
    await _persistAll();
    notifyListeners();
  }

  Future<void> _rescheduleTask(Task task) async {
    if (task.status == TaskStatus.done) {
      return;
    }

    final draft = TaskDraft(
      title: task.title,
      notes: task.notes,
      dueAt: task.dueAt,
      remindAt: task.remindAt,
      priority: task.priority,
      importance: task.importance,
      estimatedMinutes: task.estimatedMinutes,
      source: task.source,
    );

    final now = DateTime.now();
    final reminderPlan = _reminderPlanner.buildPlan(draft, now, task.priority);

    await _notifications.cancelTaskNotifications(task.id);
    await _notifications.scheduleGentleNudge(
      taskId: task.id,
      title: task.title,
      primaryAt: reminderPlan.primaryAt,
      followUpAt: reminderPlan.followUpAt,
    );

    _tasks = _tasks.map((entry) {
      if (entry.id != task.id) {
        return entry;
      }
      return entry.copyWith(
        remindAt: reminderPlan.primaryAt,
        updatedAt: now,
        notificationId: _notifications.notificationIdForTask(task.id),
      );
    }).toList();

    _appendNotificationEvent(
      taskId: task.id,
      kind: 'rescheduled',
      scheduledFor: reminderPlan.primaryAt,
    );
  }

  Future<void> _persistAll() async {
    await _storage.writeTasks(_tasks);
    await _storage.writeSettings(_settings);
    await _storage.writeNotificationEvents(_notificationEvents);
  }

  void _appendNotificationEvent({
    required String taskId,
    required String kind,
    DateTime? scheduledFor,
    String? details,
  }) {
    final event = NotificationEvent(
      id: _uuid.v4(),
      taskId: taskId,
      kind: kind,
      createdAt: DateTime.now(),
      scheduledFor: scheduledFor,
      details: details,
    );

    _notificationEvents = <NotificationEvent>[event, ..._notificationEvents];
    if (_notificationEvents.length > 120) {
      _notificationEvents = _notificationEvents.take(120).toList();
    }
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  int _taskSort(Task a, Task b) {
    final aDue = a.dueAt;
    final bDue = b.dueAt;

    if (aDue != null && bDue != null) {
      final compareDue = aDue.compareTo(bDue);
      if (compareDue != 0) {
        return compareDue;
      }
    } else if (aDue != null && bDue == null) {
      return -1;
    } else if (aDue == null && bDue != null) {
      return 1;
    }

    final priorityCompare = b.priority.scoreWeight.compareTo(
      a.priority.scoreWeight,
    );
    if (priorityCompare != 0) {
      return priorityCompare;
    }

    return a.createdAt.compareTo(b.createdAt);
  }
}
