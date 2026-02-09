import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_extensions.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
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
    final surfaces = context.surfaces;
    final scheme = Theme.of(context).colorScheme;

    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: _titleColor(scheme),
        );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: surfaces.sheet.withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: surfaces.outlineStrong.withValues(alpha: 0.18), width: 1.6),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 5,
                  width: 56,
                  decoration: BoxDecoration(
                    color: surfaces.outlineStrong.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (illustration != null) ...[
                  SizedBox(
                    height: 170,
                    child: Center(child: illustration),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: titleStyle,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: bodyStyle,
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
        ),
      ),
    );
  }

  Color _titleColor(ColorScheme scheme) {
    switch (variant) {
      case ModalSheetVariant.success:
        return AppColors.success;
      case ModalSheetVariant.fail:
        return AppColors.danger;
      case ModalSheetVariant.info:
        return scheme.onSurface;
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

