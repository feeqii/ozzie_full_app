import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

class FullScreenLoader extends StatelessWidget {
  const FullScreenLoader({
    super.key,
    this.message = 'Loading...'
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white.withValues(alpha: 0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textNavy),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(message, style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }
}
