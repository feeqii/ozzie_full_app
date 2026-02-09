import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'illustration_frame.dart';
import 'secondary_button.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.onPressed,
  });

  final String title;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        IllustrationFrame(
          variant: IllustrationFrameVariant.standard,
          child: Icon(
            Icons.image_outlined,
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.78),
              ),
          textAlign: TextAlign.center,
        ),
        if (buttonLabel != null && onPressed != null) ...[
          const SizedBox(height: AppSpacing.lg),
          SecondaryButton(
            label: buttonLabel!,
            onPressed: onPressed,
          ),
        ],
      ],
    );
  }
}
