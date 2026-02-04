import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/ui/app_app_bar.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/primary_button.dart';

class AuthOtpScreen extends StatelessWidget {
  const AuthOtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AppAppBar(title: 'Verification Code'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Verification code removed', style: AppTextStyles.title),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'This app now uses email + password. Use Sign In or Sign Up to continue.',
                      style: AppTextStyles.body,
                    ),
                    const Spacer(),
                    PrimaryButton(
                      label: 'Back to Sign In',
                      onPressed: () => context.go('/auth/signin'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
