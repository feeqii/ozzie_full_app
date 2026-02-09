import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_extensions.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

class SecondaryButton extends StatefulWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.fullWidth = true,
    this.haptic = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final bool haptic;

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
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

    final radius = BorderRadius.circular(AppRadii.lg);
    final translateY = _pressed ? 1.5 : 0.0;

    return SizedBox(
      width: widget.fullWidth ? double.infinity : null,
      child: AnimatedContainer(
        duration: motion.fast,
        curve: motion.standard,
        transform: Matrix4.translationValues(0, translateY, 0),
        decoration: BoxDecoration(
          color: surfaces.card.withValues(alpha: 0.35),
          borderRadius: radius,
          border: Border.all(color: surfaces.outlineStrong.withValues(alpha: 0.55), width: 1.6),
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                child: Center(
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.15,
                          color: scheme.onSurface,
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
}

