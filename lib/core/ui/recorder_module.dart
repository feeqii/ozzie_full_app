import 'package:flutter/material.dart';

import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import 'action_icon_button.dart';
import 'atlas_illustrations.dart';
import 'illustration_frame.dart';

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

  static const Color _brandDark = Color(0xFF141413);
  static const Color _brandLight = Color(0xFFFAF9F5);
  static const Color _brandMidGray = Color(0xFFB0AEA5);
  static const Color _brandLightGray = Color(0xFFE8E6DC);
  static const Color _brandOrange = Color(0xFFD97757);
  static const Color _brandGreen = Color(0xFF788C5D);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IllustrationFrame(
          variant: IllustrationFrameVariant.map,
          child: const AtlasIllustration(
            kind: AtlasIllustrationKind.recite,
            primary: _brandDark,
            accent: _brandOrange,
            glow: _brandGreen,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildActionRow(context),
        const SizedBox(height: AppSpacing.md),
        Text(
          _helperText(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: _brandDark.withValues(alpha: 0.62),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow(BuildContext context) {
    switch (state) {
      case RecorderState.idle:
        return ActionIconButton(
          icon: Icons.keyboard_voice_rounded,
          onPressed: onPrimaryAction,
          shape: ActionIconButtonShape.round,
          useInnerShadow: true,
          size: 96,
          iconSize: 44,
          backgroundColor: _brandLight,
          borderColor: _brandDark.withValues(alpha: 0.24),
          iconColor: _brandDark,
          innerShadowColor: _brandOrange.withValues(alpha: 0.78),
          overlayColor: _brandOrange.withValues(alpha: 0.16),
        );
      case RecorderState.recording:
        return Column(
          children: [
            _waveform(context),
            const SizedBox(height: AppSpacing.md),
            ActionIconButton(
              icon: Icons.stop_rounded,
              onPressed: onPrimaryAction,
              shape: ActionIconButtonShape.round,
              useInnerShadow: true,
              size: 96,
              iconSize: 42,
              backgroundColor: _brandLight,
              borderColor: _brandOrange.withValues(alpha: 0.55),
              iconColor: _brandDark,
              innerShadowColor: _brandOrange.withValues(alpha: 0.85),
              overlayColor: _brandOrange.withValues(alpha: 0.2),
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
              size: 62,
              iconSize: 28,
              backgroundColor: _brandLight,
              borderColor: _brandMidGray.withValues(alpha: 0.52),
              iconColor: _brandDark,
              overlayColor: _brandOrange.withValues(alpha: 0.12),
            ),
            const SizedBox(width: AppSpacing.md),
            ActionIconButton(
              icon: Icons.volume_up_rounded,
              onPressed: onListen,
              shape: ActionIconButtonShape.round,
              size: 62,
              iconSize: 28,
              backgroundColor: _brandLight,
              borderColor: _brandMidGray.withValues(alpha: 0.52),
              iconColor: _brandDark,
              overlayColor: _brandOrange.withValues(alpha: 0.12),
            ),
            const SizedBox(width: AppSpacing.md),
            ActionIconButton(
              icon: Icons.check_rounded,
              onPressed: onPrimaryAction,
              shape: ActionIconButtonShape.round,
              useInnerShadow: true,
              size: 72,
              iconSize: 30,
              backgroundColor: _brandLight,
              borderColor: _brandGreen.withValues(alpha: 0.58),
              iconColor: _brandDark,
              innerShadowColor: _brandGreen.withValues(alpha: 0.84),
              overlayColor: _brandGreen.withValues(alpha: 0.18),
            ),
          ],
        );
      case RecorderState.submitting:
        return const SizedBox(
          height: 96,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2.2)),
        );
    }
  }

  Widget _waveform(BuildContext context) {
    return Container(
      height: 38,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _brandLightGray.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: _brandMidGray.withValues(alpha: 0.44),
          width: 1.2,
        ),
        boxShadow: AppShadows.soft,
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: Text(
        durationLabel,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: _brandDark.withValues(alpha: 0.76),
        ),
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
