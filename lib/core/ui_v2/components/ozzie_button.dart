import 'package:flutter/material.dart';

import '../../theme_v2/ozzie_theme.dart';

enum OzzieButtonVariant { primary, secondary, ghost, danger }

class OzzieButton extends StatefulWidget {
  const OzzieButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = OzzieButtonVariant.primary,
    this.isLoading = false,
    this.fullWidth = true,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final OzzieButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;

  @override
  State<OzzieButton> createState() => _OzzieButtonState();
}

class _OzzieButtonState extends State<OzzieButton> {
  bool _pressed = false;

  bool get _disabled => widget.onPressed == null || widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final tokens = context.ozzieTokens;
    final c = tokens.colors;

    final fg = switch (widget.variant) {
      OzzieButtonVariant.primary => Colors.white,
      OzzieButtonVariant.secondary => Colors.white,
      OzzieButtonVariant.ghost => c.textPrimary,
      OzzieButtonVariant.danger => Colors.white,
    };

    final fillColor = switch (widget.variant) {
      OzzieButtonVariant.primary => c.primary,
      OzzieButtonVariant.secondary => c.secondary,
      OzzieButtonVariant.ghost => c.surface,
      OzzieButtonVariant.danger => c.danger,
    };

    final pressedColor = switch (widget.variant) {
      OzzieButtonVariant.primary => c.primaryPressed,
      OzzieButtonVariant.secondary => c.secondaryPressed,
      OzzieButtonVariant.ghost => c.canvasMuted,
      OzzieButtonVariant.danger => c.danger.withValues(alpha: 0.85),
    };

    final border = switch (widget.variant) {
      OzzieButtonVariant.ghost => c.outlineStrong,
      OzzieButtonVariant.primary => c.primaryPressed,
      OzzieButtonVariant.secondary => c.secondaryPressed,
      OzzieButtonVariant.danger => c.danger.withValues(alpha: 0.9),
    };

    final background = _pressed ? pressedColor : fillColor;
    final minHeight = 56.0;
    final offset = _pressed ? 2.5 : 0.0;
    final shadow = _disabled
        ? const <BoxShadow>[]
        : [
            for (final item in tokens.elevation.button)
              item.copyWith(
                color: item.color.withValues(
                  alpha: _pressed ? 0.2 : item.color.a,
                ),
                offset: Offset(item.offset.dx, _pressed ? 2 : item.offset.dy),
              ),
          ];

    final body = AnimatedContainer(
      duration: tokens.motion.fast,
      curve: tokens.motion.standard,
      transform: Matrix4.translationValues(0, offset, 0),
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        gradient:
            widget.variant == OzzieButtonVariant.primary &&
                !_pressed &&
                !_disabled
            ? c.primaryGradient
            : null,
        color:
            widget.variant == OzzieButtonVariant.primary &&
                !_pressed &&
                !_disabled
            ? null
            : background,
        borderRadius: BorderRadius.circular(tokens.radius.pill),
        border: Border.all(color: border, width: 1.4),
        boxShadow: shadow,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Center(
          child: widget.isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(fg),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 20, color: fg),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: tokens.type.bodyStrong.copyWith(color: fg),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: !_disabled,
      label: widget.label,
      child: Opacity(
        opacity: _disabled ? 0.72 : 1,
        child: SizedBox(
          width: widget.fullWidth ? double.infinity : null,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(tokens.radius.pill),
              onTap: _disabled ? null : widget.onPressed,
              onHighlightChanged: _disabled
                  ? null
                  : (value) => setState(() => _pressed = value),
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}
