import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownyourday/app/app_shell.dart';
import 'package:ownyourday/core/theme/app_theme.dart';
import 'package:ownyourday/features/onboarding/presentation/onboarding_flow_screen.dart';
import 'package:ownyourday/state/app_controller.dart';
import 'package:ownyourday/state/providers.dart';

class OwnYourDayApp extends ConsumerWidget {
  const OwnYourDayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);

    return MaterialApp(
      title: 'Own Your Day',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: app.settings.themeMode,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        switchInCurve: Curves.easeOutQuart,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _selectHome(app),
      ),
    );
  }

  Widget _selectHome(AppController app) {
    if (app.isBootstrapping) {
      return const _BootScreen(key: ValueKey<String>('boot'));
    }

    if (!app.settings.hasCompletedOnboarding || !app.settings.hasMockLoggedIn) {
      return const OnboardingFlowScreen(key: ValueKey<String>('onboarding'));
    }

    return const AppShell(key: ValueKey<String>('shell'));
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.brightness == Brightness.dark
                ? const <Color>[Color(0xFF07080D), Color(0xFF1B1330)]
                : const <Color>[Color(0xFFF7F2EC), Color(0xFFF3EAFE)],
          ),
        ),
        child: const Center(
          child: SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      ),
    );
  }
}
