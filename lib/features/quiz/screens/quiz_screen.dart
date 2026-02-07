import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/ui/alert_banner.dart';
import '../../../core/ui/action_icon_button.dart';
import '../../../core/ui/app_app_bar.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/inline_loader.dart';
import '../../../core/ui/modal_sheet.dart';
import '../../../core/ui/primary_button.dart';
import '../../../core/ui/quiz_option_card.dart';
import '../../../core/ui/recorder_module.dart';
import '../../../core/ui/stars_row.dart';
import '../../content/providers/content_providers.dart';
import '../../progress/providers/progress_refresh.dart';
import '../../progress/widgets/practice_session_boundary.dart';
import '../../rewards/models/reward_event.dart';
import '../models/quiz_models.dart';
import '../providers/quiz_controller.dart';
import '../providers/quiz_recitation_controller.dart';
import '../models/quiz_recitation_state.dart';

class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key, required this.surahId, required this.quizType});

  final int surahId;
  final QuizType quizType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahAsync = ref.watch(surahContentProvider(surahId));
    final params = QuizParams(surahId: surahId, quizType: quizType);
    final state = ref.watch(quizControllerProvider(params));
    final notifier = ref.read(quizControllerProvider(params).notifier);
    final recitationParams = QuizRecitationParams(
      surahId: surahId,
      quizType: quizType,
    );
    final recitation = ref.watch(
      quizRecitationControllerProvider(recitationParams),
    );
    final recitationNotifier = ref.read(
      quizRecitationControllerProvider(recitationParams).notifier,
    );

    ref.listen(quizControllerProvider(params), (previous, next) {
      if (previous?.errorMessage != next.errorMessage &&
          next.errorMessage != null &&
          next.errorMessage!.isNotEmpty) {
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

      if (previous?.rewardEvent != next.rewardEvent &&
          next.rewardEvent != null) {
        final event = next.rewardEvent!;
        final isFinal = event.type == RewardType.trophy;
        final args = RewardScreenArgs(
          event: event,
          primaryLabel: isFinal ? 'Back home' : 'Continue',
          primaryRoute: isFinal ? '/child/home' : '/child/surah/$surahId',
          secondaryLabel: 'Back to journey',
          secondaryRoute: '/child/surah/$surahId',
        );
        notifier.clearReward();
        context.push('/child/reward', extra: args);
        return;
      }

      if (previous?.lockedUntil != next.lockedUntil &&
          next.lockedUntil != null) {
        final lockedUntil = next.lockedUntil!;
        ModalSheetTrigger.show(
          context,
          sheet: ModalSheet(
            title: 'Try again tomorrow',
            message: 'You have reached the maximum attempts for today.',
            variant: ModalSheetVariant.info,
            primaryAction: PrimaryButton(
              label: 'Back home',
              onPressed: () => context.go('/child/home'),
            ),
          ),
        );
        return;
      }

      final justCompleted =
          previous?.isSubmitting == true &&
          next.isSubmitting == false &&
          next.score != null;
      if (justCompleted) {
        if (next.childId.isNotEmpty) {
          refreshChildProgress(ref, next.childId);
        }

        final passed = next.passed == true;
        if (!passed && next.lockedUntil != null) {
          // Lock-out modal is handled above.
          return;
        }
        ModalSheetTrigger.show(
          context,
          sheet: ModalSheet(
            title: passed ? 'Good job 🎉' : 'Let\'s try again',
            message: passed
                ? 'You answered correctly. Keep going!'
                : 'Review the lesson and try the quiz again.',
            variant: passed
                ? ModalSheetVariant.success
                : ModalSheetVariant.fail,
            primaryAction: PrimaryButton(
              label: passed ? 'Continue' : 'Try again',
              onPressed: () {
                context.pop();
                if (passed) {
                  context.pop();
                } else {
                  recitationNotifier.reset();
                  notifier.resetQuiz();
                }
              },
            ),
          ),
        );
      }
    });

    ref.listen(quizRecitationControllerProvider(recitationParams), (
      previous,
      next,
    ) {
      if (previous?.errorMessage != next.errorMessage &&
          next.errorMessage != null &&
          next.errorMessage!.isNotEmpty) {
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

      if (previous?.showMicSettingsPrompt != next.showMicSettingsPrompt &&
          next.showMicSettingsPrompt) {
        ModalSheetTrigger.show(
          context,
          sheet: ModalSheet(
            title: 'Microphone access required',
            message:
                'Enable the microphone in Settings to record your recitation.',
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
        recitationNotifier.clearMicPermissionPrompt();
      }

      final lockedUntil = next.lockedUntil;
      if (previous?.lockedUntil != lockedUntil &&
          lockedUntil != null &&
          lockedUntil.isAfter(DateTime.now())) {
        ModalSheetTrigger.show(
          context,
          sheet: ModalSheet(
            title: 'Try again tomorrow',
            message: 'You have used all attempts for today.',
            variant: ModalSheetVariant.info,
            primaryAction: PrimaryButton(
              label: 'Back home',
              onPressed: () => context.go('/child/home'),
            ),
          ),
        );
      }
    });

    return PracticeSessionBoundary(
      child: AppScaffold(
        appBar: AppAppBar(title: quizType.label),
        body: surahAsync.when(
          data: (surah) {
          if (state.questions.isEmpty) {
            return _emptyQuiz(context);
          }

          final question = state.questions[state.currentIndex];
          final isRecitePrompt = question.type == QuizQuestionType.recitePrompt;
          final recitePassed = recitation.passed == true;
          final canContinueRecite = !isRecitePrompt || recitePassed;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ActionIconButton(
                    icon: Icons.arrow_back,
                    shape: ActionIconButtonShape.round,
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  Text('Surah ${surah.id}', style: AppTextStyles.caption),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              StarsRow(
                total: state.questions.length,
                filled: state.currentIndex,
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.gamificationLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      question.title.toUpperCase(),
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(question.prompt, style: AppTextStyles.title),
                    if (question.context != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(question.context!, style: AppTextStyles.body),
                    ],
                    if (isRecitePrompt) ...[
                      const SizedBox(height: AppSpacing.lg),
                      if (recitation.attemptsLeftToday != null)
                        AlertBanner(
                          message:
                              '${recitation.attemptsLeftToday} attempts left today',
                          variant: AlertBannerVariant.warning,
                        ),
                      const SizedBox(height: AppSpacing.md),
                      RecorderModule(
                        state: _mapRecorderState(recitation.stage),
                        onPrimaryAction: () {
                          switch (recitation.stage) {
                            case QuizRecitationStage.idle:
                              recitationNotifier.setRecording();
                              break;
                            case QuizRecitationStage.recording:
                              recitationNotifier.stopRecording();
                              break;
                            case QuizRecitationStage.review:
                              recitationNotifier.submitRecording();
                              break;
                            case QuizRecitationStage.submitting:
                            case QuizRecitationStage.success:
                            case QuizRecitationStage.fail:
                            case QuizRecitationStage.lockedOut:
                              break;
                          }
                        },
                        onSecondaryAction: () =>
                            recitationNotifier.playRecording(),
                        durationLabel: recitation.durationLabel,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        recitation.resultSummary(),
                        style: AppTextStyles.body,
                        textAlign: TextAlign.center,
                      ),
                      if (recitation.transcript != null &&
                          recitation.transcript!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          recitation.transcript!,
                          style: AppTextStyles.caption,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (recitation.stage == QuizRecitationStage.fail) ...[
                        const SizedBox(height: AppSpacing.md),
                        PrimaryButton(
                          label: 'Record again',
                          onPressed: () => recitationNotifier.setRecording(),
                        ),
                      ],
                    ] else if (question.hasAudio) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: Icon(
                          Icons.volume_up,
                          size: 40,
                          color: AppColors.textNavy,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (question.hasOptions)
                Expanded(
                  child: ListView.separated(
                    itemCount: question.options.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final option = question.options[index];
                      return QuizOptionCard(
                        label: option.label,
                        state: notifier.optionState(question, option),
                        onTap: () =>
                            notifier.selectOption(question.id, option.id),
                      );
                    },
                  ),
                ),
              if (!question.hasOptions) const Spacer(),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: _primaryLabel(state, question),
                isDisabled:
                    (question.hasOptions &&
                        !state.selections.containsKey(question.id)) ||
                    !canContinueRecite,
                isLoading: state.isSubmitting,
                onPressed: () async {
                  if (isRecitePrompt) {
                    if (!canContinueRecite) {
                      return;
                    }
                    if (state.currentIndex < state.questions.length - 1) {
                      notifier.nextQuestion();
                      return;
                    }
                    await notifier.submitQuiz();
                    return;
                  }
                  if (!state.showFeedback) {
                    await notifier.submitCurrentAnswer();
                    return;
                  }
                  if (!notifier.isLastQuestion) {
                    notifier.nextQuestion();
                    return;
                  }
                  await notifier.submitQuiz();
                },
              ),
            ],
          );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text('Unable to load quiz.', style: AppTextStyles.body),
          ),
        ),
      ),
    );
  }

  RecorderState _mapRecorderState(QuizRecitationStage stage) {
    switch (stage) {
      case QuizRecitationStage.idle:
        return RecorderState.idle;
      case QuizRecitationStage.recording:
        return RecorderState.recording;
      case QuizRecitationStage.review:
      case QuizRecitationStage.success:
      case QuizRecitationStage.fail:
        return RecorderState.review;
      case QuizRecitationStage.submitting:
      case QuizRecitationStage.lockedOut:
        return RecorderState.submitting;
    }
  }

  String _primaryLabel(QuizState state, QuizQuestion question) {
    if (state.isSubmitting) {
      return 'Submitting';
    }
    if (!state.showFeedback) {
      return question.hasOptions ? 'Check answer' : 'Continue';
    }
    if (state.currentIndex < state.questions.length - 1) {
      return 'Next question';
    }
    return 'Finish quiz';
  }

  Widget _emptyQuiz(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const InlineLoader(),
          const SizedBox(height: AppSpacing.md),
          Text('Quiz content is not available yet.', style: AppTextStyles.body),
        ],
      ),
    );
  }
}
