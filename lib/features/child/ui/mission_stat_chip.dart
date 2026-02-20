import 'package:flutter/material.dart';

import 'mission_tokens.dart';

class MissionStatChip extends StatelessWidget {
  const MissionStatChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = MissionColors.resolve(Theme.of(context).brightness);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(MissionRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MissionRadius.md),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: MissionSpacing.sm,
            vertical: MissionSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MissionRadius.md),
            border: Border.all(
              color: colors.line.withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: colors.textPrimary),
              const SizedBox(width: MissionSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MissionText.micro(colors.textSecondary),
                    ),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MissionText.title(colors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
