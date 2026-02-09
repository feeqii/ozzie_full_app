import 'package:flutter/material.dart';

import 'app_bootstrap.dart';
import 'theme/app_spacing.dart';
import 'ui/alert_banner.dart';
import 'ui/app_scaffold.dart';
import 'ui/atlas_background.dart';
import 'ui/full_screen_loader.dart';

class AppStartupScreen extends StatelessWidget {
  const AppStartupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bootstrap = AppBootstrapScope.of(context);

    if (bootstrap.hasError) {
      final scheme = Theme.of(context).colorScheme;
      return AppScaffold(
        background: const AtlasBackground(seed: 5, intensity: 0.85, showGrid: false),
        contentPadding: const EdgeInsets.all(AppSpacing.xl),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'App startup failed',
                  style: Theme.of(context).textTheme.displayLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                AlertBanner(
                  message: bootstrap.errorMessage ?? 'Unknown startup error',
                  variant: AlertBannerVariant.danger,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Check Supabase configuration and restart the app.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.78),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const Scaffold(body: FullScreenLoader(message: 'Starting...'));
  }
}
