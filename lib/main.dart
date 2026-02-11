import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_bootstrap.dart';
import 'core/app_startup_screen.dart';
import 'core/flags/ui_overhaul_flag_provider.dart';
import 'core/flags/ui_overhaul_flags.dart';
import 'core/practice_session_lifecycle_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme_v2/ozzie_theme.dart';

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

    // Keep a single lifecycle observer active for practice session tracking.
    ref.watch(practiceSessionLifecycleProvider);

    final router = ref.watch(appRouterProvider);
    final flags = ref.watch(uiOverhaulFlagsProvider);
    final appThemeConfig = resolveAppThemeConfig(flags);

    return MaterialApp.router(
      title: 'Ozzie Quran App',
      theme: appThemeConfig.theme,
      darkTheme: appThemeConfig.darkTheme,
      themeMode: appThemeConfig.themeMode,
      routerConfig: router,
    );
  }
}

@immutable
class OzzieAppThemeConfig {
  const OzzieAppThemeConfig({
    required this.theme,
    required this.darkTheme,
    required this.themeMode,
  });

  final ThemeData theme;
  final ThemeData darkTheme;
  final ThemeMode themeMode;
}

@visibleForTesting
OzzieAppThemeConfig resolveAppThemeConfig(UiOverhaulFlags flags) {
  if (flags.themeV2) {
    final light = OzzieTheme.childLight();
    return OzzieAppThemeConfig(
      theme: light,
      darkTheme: light,
      themeMode: ThemeMode.light,
    );
  }

  return OzzieAppThemeConfig(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: ThemeMode.system,
  );
}
