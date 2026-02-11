import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme_v2/ozzie_theme.dart';
import '../../core/ui/action_icon_button.dart';
import '../../core/ui/atlas_background.dart';
import '../../core/ui/atlas_illustrations.dart';
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
import '../../core/ui_v2/components/ozzie_button.dart';
import '../../core/ui_v2/components/ozzie_card.dart';
import '../../core/ui_v2/components/ozzie_choice_chip.dart';
import '../../core/ui_v2/components/ozzie_input.dart';
import '../../core/ui_v2/components/ozzie_progress_rail.dart';
import '../../core/ui_v2/components/ozzie_reward_sheet.dart';
import '../../core/ui_v2/components/ozzie_top_bar.dart';
import '../../core/ui_v2/mascot/ozzie_guide_widget.dart';

class DesignSystemGalleryScreen extends StatelessWidget {
  const DesignSystemGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AppAppBar(title: 'Design System Gallery', showBack: false),
      background: const AtlasBackground(seed: 99, intensity: 0.85),
      body: ListView(
        children: [
          _sectionTitle(context, 'Typography'),
          Text('Display', style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: AppSpacing.sm),
          Text('Title', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text('Body', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Text('Caption', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'العربية',
            style: AppTextStyles.arabicTitle.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildV2FoundationSection(context),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle(context, 'Buttons'),
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
          _sectionTitle(context, 'Action Icon Buttons'),
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
          _sectionTitle(context, 'Modal Sheet'),
          PrimaryButton(
            label: 'Show Success Modal',
            onPressed: () {
              ModalSheetTrigger.show(
                context,
                sheet: ModalSheet(
                  title: 'Amazing work',
                  message: 'One more time to master it.',
                  variant: ModalSheetVariant.success,
                  illustration: const IllustrationFrame(
                    child: AtlasIllustration(
                      kind: AtlasIllustrationKind.success,
                    ),
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
          _sectionTitle(context, 'Progress + Stars'),
          const ProgressBar(value: 0.6),
          const SizedBox(height: AppSpacing.md),
          const StarsRow(total: 6, filled: 3),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle(context, 'Inputs'),
          const AppTextField(label: 'Email', hintText: 'name@example.com'),
          const SizedBox(height: AppSpacing.lg),
          const OtpCodeInput(length: 6),
          const SizedBox(height: AppSpacing.lg),
          PinInput(length: 4, onForgotPin: () {}),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle(context, 'Quiz Option Card'),
          QuizOptionCard(
            label: 'Default option',
            state: QuizOptionState.normal,
          ),
          const SizedBox(height: AppSpacing.md),
          QuizOptionCard(
            label: 'Selected option',
            state: QuizOptionState.selected,
          ),
          const SizedBox(height: AppSpacing.md),
          QuizOptionCard(
            label: 'Correct option',
            state: QuizOptionState.correct,
          ),
          const SizedBox(height: AppSpacing.md),
          QuizOptionCard(label: 'Wrong option', state: QuizOptionState.wrong),
          const SizedBox(height: AppSpacing.md),
          QuizOptionCard(
            label: 'Disabled option',
            state: QuizOptionState.disabled,
          ),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle(context, 'Recorder Module'),
          const RecorderModule(
            state: RecorderState.idle,
            onPrimaryAction: _noop,
          ),
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
            onListen: _noop,
          ),
          const SizedBox(height: AppSpacing.md),
          const RecorderModule(
            state: RecorderState.submitting,
            onPrimaryAction: _noop,
          ),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle(context, 'Reward Cards'),
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
          _sectionTitle(context, 'Stat Tiles'),
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
          _sectionTitle(context, 'Feedback + Loaders'),
          const AlertBanner(
            message: 'Attempts left today: 2',
            variant: AlertBannerVariant.warning,
          ),
          const SizedBox(height: AppSpacing.md),
          const InlineLoader(),
          const SizedBox(height: AppSpacing.md),
          const FullScreenLoader(message: 'Uploading...'),
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle(context, 'Settings + Profiles'),
          const SettingsRow(
            label: 'Daily Attempts',
            value: '6',
            showChevron: true,
          ),
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
          _sectionTitle(context, 'Illustration Frame'),
          const IllustrationFrame(
            child: AtlasIllustration(kind: AtlasIllustrationKind.quiz),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildV2FoundationSection(BuildContext context) {
    return Theme(
      data: OzzieTheme.childLight(),
      child: Builder(
        builder: (v2Context) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionTitle(v2Context, 'V2 Foundation'),
              const OzzieTopBar(title: 'Star Path', subtitle: 'V2 Preview'),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Display XL',
                style: v2Context.ozzieTokens.type.displayXL.copyWith(
                  color: v2Context.ozzieTokens.colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Readable body copy for kids and parents.',
                style: v2Context.ozzieTokens.type.body.copyWith(
                  color: v2Context.ozzieTokens.colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OzzieCard(
                variant: OzzieCardVariant.raised,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    OzzieProgressRail(label: 'Session progress', value: 0.63),
                    SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        OzzieChoiceChip(label: 'Warm-up', selected: true),
                        OzzieChoiceChip(label: 'Quiz'),
                        OzzieChoiceChip(label: 'Recite'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const OzzieInput(
                label: 'Mission title',
                hint: 'Read Surah Al-Fatihah',
              ),
              const SizedBox(height: AppSpacing.md),
              OzzieButton(
                label: 'Primary action',
                icon: Icons.rocket_launch_rounded,
                onPressed: () {},
              ),
              const SizedBox(height: AppSpacing.sm),
              OzzieButton(
                label: 'Secondary action',
                variant: OzzieButtonVariant.secondary,
                onPressed: () {},
              ),
              const SizedBox(height: AppSpacing.sm),
              const OzzieButton(
                label: 'Ghost disabled',
                variant: OzzieButtonVariant.ghost,
                onPressed: null,
              ),
              const SizedBox(height: AppSpacing.md),
              OzzieButton(
                label: 'Preview reward sheet',
                icon: Icons.auto_awesome_rounded,
                onPressed: () => _showV2RewardSheet(v2Context),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: const [
                  OzzieGuideWidget(width: 72, height: 72, enableRive: false),
                  SizedBox(width: AppSpacing.md),
                  OzzieGuideWidget(width: 72, height: 72),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<void> _showV2RewardSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return const OzzieRewardSheet(
          title: 'Mission complete',
          message: 'You unlocked a new star for today.',
        );
      },
    );
  }

  static Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
    );
  }

  static void _noop() {}

  static void _noopBool(bool value) {}
}
