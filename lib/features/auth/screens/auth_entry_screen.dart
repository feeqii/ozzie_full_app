import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/atlas_background.dart';
import '../../../core/ui/illustration_frame.dart';
import '../../../core/ui/primary_button.dart';
import '../../../core/ui/secondary_button.dart';

class AuthEntryScreen extends StatelessWidget {
  const AuthEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      background: const AtlasBackground(seed: 11, intensity: 0.8, showGrid: false),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Spacer(),
          const IllustrationFrame(
            size: 140,
            child: Icon(Icons.image_outlined, size: 48),
          ),
          const SizedBox(height: AppSpacing.xxl),
          PrimaryButton(
            label: 'Sign Up',
            onPressed: () => context.push('/auth/signup'),
          ),
          const SizedBox(height: AppSpacing.lg),
          SecondaryButton(
            label: 'Sign In',
            onPressed: () => context.push('/auth/signin'),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Use email + password to continue.',
            style: Theme.of(context).textTheme.labelMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
