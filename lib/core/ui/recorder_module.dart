import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'action_icon_button.dart';
import 'illustration_frame.dart';
import 'primary_button.dart';

enum RecorderState { idle, recording, review, submitting }

class RecorderModule extends StatelessWidget {
  const RecorderModule({
    super.key,
    required this.state,
    required this.onPrimaryAction,
    this.onSecondaryAction,
    this.durationLabel = '0:06',
  });

  final RecorderState state;
  final VoidCallback onPrimaryAction;
  final VoidCallback? onSecondaryAction;
  final String durationLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const IllustrationFrame(
          child: Icon(Icons.image_outlined, size: 54, color: AppColors.progressTrack),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildActionRow(),
        const SizedBox(height: AppSpacing.md),
        Text(
          _helperText(),
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  Widget _buildActionRow() {
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
            _waveform(),
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
            const SizedBox(width: AppSpacing.lg),
            ActionIconButton(
              icon: Icons.play_arrow,
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

  Widget _waveform() {
    return Container(
      height: 38,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.gamificationLight,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.progressTrack, width: 1),
        boxShadow: AppShadows.soft,
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: Text(
        durationLabel,
        style: AppTextStyles.caption,
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
        return 'Review or record again';
      case RecorderState.submitting:
        return 'Submitting audio';
    }
  }
}
