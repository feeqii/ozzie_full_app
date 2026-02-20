import 'dart:async';

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

class EnterPinScreen extends ConsumerStatefulWidget {
  const EnterPinScreen({super.key});

  @override
  ConsumerState<EnterPinScreen> createState() => _EnterPinScreenState();
}

class _EnterPinScreenState extends ConsumerState<EnterPinScreen> {
  String _pin = '';
  bool _isLoading = false;
  String? _error;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _appendDigit(String digit) {
    if (_pin.length >= 4) {
      return;
    }
    setState(() {
      _pin += digit;
      _error = null;
    });
  }

  void _removeDigit() {
    if (_pin.isEmpty) {
      return;
    }
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  Future<void> _verify() async {
    if (_pin.length < 4) {
      setState(() => _error = 'Enter your 4-digit PIN.');
      return;
    }

    final attempts = ref.read(pinAttemptProvider.notifier);
    if (attempts.isCoolingDown) {
      setState(() => _error = 'Too many attempts. Please wait a moment.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await ref.read(parentProfileProvider.future);
      final pinHash = profile?.pinHash;
      if (pinHash == null || pinHash.isEmpty) {
        if (!mounted) {
          return;
        }
        final setupUri = Uri(
          path: '/parent/pin/setup',
          queryParameters: {'next': _resolvedNextRoute()},
        );
        context.go(setupUri.toString());
        return;
      }

      final valid = PinHash.verifyPin(_pin, pinHash);
      if (!valid) {
        attempts.registerFailure();
        setState(() {
          _pin = '';
          _error = 'Incorrect PIN. Please try again.';
        });
        _startCooldownTickerIfNeeded();
        return;
      }

      attempts.reset();
      ref.read(pinVerifiedProvider.notifier).state = true;

      if (!mounted) {
        return;
      }
      context.go(_resolvedNextRoute());
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not verify PIN. Please try again.');
      }
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

  void _startCooldownTickerIfNeeded() {
    _cooldownTimer?.cancel();
    final controller = ref.read(pinAttemptProvider.notifier);
    if (!controller.isCoolingDown) {
      return;
    }

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      if (!controller.isCoolingDown) {
        _cooldownTimer?.cancel();
      }
      setState(() {});
    });
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
    final attemptState = ref.watch(pinAttemptProvider);
    final cooldownUntil = attemptState.cooldownUntil;
    final cooldownSeconds = cooldownUntil == null
        ? 0
        : cooldownUntil.difference(DateTime.now()).inSeconds.clamp(0, 999);

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
            'hello, parent',
            textAlign: TextAlign.center,
            style: ParentText.heading(
              colors.textPrimary,
            ).copyWith(fontSize: 46),
          ),
          const SizedBox(height: ParentSpacing.xs),
          Text(
            'Confirm your access with your current PIN.',
            textAlign: TextAlign.center,
            style: ParentText.body(colors.textSecondary),
          ),
          if (cooldownSeconds > 0) ...[
            const SizedBox(height: ParentSpacing.sm),
            Text(
              'Try again in $cooldownSeconds seconds.',
              textAlign: TextAlign.center,
              style: ParentText.label(colors.textSecondary),
            ),
          ],
          const SizedBox(height: ParentSpacing.xl),
          ParentPinBoxes(value: _pin),
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
            label: _isLoading ? 'Verifying...' : 'Verify PIN',
            onPressed: _isLoading ? null : _verify,
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
