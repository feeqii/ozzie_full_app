import 'package:flutter/material.dart';

import '../theme/onboarding_tokens.dart';

class OnboardingPinDots extends StatelessWidget {
  const OnboardingPinDots({super.key, required this.value, this.length = 4});

  final String value;
  final int length;

  @override
  Widget build(BuildContext context) {
    final colors = OnboardingColors.resolve(Theme.of(context).brightness);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final filled = index < value.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: OnboardingSpacing.xs),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? colors.primary : Colors.transparent,
            border: Border.all(
              color: filled ? colors.primary : colors.border,
              width: 1.4,
            ),
          ),
        );
      }),
    );
  }
}

class OnboardingPinKeypad extends StatelessWidget {
  const OnboardingPinKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'back'],
    ];

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: OnboardingSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key.isEmpty) {
                return const SizedBox(width: 74, height: 58);
              }
              if (key == 'back') {
                return _PinKey(label: '⌫', onTap: onBackspace);
              }
              return _PinKey(label: key, onTap: () => onDigit(key));
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _PinKey extends StatelessWidget {
  const _PinKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = OnboardingColors.resolve(Theme.of(context).brightness);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(OnboardingRadii.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(OnboardingRadii.sm),
        onTap: onTap,
        child: Ink(
          width: 74,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(OnboardingRadii.sm),
            border: Border.all(color: colors.border),
          ),
          child: Center(
            child: Text(
              label,
              style: OnboardingTypography.title(colors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
