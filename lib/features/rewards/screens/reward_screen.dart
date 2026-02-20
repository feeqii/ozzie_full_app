import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../child/ui/mission_buttons.dart';
import '../../child/ui/mission_card.dart';
import '../../child/ui/mission_scaffold.dart';
import '../../child/ui/mission_tokens.dart';
import '../models/reward_event.dart';

class RewardScreen extends StatelessWidget {
  const RewardScreen({super.key, required this.args});

  final RewardScreenArgs args;

  @override
  Widget build(BuildContext context) {
    final colors = MissionColors.resolve(Theme.of(context).brightness);
    final event = args.event;
    final xp = _xpFor(event.type, event.score);

    return MissionScaffold(
      extendToBottom: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: MissionSpacing.xxl),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: MissionCard(
                  padding: const EdgeInsets.all(MissionSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.surface,
                            border: Border.all(
                              color: colors.line.withValues(alpha: 0.65),
                              width: 1.2,
                            ),
                          ),
                          child: Icon(
                            _iconFor(event.type),
                            size: 56,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: MissionSpacing.lg),
                      Text(
                        event.title.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: MissionText.heading(
                          colors.textPrimary,
                        ).copyWith(fontSize: 42),
                      ),
                      const SizedBox(height: MissionSpacing.sm),
                      Text(
                        event.message,
                        textAlign: TextAlign.center,
                        style: MissionText.body(colors.textSecondary),
                      ),
                      const SizedBox(height: MissionSpacing.lg),
                      Text(
                        'You have earned\n$xp Xps (Hasanat)',
                        textAlign: TextAlign.center,
                        style: MissionText.title(
                          colors.textPrimary,
                        ).copyWith(fontSize: 30),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          MissionButton(
            label: args.primaryLabel,
            onPressed: () => context.go(args.primaryRoute),
          ),
          if (args.secondaryLabel != null && args.secondaryRoute != null) ...[
            const SizedBox(height: MissionSpacing.sm),
            MissionButton(
              label: args.secondaryLabel!,
              variant: MissionButtonVariant.outline,
              onPressed: () => context.go(args.secondaryRoute!),
            ),
          ],
          const SizedBox(height: MissionSpacing.md),
        ],
      ),
    );
  }

  int _xpFor(RewardType type, int? score) {
    final base = switch (type) {
      RewardType.hasanat => 180,
      RewardType.badge => 220,
      RewardType.trophy => 300,
    };

    final s = score ?? 80;
    final bonus = switch (s) {
      >= 95 => 70,
      >= 90 => 50,
      >= 80 => 30,
      >= 70 => 20,
      _ => 0,
    };

    return base + bonus;
  }

  IconData _iconFor(RewardType type) {
    switch (type) {
      case RewardType.hasanat:
        return Icons.auto_awesome;
      case RewardType.badge:
        return Icons.verified_outlined;
      case RewardType.trophy:
        return Icons.emoji_events_outlined;
    }
  }
}
