import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/ui/action_icon_button.dart';
import '../../core/ui/illustration_frame.dart';
import '../../core/ui/inline_loader.dart';
import '../../core/ui/full_screen_loader.dart';
import '../../core/ui/app_scaffold.dart';
import '../../core/ui/app_app_bar.dart';
import '../../core/ui/app_text_field.dart';
import '../../core/ui/otp_code_input.dart';
import '../../core/ui/pin_input.dart';
import '../../core/ui/secondary_button.dart';
import '../../core/ui/app_text_button.dart';
import '../../core/ui/alert_banner.dart';
import '../../core/ui/settings_row.dart';
import '../../core/ui/avatar.dart';
import '../../core/ui/child_profile_card.dart';
import '../../core/ui/empty_state.dart';
import '../../core/ui/modal_sheet.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/progress_bar.dart';
import '../../core/ui/quiz_option_card.dart';
import '../../core/ui/recorder_module.dart';
import '../../core/ui/reward_card.dart';
import '../../core/ui/stars_row.dart';
import '../../core/ui/stat_tile.dart';

class DesignSystemGalleryScreen extends StatelessWidget {
  const DesignSystemGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AppAppBar(title: 'Design System Gallery', showBack: false),
      body: ListView(
        children: [
          _sectionTitle('Typography'),
          Text('Display', style: AppTextStyles.display),
          const SizedBox(height: AppSpacing.sm),
          Text('Title', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          Text('Body', style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.sm),
          Text('Caption', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.sm),
          Text('العربية', style: AppTextStyles.arabicTitle),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle('Buttons'),
          PrimaryButton(label: 'Primary', onPressed: () {}),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Success',
            onPressed: () {},
            variant: PrimaryButtonVariant.success,
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Warning',
            onPressed: () {},
            variant: PrimaryButtonVariant.warning,
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Danger',
            onPressed: () {},
            variant: PrimaryButtonVariant.danger,
          ),
          const SizedBox(height: AppSpacing.md),
          const PrimaryButton(label: 'Disabled', isDisabled: true),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(label: 'Secondary', onPressed: () {}),
          const SizedBox(height: AppSpacing.md),
          AppTextButton(label: 'Text Button', onPressed: () {}),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle('Action Icon Buttons'),
          Row(
            children: [
              ActionIconButton(icon: Icons.close, onPressed: () {}),
              const SizedBox(width: AppSpacing.md),
              ActionIconButton(
                icon: Icons.mic,
                onPressed: () {},
                shape: ActionIconButtonShape.round,
                useInnerShadow: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle('Modal Sheet'),
          PrimaryButton(
            label: 'Show Success Modal',
            onPressed: () {
              ModalSheetTrigger.show(
                context,
                sheet: ModalSheet(
                  title: 'Amazing Work 🎉',
                  message: 'One more time to master it.',
                  variant: ModalSheetVariant.success,
                  illustration: const IllustrationFrame(
                    child: Icon(Icons.emoji_events_outlined),
                  ),
                  primaryAction: PrimaryButton(
                    label: 'Next',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle('Progress + Stars'),
          const ProgressBar(value: 0.6),
          const SizedBox(height: AppSpacing.md),
          const StarsRow(total: 6, filled: 3),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle('Inputs'),
          const AppTextField(label: 'Email', hintText: 'name@example.com'),
          const SizedBox(height: AppSpacing.lg),
          const OtpCodeInput(length: 6),
          const SizedBox(height: AppSpacing.lg),
          PinInput(length: 4, onForgotPin: () {}),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle('Quiz Option Card'),
          QuizOptionCard(label: 'Default option', state: QuizOptionState.normal),
          const SizedBox(height: AppSpacing.md),
          QuizOptionCard(label: 'Selected option', state: QuizOptionState.selected),
          const SizedBox(height: AppSpacing.md),
          QuizOptionCard(label: 'Correct option', state: QuizOptionState.correct),
          const SizedBox(height: AppSpacing.md),
          QuizOptionCard(label: 'Wrong option', state: QuizOptionState.wrong),
          const SizedBox(height: AppSpacing.md),
          QuizOptionCard(label: 'Disabled option', state: QuizOptionState.disabled),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle('Recorder Module'),
          const RecorderModule(state: RecorderState.idle, onPrimaryAction: _noop),
          const SizedBox(height: AppSpacing.md),
          const RecorderModule(
            state: RecorderState.recording,
            onPrimaryAction: _noop,
          ),
          const SizedBox(height: AppSpacing.md),
          const RecorderModule(
            state: RecorderState.review,
            onPrimaryAction: _noop,
            onSecondaryAction: _noop,
          ),
          const SizedBox(height: AppSpacing.md),
          const RecorderModule(
            state: RecorderState.submitting,
            onPrimaryAction: _noop,
          ),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle('Reward Cards'),
          const RewardCard(
            title: '200 Hasanat',
            subtitle: 'You earned XP for recitation.',
            variant: RewardCardVariant.hasanat,
          ),
          const SizedBox(height: AppSpacing.md),
          const RewardCard(
            title: 'Golden Crown',
            subtitle: 'New badge unlocked.',
            variant: RewardCardVariant.badge,
          ),
          const SizedBox(height: AppSpacing.md),
          const RewardCard(
            title: 'Gold Trophy',
            subtitle: 'Master quiz completed.',
            variant: RewardCardVariant.trophy,
          ),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle('Stat Tiles'),
          const StatTile(
            title: 'Streak',
            value: '2 Days',
            variant: StatTileVariant.streak,
          ),
          const SizedBox(height: AppSpacing.md),
          const StatTile(
            title: 'Recite Time',
            value: '23 Min',
            variant: StatTileVariant.time,
          ),
          const SizedBox(height: AppSpacing.md),
          const StatTile(
            title: 'Score',
            value: '87%',
            variant: StatTileVariant.score,
          ),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle('Feedback + Loaders'),
          const AlertBanner(
            message: 'Attempts left today: 2',
            variant: AlertBannerVariant.warning,
          ),
          const SizedBox(height: AppSpacing.md),
          const InlineLoader(),
          const SizedBox(height: AppSpacing.md),
          const FullScreenLoader(message: 'Uploading...'),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle('Settings + Profiles'),
          const SettingsRow(label: 'Daily Attempts', value: '6', showChevron: true),
          const SizedBox(height: AppSpacing.md),
          const SettingsRow(
            label: 'Notifications',
            trailing: Switch(value: true, onChanged: _noopBool),
          ),
          const SizedBox(height: AppSpacing.md),
          const Avatar(initials: 'OA'),
          const SizedBox(height: AppSpacing.md),
          const ChildProfileCard(name: 'Ozzie', subtitle: 'Age 7'),
          const SizedBox(height: AppSpacing.md),
          EmptyState(
            title: 'No children yet',
            message: 'Add a child to get started.',
            buttonLabel: 'Add Child',
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle('Illustration Frame'),
          const IllustrationFrame(
            child: Icon(Icons.image_outlined, color: AppColors.progressTrack),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  static Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        title,
        style: AppTextStyles.title,
      ),
    );
  }

  static void _noop() {}

  static void _noopBool(bool value) {}
}
