import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
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
    return Column(
      children: [
        const IllustrationFrame(
          child: Icon(Icons.image_outlined, color: AppColors.progressTrack),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(title, style: AppTextStyles.title, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Text(message, style: AppTextStyles.body, textAlign: TextAlign.center),
        if (buttonLabel != null && onPressed != null) ...[
          const SizedBox(height: AppSpacing.lg),
          SecondaryButton(label: buttonLabel!, onPressed: onPressed),
        ],
      ],
    );
  }
}
