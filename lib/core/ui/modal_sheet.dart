import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'primary_button.dart';

enum ModalSheetVariant { success, fail, info }

class ModalSheet extends StatelessWidget {
  const ModalSheet({
    super.key,
    required this.title,
    required this.message,
    required this.primaryAction,
    this.variant = ModalSheetVariant.info,
    this.illustration,
    this.secondaryAction,
  });

  final String title;
  final String message;
  final PrimaryButton primaryAction;
  final PrimaryButton? secondaryAction;
  final ModalSheetVariant variant;
  final Widget? illustration;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppColors.black, width: 1.4),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustration != null) ...[
              SizedBox(height: 160, child: Center(child: illustration)),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.title.copyWith(color: _titleColor()),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.xl),
            primaryAction,
            if (secondaryAction != null) ...[
              const SizedBox(height: AppSpacing.md),
              secondaryAction!,
            ],
          ],
        ),
      ),
    );
  }

  Color _titleColor() {
    switch (variant) {
      case ModalSheetVariant.success:
        return AppColors.success;
      case ModalSheetVariant.fail:
        return AppColors.danger;
      case ModalSheetVariant.info:
        return AppColors.textNavy;
    }
  }
}

class ModalSheetTrigger {
  const ModalSheetTrigger._();

  static Future<void> show(
    BuildContext context, {
    required ModalSheet sheet,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: sheet,
      ),
    );
  }
}
