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

class SetPinScreen extends ConsumerStatefulWidget {
  const SetPinScreen({super.key});

  @override
  ConsumerState<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends ConsumerState<SetPinScreen> {
  String _pin = '';
  String _confirm = '';
  bool _isConfirmStep = false;
  bool _isLoading = false;

  void _appendDigit(String digit) {
    if (_isConfirmStep) {
      if (_confirm.length >= 4) return;
      setState(() {
        _confirm += digit;
      });
    } else {
      if (_pin.length >= 4) return;
      setState(() {
        _pin += digit;
      });
    }
  }

  void _removeDigit() {
    setState(() {
      if (_isConfirmStep) {
        if (_confirm.isNotEmpty) {
          _confirm = _confirm.substring(0, _confirm.length - 1);
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    });
  }

  Future<void> _continue() async {
    if (!_isConfirmStep) {
      if (_pin.length < 4) {
        AppSnackbar.show(context, message: 'Enter a 4-digit PIN.');
        return;
      }
      setState(() {
        _isConfirmStep = true;
      });
      return;
    }

    if (_confirm.length < 4) {
      AppSnackbar.show(context, message: 'Confirm your 4-digit PIN.');
      return;
    }

    if (_pin != _confirm) {
      AppSnackbar.show(context, message: 'PINs do not match. Try again.', isError: true);
      setState(() {
        _pin = '';
        _confirm = '';
        _isConfirmStep = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final salt = PinHash.generateSalt();
      final hashed = PinHash.hashPin(_pin, salt);
      await ref.read(parentRepositoryProvider).updatePinHash(hashed);
      ref.invalidate(parentProfileProvider);
      await ref.read(parentProfileProvider.future);
      ref.read(pinVerifiedProvider.notifier).state = true;
      if (mounted) {
        context.go('/parent/child/select');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackbar.show(context, message: 'Unable to save PIN. Try again.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isConfirmStep ? 'Confirm PIN' : 'Create PIN';
    final message = _isConfirmStep
        ? 'Re-enter your 4-digit PIN.'
        : 'Create a 4-digit PIN to secure parental access.';

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
                    Text(title, style: AppTextStyles.title, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.sm),
                    Text(message, style: AppTextStyles.body, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.xl),
                    PinInput(
                      length: 4,
                      value: _isConfirmStep ? _confirm : _pin,
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
                      label: _isConfirmStep ? 'Save PIN' : 'Continue',
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _continue,
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
