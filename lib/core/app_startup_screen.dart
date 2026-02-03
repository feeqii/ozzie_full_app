import 'package:flutter/material.dart';

import 'app_bootstrap.dart';
import 'theme/app_spacing.dart';
import 'theme/app_text_styles.dart';
import 'ui/alert_banner.dart';
import 'ui/full_screen_loader.dart';

class AppStartupScreen extends StatelessWidget {
  const AppStartupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bootstrap = AppBootstrapScope.of(context);

    if (bootstrap.hasError) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('App startup failed', style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.lg),
                AlertBanner(
                  message: bootstrap.errorMessage ?? 'Unknown startup error',
                  variant: AlertBannerVariant.danger,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Check .env and restart the app after setting Supabase values.',
                  style: AppTextStyles.body,
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
