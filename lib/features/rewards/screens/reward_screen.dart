import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/ui/app_app_bar.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/atlas_background.dart';
import '../../../core/ui/atlas_illustrations.dart';
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
      contentPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      background: const AtlasBackground(seed: 31),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scheme = Theme.of(context).colorScheme;
          final surfaces = context.surfaces;

          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.displayLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      event.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.78),
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Center(
                      child: IllustrationFrame(
                        size: 150,
                        child: AtlasIllustration(kind: _illustrationFor(event.type)),
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
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: surfaces.card.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: surfaces.outlineStrong.withValues(alpha: 0.14),
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        event.type == RewardType.trophy
                            ? 'A trophy means a big milestone. Take a moment to celebrate, then head back to the map.'
                            : 'Collect rewards by practicing every day. Your progress unlocks new planets and levels.',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.74),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
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

  AtlasIllustrationKind _illustrationFor(RewardType type) {
    switch (type) {
      case RewardType.hasanat:
        return AtlasIllustrationKind.hasanat;
      case RewardType.badge:
        return AtlasIllustrationKind.badge;
      case RewardType.trophy:
        return AtlasIllustrationKind.trophy;
    }
  }
}
