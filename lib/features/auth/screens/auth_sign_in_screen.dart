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

class AuthSignInScreen extends ConsumerStatefulWidget {
  const AuthSignInScreen({super.key});

  @override
  ConsumerState<AuthSignInScreen> createState() => _AuthSignInScreenState();
}

class _AuthSignInScreenState extends ConsumerState<AuthSignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    final trimmed = value.trim();
    return trimmed.contains('@') && trimmed.contains('.');
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (!_isValidEmail(email)) {
      setState(() => _errorText = 'Enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorText = 'Password must be at least 6 characters.');
      return;
    }
    setState(() => _errorText = null);

    final success = await ref.read(authControllerProvider.notifier).signIn(
          email: email,
          password: password,
        );

    if (!success && mounted) {
      return;
    }

    if (mounted) {
      context.go('/auth/success');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return AppScaffold(
      appBar: const AppAppBar(title: 'Sign In'),
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
                    AppTextField(
                      label: 'Password',
                      hintText: 'Enter your password',
                      controller: _passwordController,
                      obscureText: true,
                      keyboardType: TextInputType.visiblePassword,
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
                      label: 'Sign In',
                      isLoading: state.isLoading,
                      onPressed: state.isLoading ? null : _submit,
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

  String _mapSignInError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('user not found') || lower.contains('not found')) {
      return 'No account found. Please sign up first.';
    }
    return message;
  }
}
