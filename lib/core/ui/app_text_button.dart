import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.label,
    this.onPressed,
    this.haptic = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool haptic;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TextButton(
      onPressed: onPressed == null
          ? null
          : () {
              if (haptic) HapticFeedback.selectionClick();
              onPressed?.call();
            },
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.underline,
              decorationColor: scheme.primary.withValues(alpha: 0.65),
              decorationThickness: 2,
            ),
      ),
    );
  }
}
