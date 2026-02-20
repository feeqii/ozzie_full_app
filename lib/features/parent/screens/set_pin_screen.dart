import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../onboarding/theme/onboarding_tokens.dart';
import '../../onboarding/ui/onboarding_button.dart';
import '../../onboarding/ui/onboarding_pin_widgets.dart';
import '../../onboarding/ui/onboarding_scaffold.dart';
import '../../onboarding/ui/onboarding_surface_card.dart';
import '../../onboarding/ui/onboarding_theme_toggle.dart';
import '../../../core/utils/pin_hash.dart';
import '../providers/parent_profile_provider.dart';

class SetPinScreen extends ConsumerStatefulWidget {
  const SetPinScreen({super.key});

  @override
  ConsumerState<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends ConsumerState<SetPinScreen> {
  String _pin = '';
  String _confirm = '';
  bool _confirmStep = false;
  bool _isLoading = false;
  String? _error;

  void _appendDigit(String digit) {
    setState(() {
      _error = null;
      if (_confirmStep) {
        if (_confirm.length < 4) {
          _confirm += digit;
        }
      } else {
        if (_pin.length < 4) {
          _pin += digit;
        }
      }
    });
  }

  void _removeDigit() {
    setState(() {
      _error = null;
      if (_confirmStep) {
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
    if (!_confirmStep) {
      if (_pin.length < 4) {
        setState(() => _error = 'Enter a 4-digit PIN.');
        return;
      }
      setState(() {
        _confirmStep = true;
        _error = null;
      });
      return;
    }

    if (_confirm.length < 4) {
      setState(() => _error = 'Confirm your 4-digit PIN.');
      return;
    }

    if (_pin != _confirm) {
      setState(() {
        _error = 'PINs do not match. Try again.';
        _pin = '';
        _confirm = '';
        _confirmStep = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final salt = PinHash.generateSalt();
      final hashed = PinHash.hashPin(_pin, salt);
      await ref.read(parentRepositoryProvider).updatePinHash(hashed);
      ref.invalidate(parentProfileProvider);
      await ref.read(parentProfileProvider.future);
      ref.read(pinVerifiedProvider.notifier).state = true;

      if (!mounted) {
        return;
      }
      context.go(_resolvedNextRoute());
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(
        () => _error = 'Unable to save PIN right now. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _resolvedNextRoute() {
    final next = GoRouterState.of(context).uri.queryParameters['next'];
    if (next == null || next.isEmpty || !next.startsWith('/')) {
      return '/parent/child/select';
    }
    return next;
  }

  Future<void> _switchAccount() async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (mounted) {
      context.go('/auth/entry');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = OnboardingColors.resolve(Theme.of(context).brightness);
    final currentValue = _confirmStep ? _confirm : _pin;

    return OnboardingScaffold(
      showBack: false,
      trailing: const OnboardingThemeToggle(),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _confirmStep
                  ? 'Confirm your parent PIN'
                  : 'Create your parent PIN',
              style: OnboardingTypography.headline(colors.textPrimary),
            ),
            const SizedBox(height: OnboardingSpacing.sm),
            Text(
              _confirmStep
                  ? 'Re-enter the same 4 digits to finish setup.'
                  : 'This PIN protects parent-only actions and keeps child mode focused.',
              style: OnboardingTypography.body(colors.textSecondary),
            ),
            const SizedBox(height: OnboardingSpacing.lg),
            const OnboardingSurfaceCard(child: _PinTip()),
            const SizedBox(height: OnboardingSpacing.lg),
            OnboardingPinDots(value: currentValue),
            if (_error != null) ...[
              const SizedBox(height: OnboardingSpacing.sm),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: OnboardingTypography.label(OnboardingPalette.danger),
              ),
            ],
            const SizedBox(height: OnboardingSpacing.lg),
            OnboardingPinKeypad(
              onDigit: _appendDigit,
              onBackspace: _removeDigit,
            ),
            const SizedBox(height: OnboardingSpacing.md),
            OnboardingButton(
              label: _confirmStep ? 'Save PIN' : 'Continue',
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _continue,
            ),
            const SizedBox(height: OnboardingSpacing.xs),
            OnboardingButton(
              label: 'Switch account',
              variant: OnboardingButtonVariant.text,
              onPressed: _switchAccount,
            ),
          ],
        ),
      ),
    );
  }
}

class _PinTip extends StatelessWidget {
  const _PinTip();

  @override
  Widget build(BuildContext context) {
    final colors = OnboardingColors.resolve(Theme.of(context).brightness);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: OnboardingPalette.blue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(OnboardingRadii.sm),
          ),
          child: const Icon(
            Icons.security_rounded,
            color: OnboardingPalette.blue,
          ),
        ),
        const SizedBox(width: OnboardingSpacing.sm),
        Expanded(
          child: Text(
            'You can reset this PIN anytime by signing out and verifying your account again.',
            style: OnboardingTypography.body(colors.textPrimary),
          ),
        ),
      ],
    );
  }
}
