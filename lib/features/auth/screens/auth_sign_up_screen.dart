import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/ui/alert_banner.dart';
import '../../../core/ui/app_app_bar.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/app_text_field.dart';
import '../../../core/ui/primary_button.dart';
import '../controllers/auth_controller.dart';
import '../models/auth_flow_args.dart';

class AuthSignUpScreen extends ConsumerStatefulWidget {
  const AuthSignUpScreen({super.key});

  @override
  ConsumerState<AuthSignUpScreen> createState() => _AuthSignUpScreenState();
}

class _AuthSignUpScreenState extends ConsumerState<AuthSignUpScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    final trimmed = value.trim();
    return trimmed.contains('@') && trimmed.contains('.');
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _errorText = 'Enter a valid email address.');
      return;
    }
    setState(() => _errorText = null);

    await ref.read(authControllerProvider.notifier).sendOtp(
          email: email,
          shouldCreateUser: true,
          displayName: _nameController.text.trim(),
        );

    final state = ref.read(authControllerProvider);
    if (state.errorMessage != null && mounted) {
      return;
    }

    if (mounted) {
      context.push(
        '/auth/otp',
        extra: AuthFlowArgs(
          email: email,
          isSignUp: true,
          displayName: _nameController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return AppScaffold(
      appBar: const AppAppBar(title: 'Sign Up'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Create your account', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          Text('We will send a verification code to your email.',
              style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: 'Enter your email',
            hintText: 'mail@mailto.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            errorText: _errorText,
            onChanged: (_) => setState(() => _errorText = null),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Display name (optional)',
            hintText: 'Parent name',
            controller: _nameController,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (state.errorMessage != null)
            AlertBanner(
              message: state.errorMessage!,
              variant: AlertBannerVariant.danger,
            ),
          const Spacer(),
          PrimaryButton(
            label: 'Send OTP',
            isLoading: state.isLoading,
            onPressed: state.isLoading ? null : _submit,
          ),
        ],
      ),
    );
  }
}
