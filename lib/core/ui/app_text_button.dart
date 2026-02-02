import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: AppTextStyles.body.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textNavy,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
