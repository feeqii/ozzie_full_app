import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_extensions.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';

enum ActionIconButtonShape { square, round }

class ActionIconButton extends StatefulWidget {
  const ActionIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.shape = ActionIconButtonShape.square,
    this.useInnerShadow = false,
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
    this.haptic = true,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final ActionIconButtonShape shape;
  final bool useInnerShadow;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? iconColor;
  final bool haptic;

  @override
  State<ActionIconButton> createState() => _ActionIconButtonState();
}

class _ActionIconButtonState extends State<ActionIconButton> {
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

    final radius = BorderRadius.circular(
      widget.shape == ActionIconButtonShape.round ? 999 : AppRadii.md,
    );

    final bg = widget.backgroundColor ?? surfaces.card;
    final border = widget.borderColor ?? surfaces.outlineStrong;
    final iconColor = widget.iconColor ?? scheme.onSurface;

    final double translateY = _pressed ? 1.5 : 0;
    final double shadowOffsetY = _pressed ? 2 : 5;

    return AnimatedContainer(
      duration: motion.fast,
      curve: motion.standard,
      transform: Matrix4.translationValues(0, translateY, 0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(color: border, width: 1.6),
        boxShadow: widget.useInnerShadow
            ? AppShadows.inner(color: AppColors.actionInnerShadowBlue, blur: 10)
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
          onTap: widget.onPressed == null
              ? null
              : () {
                  if (widget.haptic) HapticFeedback.selectionClick();
                  widget.onPressed?.call();
                },
          onHighlightChanged: widget.onPressed == null ? null : _setPressed,
          borderRadius: radius,
          overlayColor: WidgetStatePropertyAll(scheme.primary.withValues(alpha: 0.08)),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Icon(widget.icon, color: iconColor, size: 20),
          ),
        ),
      ),
    );
  }
}

