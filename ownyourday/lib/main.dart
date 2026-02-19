import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownyourday/app/own_your_day_app.dart';
import 'package:ownyourday/core/services/local_storage_service.dart';
import 'package:ownyourday/core/services/notification_service.dart';
import 'package:ownyourday/state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = await LocalStorageService.create();
  final notifications = NotificationService();
  await notifications.initialize();

  runApp(
    ProviderScope(
      overrides: <Override>[
        localStorageProvider.overrideWithValue(storage),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const OwnYourDayApp(),
    ),
  );
}
