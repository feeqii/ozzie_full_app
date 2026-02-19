class AppConstants {
  AppConstants._();

  static const String appName = 'Own Your Day';
  static const String openAiModel = 'gpt-5-mini';

  static const String storageTasksKey = 'oyd.tasks';
  static const String storageSettingsKey = 'oyd.settings';
  static const String storageNotificationEventsKey = 'oyd.notification_events';

  static const int notificationChannelId = 101;
  static const String notificationChannelKey = 'oyd_gentle_nudges';
  static const String notificationChannelName = 'Gentle nudges';
  static const String notificationChannelDescription =
      'Smart, gentle reminders for your priorities.';
}
