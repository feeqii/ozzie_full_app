import 'package:flutter/material.dart';

import 'mission_tokens.dart';

enum MissionButtonVariant { primary, outline, danger }

class MissionButton extends StatelessWidget {
  const MissionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = MissionButtonVariant.primary,
    this.leading,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final MissionButtonVariant variant;
  final Widget? leading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final colors = MissionColors.resolve(Theme.of(context).brightness);
    final disabled = onPressed == null;

    final isPrimary = variant == MissionButtonVariant.primary;
    final isDanger = variant == MissionButtonVariant.danger;

    final textColor = isPrimary
        ? colors.primaryText
        : isDanger
        ? MissionPalette.light
        : colors.textPrimary;

    final background = isPrimary
        ? null
        : isDanger
        ? MissionPalette.red
        : colors.surface;

    final borderColor = isPrimary
        ? colors.textPrimary
        : isDanger
        ? MissionPalette.red
        : colors.line;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: Opacity(
        opacity: disabled ? 0.6 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(MissionRadius.md),
            onTap: disabled ? null : onPressed,
            child: Ink(
              decoration: BoxDecoration(
                gradient: isPrimary ? colors.primaryGradient : null,
                color: background,
                borderRadius: BorderRadius.circular(MissionRadius.md),
                border: Border.all(color: borderColor, width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow,
                    blurRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: MissionSpacing.lg,
                vertical: MissionSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: MissionSpacing.sm),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: MissionText.title(
                        textColor,
                      ).copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MissionIconButton extends StatelessWidget {
  const MissionIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = MissionColors.resolve(Theme.of(context).brightness);

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.line, width: 1.2),
            ),
            child: Icon(icon, color: colors.textPrimary, size: 20),
          ),
        ),
      ),
    );
  }
}
