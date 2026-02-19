import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownyourday/core/services/local_storage_service.dart';
import 'package:ownyourday/core/services/notification_service.dart';
import 'package:ownyourday/core/services/openai_task_parser.dart';
import 'package:ownyourday/core/services/prioritization_service.dart';
import 'package:ownyourday/core/services/reminder_planner.dart';
import 'package:ownyourday/state/app_controller.dart';

final environmentApiKeyProvider = Provider<String>((ref) {
  return const String.fromEnvironment('OYD_OPENAI_KEY');
});

final localStorageProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError(
    'localStorageProvider must be overridden in main().',
  );
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError(
    'notificationServiceProvider must be overridden in main().',
  );
});

final prioritizationServiceProvider = Provider<PrioritizationService>((ref) {
  return PrioritizationService();
});

final reminderPlannerProvider = Provider<ReminderPlanner>((ref) {
  return ReminderPlanner();
});

final openAiTaskParserProvider = Provider<OpenAiTaskParser>((ref) {
  return OpenAiTaskParser();
});

final appControllerProvider = ChangeNotifierProvider<AppController>((ref) {
  final controller = AppController(
    storage: ref.watch(localStorageProvider),
    notifications: ref.watch(notificationServiceProvider),
    prioritization: ref.watch(prioritizationServiceProvider),
    reminderPlanner: ref.watch(reminderPlannerProvider),
    openAiTaskParser: ref.watch(openAiTaskParserProvider),
    environmentApiKey: ref.watch(environmentApiKeyProvider),
  );
  controller.initialize();
  return controller;
});
