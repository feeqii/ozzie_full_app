import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/ui/alert_banner.dart';
import '../../../core/ui/app_app_bar.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/app_text_button.dart';
import '../../../core/ui/otp_code_input.dart';
import '../../../core/ui/primary_button.dart';
import '../controllers/auth_controller.dart';
import '../models/auth_flow_args.dart';

class AuthOtpScreen extends ConsumerStatefulWidget {
  const AuthOtpScreen({super.key, required this.args});

  final AuthFlowArgs args;

  @override
  ConsumerState<AuthOtpScreen> createState() => _AuthOtpScreenState();
}

class _AuthOtpScreenState extends ConsumerState<AuthOtpScreen> {
  String _code = '';
  String? _errorText;

  Future<void> _verify() async {
    if (_code.trim().length != 6) {
      setState(() => _errorText = 'Enter the 6-digit code.');
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .verifyOtp(email: widget.args.email, token: _code.trim());

    if (!success && mounted) {
      return;
    }

    await ref.read(authControllerProvider.notifier).upsertProfile();

    if (mounted) {
      context.go('/auth/success');
    }
  }

  Future<void> _resend() async {
    await ref.read(authControllerProvider.notifier).sendOtp(
          email: widget.args.email,
          shouldCreateUser: widget.args.isSignUp,
          displayName: widget.args.displayName,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return AppScaffold(
      appBar: const AppAppBar(title: 'Verification Code'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Verification code', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Please enter the verification code sent to your email\n${widget.args.email}',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Verification code', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.md),
          OtpCodeInput(
            length: 6,
            onChanged: (value) {
              setState(() {
                _code = value;
                _errorText = null;
              });
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_errorText != null)
            AlertBanner(message: _errorText!, variant: AlertBannerVariant.danger)
          else if (state.errorMessage != null)
            AlertBanner(
              message: state.errorMessage!,
              variant: AlertBannerVariant.danger,
            ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Didn’t receive the code? ', style: AppTextStyles.body),
              AppTextButton(
                label: 'Resend',
                onPressed: state.isLoading ? null : _resend,
              ),
            ],
          ),
          const Spacer(),
          PrimaryButton(
            label: 'Verify',
            isLoading: state.isLoading,
            onPressed: state.isLoading ? null : _verify,
          ),
        ],
      ),
    );
  }
}
