import 'package:flutter/material.dart';

import '../../theme_v2/ozzie_theme.dart';

enum OzzieCardVariant { surface, raised, accent, success, warning, danger }

class OzzieCard extends StatelessWidget {
  const OzzieCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.variant = OzzieCardVariant.surface,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final OzzieCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final tokens = context.ozzieTokens;
    final c = tokens.colors;

    final background = switch (variant) {
      OzzieCardVariant.surface => c.surface,
      OzzieCardVariant.raised => c.surfaceRaised,
      OzzieCardVariant.accent => c.surfaceAccent,
      OzzieCardVariant.success => c.success.withValues(alpha: 0.15),
      OzzieCardVariant.warning => c.warning.withValues(alpha: 0.18),
      OzzieCardVariant.danger => c.danger.withValues(alpha: 0.15),
    };

    final border = switch (variant) {
      OzzieCardVariant.success => c.success.withValues(alpha: 0.45),
      OzzieCardVariant.warning => c.warning.withValues(alpha: 0.5),
      OzzieCardVariant.danger => c.danger.withValues(alpha: 0.4),
      _ => c.outline,
    };

    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(tokens.radius.lg),
        border: Border.all(color: border, width: 1.4),
        boxShadow: tokens.elevation.card,
      ),
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(tokens.radius.lg),
      child: InkWell(
        canRequestFocus: true,
        borderRadius: BorderRadius.circular(tokens.radius.lg),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
