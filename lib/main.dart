import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_bootstrap.dart';
import 'core/app_startup_screen.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: AppBootstrap(child: OzzieApp())));
}

class OzzieApp extends ConsumerWidget {
  const OzzieApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = AppBootstrapScope.of(context);

    if (!bootstrap.isReady) {
      return const MaterialApp(home: AppStartupScreen());
    }

    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Ozzie Quran App',
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
