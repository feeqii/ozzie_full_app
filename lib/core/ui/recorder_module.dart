import 'package:flutter/material.dart';

import '../theme/app_extensions.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import 'action_icon_button.dart';
import 'atlas_illustrations.dart';
import 'illustration_frame.dart';
import 'primary_button.dart';

enum RecorderState { idle, recording, review, submitting }

class RecorderModule extends StatelessWidget {
  const RecorderModule({
    super.key,
    required this.state,
    required this.onPrimaryAction,
    this.onSecondaryAction,
    this.onListen,
    this.durationLabel = '0:06',
  });

  final RecorderState state;
  final VoidCallback onPrimaryAction;
  final VoidCallback? onSecondaryAction;
  final VoidCallback? onListen;
  final String durationLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IllustrationFrame(
          variant: IllustrationFrameVariant.map,
          child: const AtlasIllustration(kind: AtlasIllustrationKind.recite),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildActionRow(context),
        const SizedBox(height: AppSpacing.md),
        Text(
          _helperText(),
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }

  Widget _buildActionRow(BuildContext context) {
    switch (state) {
      case RecorderState.idle:
        return ActionIconButton(
          icon: Icons.mic,
          onPressed: onPrimaryAction,
          shape: ActionIconButtonShape.round,
          useInnerShadow: true,
        );
      case RecorderState.recording:
        return Column(
          children: [
            _waveform(context),
            const SizedBox(height: AppSpacing.md),
            ActionIconButton(
              icon: Icons.stop,
              onPressed: onPrimaryAction,
              shape: ActionIconButtonShape.round,
              useInnerShadow: true,
            ),
          ],
        );
      case RecorderState.review:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ActionIconButton(
              icon: Icons.replay,
              onPressed: onSecondaryAction,
              shape: ActionIconButtonShape.round,
            ),
            const SizedBox(width: AppSpacing.md),
            ActionIconButton(
              icon: Icons.volume_up_rounded,
              onPressed: onListen,
              shape: ActionIconButtonShape.round,
            ),
            const SizedBox(width: AppSpacing.md),
            ActionIconButton(
              icon: Icons.check_rounded,
              onPressed: onPrimaryAction,
              shape: ActionIconButtonShape.round,
              useInnerShadow: true,
            ),
          ],
        );
      case RecorderState.submitting:
        return const PrimaryButton(
          label: 'Submitting...',
          onPressed: null,
          isLoading: true,
        );
    }
  }

  Widget _waveform(BuildContext context) {
    final surfaces = context.surfaces;
    return Container(
      height: 38,
      width: double.infinity,
      decoration: BoxDecoration(
        color: surfaces.cardSubtle.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: context.surfaces.outlineStrong.withValues(alpha: 0.22), width: 1.2),
        boxShadow: AppShadows.soft,
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: Text(
        durationLabel,
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }

  String _helperText() {
    switch (state) {
      case RecorderState.idle:
        return 'Tap to recite';
      case RecorderState.recording:
        return 'Recording...';
      case RecorderState.review:
        return 'Listen, then submit';
      case RecorderState.submitting:
        return 'Submitting audio';
    }
  }
}
