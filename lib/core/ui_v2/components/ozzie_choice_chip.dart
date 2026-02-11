import 'package:flutter/material.dart';

import '../../theme_v2/ozzie_theme.dart';

class OzzieChoiceChip extends StatelessWidget {
  const OzzieChoiceChip({
    super.key,
    required this.label,
    this.leading,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final Widget? leading;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.ozzieTokens;
    final c = tokens.colors;
    final disabled = onTap == null;

    return Semantics(
      button: true,
      selected: selected,
      enabled: !disabled,
      label: label,
      child: Opacity(
        opacity: disabled ? 0.72 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(tokens.radius.pill),
            onTap: onTap,
            child: AnimatedContainer(
              duration: tokens.motion.fast,
              curve: tokens.motion.standard,
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? c.secondary.withValues(alpha: 0.15)
                    : c.surface,
                borderRadius: BorderRadius.circular(tokens.radius.pill),
                border: Border.all(
                  color: selected ? c.secondary : c.outline,
                  width: selected ? 1.8 : 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 8)],
                  Text(
                    label,
                    style: tokens.type.bodyStrong.copyWith(
                      color: selected ? c.secondaryPressed : c.textPrimary,
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
