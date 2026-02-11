import 'package:flutter/material.dart';

import '../../theme_v2/ozzie_theme.dart';

class OzzieProgressRail extends StatelessWidget {
  const OzzieProgressRail({
    super.key,
    required this.label,
    required this.value,
    this.trailing,
    this.showPercentWhenTrailingMissing = true,
  });

  final String label;
  final double value;
  final String? trailing;
  final bool showPercentWhenTrailingMissing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.ozzieTokens;
    final c = tokens.colors;
    final normalized = value.isFinite ? value : 0.0;
    final clamped = normalized.clamp(0.0, 1.0).toDouble();
    final trailingLabel =
        trailing ??
        (showPercentWhenTrailingMissing ? '${(clamped * 100).round()}%' : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: tokens.type.label.copyWith(color: c.textPrimary),
              ),
            ),
            if (trailingLabel != null)
              Text(
                trailingLabel,
                style: tokens.type.label.copyWith(color: c.textSecondary),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(tokens.radius.pill),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 12,
            color: c.progressFill,
            backgroundColor: c.progressTrack,
          ),
        ),
      ],
    );
  }
}
