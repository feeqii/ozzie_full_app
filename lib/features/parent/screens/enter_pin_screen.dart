import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/ui/app_app_bar.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/app_snackbar.dart';
import '../../../core/ui/app_text_button.dart';
import '../../../core/ui/pin_input.dart';
import '../../../core/ui/primary_button.dart';
import '../../../core/utils/pin_hash.dart';
import '../../auth/controllers/auth_controller.dart';
import '../providers/parent_profile_provider.dart';

class EnterPinScreen extends ConsumerStatefulWidget {
  const EnterPinScreen({super.key});

  @override
  ConsumerState<EnterPinScreen> createState() => _EnterPinScreenState();
}

class _EnterPinScreenState extends ConsumerState<EnterPinScreen> {
  String _pin = '';
  bool _isLoading = false;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _appendDigit(String digit) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += digit;
    });
  }

  void _removeDigit() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _verify() async {
    if (_pin.length < 4) {
      AppSnackbar.show(context, message: 'Enter your 4-digit PIN.');
      return;
    }

    final attempts = ref.read(pinAttemptProvider.notifier);
    if (attempts.isCoolingDown) {
      AppSnackbar.show(context, message: 'Too many attempts. Try again shortly.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final profile = await ref.read(parentProfileProvider.future);
    final storedHash = profile?.pinHash;
    if (storedHash == null || storedHash.isEmpty) {
      if (mounted) {
        context.go('/parent/pin/setup');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    final isValid = PinHash.verifyPin(_pin, storedHash);
    if (!isValid) {
      attempts.registerFailure();
      if (!mounted) {
        return;
      }
      AppSnackbar.show(context, message: 'Incorrect PIN.', isError: true);
      setState(() {
        _pin = '';
      });
      _startCooldownTickerIfNeeded();
    } else {
      attempts.reset();
      ref.read(pinVerifiedProvider.notifier).state = true;
      if (mounted) {
        context.go('/parent/child/select');
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startCooldownTickerIfNeeded() {
    _cooldownTimer?.cancel();
    final controller = ref.read(pinAttemptProvider.notifier);
    if (!controller.isCoolingDown) {
      return;
    }
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!controller.isCoolingDown) {
        _cooldownTimer?.cancel();
        setState(() {});
      } else {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final attemptState = ref.watch(pinAttemptProvider);
    final cooldownUntil = attemptState.cooldownUntil;
    final cooldownSeconds = cooldownUntil == null
        ? 0
        : cooldownUntil.difference(DateTime.now()).inSeconds.clamp(0, 999);

    return AppScaffold(
      appBar: const AppAppBar(title: 'Parental PIN', showBack: false),
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
                    Text('Hello, parent', style: AppTextStyles.title, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Please confirm your entrance.',
                      style: AppTextStyles.body,
                      textAlign: TextAlign.center,
                    ),
                    if (cooldownSeconds > 0) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Try again in $cooldownSeconds seconds',
                        style: AppTextStyles.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    PinInput(
                      length: 4,
                      value: _pin,
                      onForgotPin: () {
                        _signOutToAuth();
                      },
                    ),
                    Center(
                      child: AppTextButton(
                        label: 'Switch account',
                        onPressed: _signOutToAuth,
                      ),
                    ),
                    const Spacer(),
                    _PinKeypad(
                      onDigit: _appendDigit,
                      onBackspace: _removeDigit,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: 'Verify PIN',
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _verify,
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

  Future<void> _signOutToAuth() async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (mounted) {
      context.go('/auth/entry');
    }
  }
}

class _PinKeypad extends StatelessWidget {
  const _PinKeypad({
    required this.onDigit,
    required this.onBackspace,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final buttons = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'back'],
    ];

    return Column(
      children: buttons.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((value) {
              if (value.isEmpty) {
                return const SizedBox(width: 56, height: 56);
              }
              if (value == 'back') {
                return _KeypadButton(
                  label: '⌫',
                  onPressed: onBackspace,
                );
              }
              return _KeypadButton(
                label: value,
                onPressed: () => onDigit(value),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: TextButton(
        onPressed: onPressed,
        child: Text(label, style: AppTextStyles.title),
      ),
    );
  }
}
