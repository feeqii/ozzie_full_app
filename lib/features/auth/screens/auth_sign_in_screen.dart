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

class AuthSignInScreen extends ConsumerStatefulWidget {
  const AuthSignInScreen({super.key});

  @override
  ConsumerState<AuthSignInScreen> createState() => _AuthSignInScreenState();
}

class _AuthSignInScreenState extends ConsumerState<AuthSignInScreen> {
  final _emailController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
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
          shouldCreateUser: false,
        );

    final state = ref.read(authControllerProvider);
    if (state.errorMessage != null && mounted) {
      return;
    }

    if (mounted) {
      context.push(
        '/auth/otp',
        extra: AuthFlowArgs(email: email, isSignUp: false),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return AppScaffold(
      appBar: const AppAppBar(title: 'Sign In'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Sign in', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Welcome back to Ozzie. Login to continue your child’s journey.',
            style: AppTextStyles.body,
          ),
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
          if (state.errorMessage != null)
            AlertBanner(
              message: _mapSignInError(state.errorMessage!),
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

  String _mapSignInError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('user not found') || lower.contains('not found')) {
      return 'No account found. Please sign up first.';
    }
    return message;
  }
}
