import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/ui/app_app_bar.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/illustration_frame.dart';
import '../../../core/ui/primary_button.dart';
import '../../../core/ui/reward_card.dart';
import '../../../core/ui/secondary_button.dart';
import '../../../core/ui/stat_tile.dart';
import '../models/reward_event.dart';

class RewardScreen extends StatelessWidget {
  const RewardScreen({
    super.key,
    required this.args,
  });

  final RewardScreenArgs args;

  @override
  Widget build(BuildContext context) {
    final event = args.event;
    return AppScaffold(
      appBar: const AppAppBar(title: 'Rewards', showBack: false),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(event.title, style: AppTextStyles.title),
                    const SizedBox(height: AppSpacing.sm),
                    Text(event.message, style: AppTextStyles.body),
                    const SizedBox(height: AppSpacing.xl),
                    Center(
                      child: IllustrationFrame(
                        size: 150,
                        child: Icon(
                          _iconFor(event.type),
                          size: 48,
                          color: AppColors.textNavy,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    RewardCard(
                      title: event.title,
                      subtitle: event.message,
                      variant: _variantFor(event.type),
                    ),
                    if (event.score != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      StatTile(
                        title: 'Score',
                        value: '${event.score}%',
                        variant: StatTileVariant.score,
                      ),
                    ],
                    const Spacer(),
                    PrimaryButton(
                      label: args.primaryLabel,
                      onPressed: () => context.go(args.primaryRoute),
                    ),
                    if (args.secondaryLabel != null && args.secondaryRoute != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      SecondaryButton(
                        label: args.secondaryLabel!,
                        onPressed: () => context.go(args.secondaryRoute!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  RewardCardVariant _variantFor(RewardType type) {
    switch (type) {
      case RewardType.hasanat:
        return RewardCardVariant.hasanat;
      case RewardType.badge:
        return RewardCardVariant.badge;
      case RewardType.trophy:
        return RewardCardVariant.trophy;
    }
  }

  IconData _iconFor(RewardType type) {
    switch (type) {
      case RewardType.hasanat:
        return Icons.brightness_1;
      case RewardType.badge:
        return Icons.emoji_events_outlined;
      case RewardType.trophy:
        return Icons.military_tech_outlined;
    }
  }
}
