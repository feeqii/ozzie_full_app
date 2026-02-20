import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/pin_hash.dart';
import '../../auth/controllers/auth_controller.dart';
import '../providers/parent_profile_provider.dart';
import '../ui/parent_pin_widgets.dart';
import '../ui/parent_scaffold.dart';
import '../ui/parent_tokens.dart';
import '../ui/parent_widgets.dart';

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
      } else if (_pin.length < 4) {
        _pin += digit;
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
      } else if (_pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
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
      setState(() => _error = 'Unable to save PIN right now.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _resolvedNextRoute() {
    final next = GoRouterState.of(context).uri.queryParameters['next'];
    if (next == null || next.isEmpty || !next.startsWith('/')) {
      return '/parent/dashboard';
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
    final colors = ParentColors.resolve(Theme.of(context).brightness);
    final currentValue = _confirmStep ? _confirm : _pin;

    return ParentScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ParentHeaderBar(
            title: 'Parent PIN',
            onBack: () => context.go('/child/home'),
          ),
          const SizedBox(height: ParentSpacing.xl),
          Text(
            _confirmStep ? 'Confirm your PIN' : 'Create your parent PIN',
            textAlign: TextAlign.center,
            style: ParentText.heading(
              colors.textPrimary,
            ).copyWith(fontSize: 40),
          ),
          const SizedBox(height: ParentSpacing.sm),
          Text(
            _confirmStep
                ? 'Enter the same 4 digits to finish setup.'
                : 'This PIN protects all parent-only views and actions.',
            textAlign: TextAlign.center,
            style: ParentText.body(colors.textSecondary),
          ),
          const SizedBox(height: ParentSpacing.xl),
          ParentPinBoxes(value: currentValue),
          if (_error != null) ...[
            const SizedBox(height: ParentSpacing.sm),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: ParentText.label(colors.danger),
            ),
          ],
          const SizedBox(height: ParentSpacing.xl),
          Expanded(
            child: SingleChildScrollView(
              child: ParentPinKeypad(
                onDigit: _appendDigit,
                onBackspace: _removeDigit,
              ),
            ),
          ),
          const SizedBox(height: ParentSpacing.sm),
          ParentPrimaryButton(
            label: _isLoading
                ? 'Saving...'
                : _confirmStep
                ? 'Save PIN'
                : 'Continue',
            onPressed: _isLoading ? null : _continue,
          ),
          const SizedBox(height: ParentSpacing.xs),
          TextButton(
            onPressed: _switchAccount,
            child: Text(
              'Switch account',
              style: ParentText.label(colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
