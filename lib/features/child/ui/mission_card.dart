import 'package:flutter/material.dart';

import 'mission_tokens.dart';

class MissionCard extends StatelessWidget {
  const MissionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(MissionSpacing.lg),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = MissionColors.resolve(Theme.of(context).brightness);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(MissionRadius.md),
        border: Border.all(
          color: colors.line.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: child,
    );
  }
}
