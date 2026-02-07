import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/ui/alert_banner.dart';
import '../../../core/ui/app_app_bar.dart';
import '../../../core/ui/app_card.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/label_chip.dart';
import '../../../core/ui/modal_sheet.dart';
import '../../../core/ui/primary_button.dart';
import '../../../core/ui/recorder_module.dart';
import '../../../core/ui/secondary_button.dart';
import '../../content/providers/content_providers.dart';
import '../../rewards/models/reward_event.dart';
import '../models/recitation_state.dart';
import '../providers/recitation_controller.dart';
import '../../quiz/models/quiz_models.dart';
import '../../progress/providers/progress_refresh.dart';
import '../../progress/widgets/practice_session_boundary.dart';

class RecitationPracticeScreen extends ConsumerStatefulWidget {
  const RecitationPracticeScreen({
    super.key,
    required this.surahId,
    required this.ayahId,
  });

  final int surahId;
  final int ayahId;

  @override
  ConsumerState<RecitationPracticeScreen> createState() => _RecitationPracticeScreenState();
}

class _RecitationPracticeScreenState extends ConsumerState<RecitationPracticeScreen> {
  bool _didRequestPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didRequestPermission) {
        return;
      }
      _didRequestPermission = true;
      final params = RecitationParams(surahId: widget.surahId, ayahId: widget.ayahId);
      ref.read(recitationControllerProvider(params).notifier).ensureMicPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    final surahId = widget.surahId;
    final ayahId = widget.ayahId;
    final surahAsync = ref.watch(surahContentProvider(surahId));
    final params = RecitationParams(surahId: surahId, ayahId: ayahId);
    final controller = ref.watch(
      recitationControllerProvider(params),
    );
    final notifier = ref.read(
      recitationControllerProvider(params).notifier,
    );

    ref.listen(recitationControllerProvider(params), (previous, next) {
      final finishedUpload = previous?.stage == RecitationStage.uploading &&
          next.stage != RecitationStage.uploading &&
          (next.errorMessage == null || next.errorMessage!.isEmpty);
      if (finishedUpload && next.childId.isNotEmpty) {
        refreshChildProgress(ref, next.childId);
      }

      if (previous?.errorMessage != next.errorMessage && next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        ModalSheetTrigger.show(
          context,
          sheet: ModalSheet(
            title: 'Something went wrong',
            message: next.errorMessage!,
            variant: ModalSheetVariant.fail,
            primaryAction: PrimaryButton(
              label: 'Okay',
              onPressed: () => context.pop(),
            ),
          ),
        );
      }
      if (previous?.showMicSettingsPrompt != next.showMicSettingsPrompt && next.showMicSettingsPrompt) {
        ModalSheetTrigger.show(
          context,
          sheet: ModalSheet(
            title: 'Microphone access required',
            message: 'Enable the microphone in Settings to record your recitation.',
            variant: ModalSheetVariant.info,
            primaryAction: PrimaryButton(
              label: 'Open Settings',
              onPressed: () async {
                await openAppSettings();
                if (!context.mounted) return;
                context.pop();
              },
            ),
            secondaryAction: PrimaryButton(
              label: 'Not now',
              onPressed: () => context.pop(),
            ),
          ),
        );
        notifier.clearMicPermissionPrompt();
      }
      if (previous?.rewardEvent != next.rewardEvent && next.rewardEvent != null) {
        final args = RewardScreenArgs(
          event: next.rewardEvent!,
          primaryLabel: 'Continue',
          primaryRoute: '/child/surah/$surahId',
          secondaryLabel: 'Back home',
          secondaryRoute: '/child/home',
        );
        notifier.clearReward();
        context.push('/child/reward', extra: args);
      }
      if (previous?.stage != next.stage && next.stage == RecitationStage.gateToQuiz) {
        final quizType = quizTypeFromGate(next.nextGate);
        final route = quizType == null ? '/child/surah/$surahId' : '/child/surah/$surahId/quiz/${quizType.apiValue}';
        ModalSheetTrigger.show(
          context,
          sheet: ModalSheet(
            title: 'Mini quiz unlocked',
            message: 'Great job! A mini quiz is now ready.',
            variant: ModalSheetVariant.success,
            primaryAction: PrimaryButton(
              label: 'Continue',
              onPressed: () {
                context.pop();
                context.push(route);
              },
            ),
          ),
        );
      }
      if (previous?.stage != next.stage && next.stage == RecitationStage.interventionRequired) {
        ModalSheetTrigger.show(
          context,
          sheet: ModalSheet(
            title: 'Let\'s review first',
            message: 'Listen and read the ayah again before trying.',
            variant: ModalSheetVariant.info,
            primaryAction: PrimaryButton(
              label: 'Back to learn',
              onPressed: () => context.pop(),
            ),
          ),
        );
      }
      if (previous?.stage != next.stage && next.stage == RecitationStage.lockedOut) {
        ModalSheetTrigger.show(
          context,
          sheet: ModalSheet(
            title: 'Try again tomorrow',
            message: 'You have used all attempts for today.',
            variant: ModalSheetVariant.info,
            primaryAction: PrimaryButton(
              label: 'Return home',
              onPressed: () => context.go('/child/home'),
            ),
          ),
        );
      }
    });

    return PracticeSessionBoundary(
      child: AppScaffold(
        appBar: const AppAppBar(title: 'Recitation Practice'),
        body: surahAsync.when(
          data: (surah) {
            final ayah = surah.ayahs.firstWhere((item) => item.id == ayahId, orElse: () => surah.ayahs.first);
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              LabelChip(label: 'Surah $surahId'),
                              const SizedBox(width: AppSpacing.sm),
                              LabelChip(label: 'Ayah $ayahId'),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppCard(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              children: [
                                Text(
                                  controller.shouldBlurVerse ? _blurText(ayah.arabic) : ayah.arabic,
                                  style: AppTextStyles.arabicTitle,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(ayah.translation, style: AppTextStyles.body, textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (controller.attemptsLeftToday != null)
                            AlertBanner(
                              message: '${controller.attemptsLeftToday} attempts left today',
                              variant: AlertBannerVariant.warning,
                            ),
                          const SizedBox(height: AppSpacing.lg),
                          RecorderModule(
                            state: _mapRecorderState(controller.stage),
                            onPrimaryAction: () {
                              switch (controller.stage) {
                                case RecitationStage.idle:
                                  notifier.setRecording();
                                  break;
                                case RecitationStage.recording:
                                  notifier.stopRecording();
                                  break;
                                case RecitationStage.review:
                                  notifier.submitRecording();
                                  break;
                                case RecitationStage.uploading:
                                case RecitationStage.feedbackSuccess:
                                case RecitationStage.feedbackFail:
                                case RecitationStage.interventionRequired:
                                case RecitationStage.lockedOut:
                                case RecitationStage.gateToQuiz:
                                  break;
                              }
                            },
                            onSecondaryAction: () {
                              notifier.playRecording();
                            },
                            durationLabel: controller.durationLabel,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            controller.resultSummary(),
                            style: AppTextStyles.body,
                            textAlign: TextAlign.center,
                          ),
                          const Spacer(),
                          if (controller.stage == RecitationStage.feedbackSuccess ||
                              controller.stage == RecitationStage.feedbackFail)
                            PrimaryButton(
                              label: 'Practice again',
                              onPressed: () => notifier.setRecording(),
                            ),
                          if (controller.stage == RecitationStage.review) ...[
                            PrimaryButton(
                              label: 'Play recording',
                              onPressed: () => notifier.playRecording(),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          if (controller.stage == RecitationStage.feedbackSuccess ||
                              controller.stage == RecitationStage.feedbackFail)
                            const SizedBox(height: AppSpacing.sm),
                          SecondaryButton(
                            label: 'Back to learn',
                            onPressed: () => context.pop(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text('Unable to load recitation.', style: AppTextStyles.body),
          ),
        ),
      ),
    );
  }

  RecorderState _mapRecorderState(RecitationStage stage) {
    switch (stage) {
      case RecitationStage.idle:
        return RecorderState.idle;
      case RecitationStage.recording:
        return RecorderState.recording;
      case RecitationStage.review:
      case RecitationStage.feedbackSuccess:
      case RecitationStage.feedbackFail:
      case RecitationStage.interventionRequired:
        return RecorderState.review;
      case RecitationStage.uploading:
      case RecitationStage.lockedOut:
      case RecitationStage.gateToQuiz:
        return RecorderState.submitting;
    }
  }

  String _blurText(String text) {
    return text.split('').map((char) => char == ' ' ? ' ' : '•').join();
  }
}
