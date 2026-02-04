import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/illustration_frame.dart';
import '../../../core/ui/primary_button.dart';

class AuthSuccessScreen extends StatelessWidget {
  const AuthSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const IllustrationFrame(
            size: 140,
            child: Icon(Icons.check_circle_outline, size: 52),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Success', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          Text('You are signed in', style: AppTextStyles.body),
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
