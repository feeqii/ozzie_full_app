import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../onboarding/theme/onboarding_tokens.dart';
import '../../onboarding/ui/onboarding_button.dart';
import '../../onboarding/ui/onboarding_scaffold.dart';
import '../../onboarding/ui/onboarding_surface_card.dart';
import '../../onboarding/ui/onboarding_text_field.dart';
import '../../onboarding/ui/onboarding_theme_toggle.dart';
import '../controllers/auth_controller.dart';

class AuthForgotPasswordScreen extends ConsumerStatefulWidget {
  const AuthForgotPasswordScreen({super.key});

  @override
  ConsumerState<AuthForgotPasswordScreen> createState() =>
      _AuthForgotPasswordScreenState();
}

class _AuthForgotPasswordScreenState
    extends ConsumerState<AuthForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _errorText;
  bool _isSuccess = false;

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

    final success = await ref
        .read(authControllerProvider.notifier)
        .requestPasswordReset(email: email);

    if (!mounted || !success) {
      return;
    }

    setState(() => _isSuccess = true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final colors = OnboardingColors.resolve(Theme.of(context).brightness);

    return OnboardingScaffold(
      showBack: true,
      onBack: () => context.pop(),
      trailing: const OnboardingThemeToggle(),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Reset your password',
              style: OnboardingTypography.headline(colors.textPrimary),
            ),
            const SizedBox(height: OnboardingSpacing.sm),
            Text(
              'Enter your account email and we\'ll send reset instructions.',
              style: OnboardingTypography.body(colors.textSecondary),
            ),
            const SizedBox(height: OnboardingSpacing.lg),
            if (_isSuccess)
              OnboardingSurfaceCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.mark_email_read_outlined,
                      color: OnboardingPalette.success,
                    ),
                    const SizedBox(width: OnboardingSpacing.sm),
                    Expanded(
                      child: Text(
                        'Check your inbox for password reset instructions.',
                        style: OnboardingTypography.body(colors.textPrimary),
                      ),
                    ),
                  ],
                ),
              )
            else
              OnboardingTextField(
                label: 'Email',
                hint: 'name@example.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                errorText: _errorText,
                onChanged: (_) => setState(() => _errorText = null),
              ),
            if (state.errorMessage != null && !_isSuccess) ...[
              const SizedBox(height: OnboardingSpacing.md),
              _InlineError(message: state.errorMessage!),
            ],
            const SizedBox(height: OnboardingSpacing.xl),
            OnboardingButton(
              label: _isSuccess ? 'Back to sign in' : 'Send reset email',
              isLoading: state.isLoading,
              onPressed: state.isLoading
                  ? null
                  : _isSuccess
                  ? () => context.go('/auth/signin')
                  : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = OnboardingColors.resolve(Theme.of(context).brightness);

    return Container(
      padding: const EdgeInsets.all(OnboardingSpacing.md),
      decoration: BoxDecoration(
        color: OnboardingPalette.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(OnboardingRadii.sm),
        border: Border.all(
          color: OnboardingPalette.danger.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        message,
        style: OnboardingTypography.body(colors.textPrimary),
      ),
    );
  }
}
