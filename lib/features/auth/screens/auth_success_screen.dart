import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/atlas_background.dart';
import '../../../core/ui/atlas_illustrations.dart';
import '../../../core/ui/illustration_frame.dart';
import '../../../core/ui/primary_button.dart';

class AuthSuccessScreen extends StatelessWidget {
  const AuthSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      background: const AtlasBackground(seed: 23, intensity: 0.8, showGrid: false),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const IllustrationFrame(
            size: 140,
            child: AtlasIllustration(kind: AtlasIllustrationKind.success),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Success', style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: AppSpacing.sm),
          Text('You are signed in', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Continue',
            onPressed: () => context.go('/parent/pin/setup'),
          ),
        ],
      ),
    );
  }
}
