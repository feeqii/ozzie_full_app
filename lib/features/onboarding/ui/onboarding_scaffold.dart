import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/onboarding_tokens.dart';

class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.child,
    this.showBack = false,
    this.onBack,
    this.trailing,
    this.horizontalPadding = OnboardingSpacing.lg,
  });

  final Widget child;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final colors = OnboardingColors.resolve(Theme.of(context).brightness);

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          Positioned.fill(child: _Backdrop(colors: colors)),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: OnboardingSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TopRow(
                        showBack: showBack,
                        onBack: onBack,
                        trailing: trailing,
                      ),
                      const SizedBox(height: OnboardingSpacing.md),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.showBack,
    required this.onBack,
    required this.trailing,
  });

  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          if (showBack)
            _IconCircleButton(
              icon: Icons.arrow_back_rounded,
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          else
            const SizedBox(width: 42),
          const Spacer(),
          trailing ?? const SizedBox(width: 42),
        ],
      ),
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = OnboardingColors.resolve(Theme.of(context).brightness);

    return Material(
      color: colors.surface.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: colors.textPrimary, size: 20),
        ),
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.colors});

  final OnboardingColors colors;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -160,
          left: -120,
          child: _BlurOrb(size: 300, color: colors.decorationA),
        ),
        Positioned(
          bottom: -180,
          right: -130,
          child: _BlurOrb(size: 340, color: colors.decorationB),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors.background,
                  colors.background.withValues(alpha: 0.95),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
