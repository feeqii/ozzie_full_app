import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum QuizOptionState {
  normal,
  selected,
  correct,
  wrong,
  disabled,
}

class QuizOptionCard extends StatelessWidget {
  const QuizOptionCard({
    super.key,
    required this.label,
    required this.state,
    this.onTap,
    this.trailing,
  });

  final String label;
  final QuizOptionState state;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final Color background = _backgroundColor();
    final Color border = _borderColor();
    final Color textColor = _textColor();

    return InkWell(
      onTap: state == QuizOptionState.disabled ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: border, width: 1.4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(color: textColor),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }

  Color _backgroundColor() {
    switch (state) {
      case QuizOptionState.normal:
        return AppColors.white;
      case QuizOptionState.selected:
        return AppColors.success.withValues(alpha: 0.35);
      case QuizOptionState.correct:
        return AppColors.success.withValues(alpha: 0.55);
      case QuizOptionState.wrong:
        return AppColors.danger.withValues(alpha: 0.45);
      case QuizOptionState.disabled:
        return AppColors.gamificationLight;
    }
  }

  Color _borderColor() {
    switch (state) {
      case QuizOptionState.normal:
        return AppColors.black;
      case QuizOptionState.selected:
        return AppColors.success;
      case QuizOptionState.correct:
        return AppColors.success;
      case QuizOptionState.wrong:
        return AppColors.danger;
      case QuizOptionState.disabled:
        return AppColors.progressTrack;
    }
  }

  Color _textColor() {
    switch (state) {
      case QuizOptionState.disabled:
        return AppColors.textMuted;
      case QuizOptionState.wrong:
        return AppColors.black;
      case QuizOptionState.correct:
      case QuizOptionState.selected:
      case QuizOptionState.normal:
        return AppColors.textNavy;
    }
  }
}
