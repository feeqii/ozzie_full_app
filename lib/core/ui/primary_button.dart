import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_extensions.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

enum PrimaryButtonVariant { primary, success, warning, danger }

class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = PrimaryButtonVariant.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.fullWidth = true,
    this.haptic = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final PrimaryButtonVariant variant;
  final bool isLoading;
  final bool isDisabled;
  final bool fullWidth;
  final bool haptic;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  bool get _disabled => widget.isDisabled || widget.onPressed == null || widget.isLoading;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    final surfaces = context.surfaces;
    final scheme = Theme.of(context).colorScheme;

    final minSize = Size(widget.fullWidth ? double.infinity : 0, 54);
    final radius = BorderRadius.circular(AppRadii.lg);

    final shadowOffsetY = _pressed ? 2.0 : 6.0;
    final translateY = _pressed ? 2.0 : 0.0;

    final gradient = _disabled ? null : _gradient();
    final bgColor = _disabled ? surfaces.canvasSubtle : _solidColor();
    final borderColor = _disabled ? surfaces.outline : _borderColor();

    return SizedBox(
      width: widget.fullWidth ? double.infinity : null,
      child: AnimatedContainer(
        duration: motion.fast,
        curve: motion.standard,
        transform: Matrix4.translationValues(0, translateY, 0),
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: gradient,
          color: gradient == null ? bgColor : null,
          border: Border.all(color: borderColor, width: 1.6),
          boxShadow: _disabled
              ? const []
              : [
                  BoxShadow(
                    color: surfaces.shadow,
                    blurRadius: 0,
                    offset: Offset(0, shadowOffsetY),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _disabled
                ? null
                : () {
                    if (widget.haptic) {
                      HapticFeedback.selectionClick();
                    }
                    widget.onPressed?.call();
                  },
            onHighlightChanged: _disabled ? null : _setPressed,
            borderRadius: radius,
            overlayColor: WidgetStatePropertyAll(
              scheme.onPrimary.withValues(alpha: 0.10),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minSize.height),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                child: Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          widget.label,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: _disabled ? scheme.onSurface.withValues(alpha: 0.55) : scheme.onPrimary,
                                letterSpacing: 0.2,
                              ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient? _gradient() {
    if (widget.variant != PrimaryButtonVariant.primary) return null;
    return AppColors.primaryGradient;
  }

  Color _solidColor() {
    switch (widget.variant) {
      case PrimaryButtonVariant.primary:
        return AppColors.accentPrimary;
      case PrimaryButtonVariant.success:
        return AppColors.success;
      case PrimaryButtonVariant.warning:
        return AppColors.warning;
      case PrimaryButtonVariant.danger:
        return AppColors.danger;
    }
  }

  Color _borderColor() {
    switch (widget.variant) {
      case PrimaryButtonVariant.primary:
        return AppColors.textNavy;
      case PrimaryButtonVariant.success:
        return AppColors.accentSuccess;
      case PrimaryButtonVariant.warning:
        return AppColors.accentWarning;
      case PrimaryButtonVariant.danger:
        return AppColors.danger;
    }
  }
}

