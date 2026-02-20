import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../onboarding/onboarding_flow.dart';
import '../../onboarding/theme/onboarding_tokens.dart';
import '../../onboarding/ui/onboarding_button.dart';
import '../../onboarding/ui/onboarding_scaffold.dart';
import '../../onboarding/ui/onboarding_surface_card.dart';
import '../../onboarding/ui/onboarding_text_field.dart';
import '../../onboarding/ui/onboarding_theme_toggle.dart';
import '../controllers/auth_controller.dart';

class AuthSignUpScreen extends ConsumerStatefulWidget {
  const AuthSignUpScreen({super.key});

  @override
  ConsumerState<AuthSignUpScreen> createState() => _AuthSignUpScreenState();
}

class _AuthSignUpScreenState extends ConsumerState<AuthSignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
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

    final success = await ref
        .read(authControllerProvider.notifier)
        .signUp(
          email: email,
          password: password,
          displayName: _nameController.text.trim(),
        );

    if (!success || !mounted) {
      return;
    }

    context.go(buildPostAuthOnboardingRoute().toString());
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
              'Create your parent account',
              style: OnboardingTypography.headline(colors.textPrimary),
            ),
            const SizedBox(height: OnboardingSpacing.sm),
            Text(
              'We\'ll use this account for secure family access and progress tracking.',
              style: OnboardingTypography.body(colors.textSecondary),
            ),
            const SizedBox(height: OnboardingSpacing.lg),
            const OnboardingSurfaceCard(child: _SignUpHeader()),
            const SizedBox(height: OnboardingSpacing.lg),
            OnboardingTextField(
              label: 'Email',
              hint: 'name@example.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              errorText: _errorText,
              onChanged: (_) => setState(() => _errorText = null),
            ),
            const SizedBox(height: OnboardingSpacing.md),
            OnboardingTextField(
              label: 'Password',
              hint: 'At least 6 characters',
              controller: _passwordController,
              obscureText: true,
              onChanged: (_) => setState(() => _errorText = null),
            ),
            const SizedBox(height: OnboardingSpacing.md),
            OnboardingTextField(
              label: 'Parent name (optional)',
              hint: 'How should we address you?',
              controller: _nameController,
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: OnboardingSpacing.md),
              _InlineError(message: state.errorMessage!),
            ],
            const SizedBox(height: OnboardingSpacing.xl),
            OnboardingButton(
              label: 'Continue',
              isLoading: state.isLoading,
              onPressed: state.isLoading ? null : _submit,
            ),
            const SizedBox(height: OnboardingSpacing.xs),
            OnboardingButton(
              label: 'Already have an account? Sign in',
              variant: OnboardingButtonVariant.text,
              onPressed: () => context.replace('/auth/signin'),
            ),
            const SizedBox(height: OnboardingSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _SignUpHeader extends StatelessWidget {
  const _SignUpHeader();

  @override
  Widget build(BuildContext context) {
    final colors = OnboardingColors.resolve(Theme.of(context).brightness);

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: OnboardingPalette.orange.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(OnboardingRadii.sm),
          ),
          child: const Icon(
            Icons.verified_user_rounded,
            color: OnboardingPalette.orange,
          ),
        ),
        const SizedBox(width: OnboardingSpacing.sm),
        Expanded(
          child: Text(
            'Your account unlocks parental controls and personalized child onboarding.',
            style: OnboardingTypography.body(colors.textPrimary),
          ),
        ),
      ],
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
