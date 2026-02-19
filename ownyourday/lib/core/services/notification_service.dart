import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:ownyourday/core/constants/app_constants.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    tz.initializeTimeZones();
    try {
      final localZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localZone));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(android: android, iOS: darwin);
    await _plugin.initialize(settings);

    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final iosGranted =
        await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
        true;

    final androidGranted =
        await android?.requestNotificationsPermission() ?? true;
    return iosGranted && androidGranted;
  }

  Future<void> scheduleGentleNudge({
    required String taskId,
    required String title,
    required DateTime primaryAt,
    DateTime? followUpAt,
  }) async {
    final primaryId = _buildNotificationId(taskId, 0);
    await _schedule(
      id: primaryId,
      title: title,
      body: 'A gentle nudge: this matters for today.',
      scheduleAt: primaryAt,
      payload: '$taskId|primary',
    );

    if (followUpAt != null) {
      final followUpId = _buildNotificationId(taskId, 1);
      await _schedule(
        id: followUpId,
        title: title,
        body: 'Still open when you have a minute.',
        scheduleAt: followUpAt,
        payload: '$taskId|followup',
      );
    }
  }

  Future<void> cancelTaskNotifications(String taskId) async {
    await _plugin.cancel(_buildNotificationId(taskId, 0));
    await _plugin.cancel(_buildNotificationId(taskId, 1));
  }

  int notificationIdForTask(String taskId) {
    return _buildNotificationId(taskId, 0);
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduleAt,
    required String payload,
  }) async {
    final now = DateTime.now();
    final effectiveTime =
        scheduleAt.isBefore(now.add(const Duration(minutes: 1)))
        ? now.add(const Duration(minutes: 1))
        : scheduleAt;

    const androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelKey,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(effectiveTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );

    if (kDebugMode) {
      debugPrint('Scheduled notification $id for $effectiveTime');
    }
  }

  int _buildNotificationId(String taskId, int salt) {
    final seed = taskId.hashCode.abs();
    final salted = seed + salt * 4099;
    return salted % 2147483647;
  }
}
