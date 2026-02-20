import 'package:flutter/material.dart';

import 'mission_tokens.dart';

class MissionStatusTag extends StatelessWidget {
  const MissionStatusTag({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = MissionColors.resolve(Theme.of(context).brightness);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MissionSpacing.sm,
        vertical: MissionSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.textPrimary, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: colors.textPrimary),
            const SizedBox(width: MissionSpacing.xs),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textScaler: const TextScaler.linear(1),
            style: MissionText.micro(
              colors.textPrimary,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
