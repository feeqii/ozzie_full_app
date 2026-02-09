import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_extensions.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

enum QuizOptionState {
  normal,
  selected,
  correct,
  wrong,
  disabled,
}

class QuizOptionCard extends StatefulWidget {
  const QuizOptionCard({
    super.key,
    required this.label,
    required this.state,
    this.onTap,
    this.trailing,
    this.haptic = true,
  });

  final String label;
  final QuizOptionState state;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool haptic;

  @override
  State<QuizOptionCard> createState() => _QuizOptionCardState();
}

class _QuizOptionCardState extends State<QuizOptionCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    final surfaces = context.surfaces;
    final scheme = Theme.of(context).colorScheme;

    final enabled = widget.state != QuizOptionState.disabled && widget.onTap != null;
    final background = _backgroundColor(surfaces, scheme);
    final border = _borderColor(surfaces, scheme);
    final textColor = _textColor(scheme);

    return AnimatedContainer(
      duration: motion.fast,
      curve: motion.standard,
      transform: Matrix4.translationValues(0, _pressed ? 1.0 : 0.0, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: !enabled
              ? null
              : () {
                  if (widget.haptic) HapticFeedback.selectionClick();
                  widget.onTap?.call();
                },
          onHighlightChanged: enabled ? _setPressed : null,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          overlayColor: WidgetStatePropertyAll(scheme.primary.withValues(alpha: 0.08)),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: border, width: 1.6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (widget.trailing != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  widget.trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _backgroundColor(AppSurfaces surfaces, ColorScheme scheme) {
    switch (widget.state) {
      case QuizOptionState.normal:
        return surfaces.card;
      case QuizOptionState.selected:
        return scheme.primary.withValues(alpha: 0.16);
      case QuizOptionState.correct:
        return AppColors.success.withValues(alpha: 0.18);
      case QuizOptionState.wrong:
        return AppColors.danger.withValues(alpha: 0.16);
      case QuizOptionState.disabled:
        return surfaces.canvasSubtle;
    }
  }

  Color _borderColor(AppSurfaces surfaces, ColorScheme scheme) {
    switch (widget.state) {
      case QuizOptionState.normal:
        return surfaces.outlineStrong.withValues(alpha: 0.24);
      case QuizOptionState.selected:
        return scheme.primary;
      case QuizOptionState.correct:
        return AppColors.success;
      case QuizOptionState.wrong:
        return AppColors.danger;
      case QuizOptionState.disabled:
        return surfaces.outline;
    }
  }

  Color _textColor(ColorScheme scheme) {
    switch (widget.state) {
      case QuizOptionState.disabled:
        return scheme.onSurface.withValues(alpha: 0.45);
      case QuizOptionState.wrong:
      case QuizOptionState.correct:
      case QuizOptionState.selected:
      case QuizOptionState.normal:
        return scheme.onSurface;
    }
  }
}

