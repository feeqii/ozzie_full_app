import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/ui/alert_banner.dart';
import '../../../core/ui/app_app_bar.dart';
import '../../../core/ui/app_card.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/atlas_background.dart';
import '../../../core/ui/illustration_frame.dart';
import '../../../core/ui/inline_loader.dart';
import '../../../core/ui/label_chip.dart';
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
        ModalSheetTrigger.show(
          context,
          sheet: ModalSheet(
            title: 'Try again tomorrow',
            message: 'You have reached the maximum attempts for today.',
            variant: ModalSheetVariant.info,
            illustration: IllustrationFrame(
              size: 150,
              child: Icon(
                Icons.bedtime_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
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
          refreshChildProgress(ref.invalidate, next.childId);
        }

        final passed = next.passed == true;
        if (!passed && next.lockedUntil != null) {
          // Lock-out modal is handled above.
          return;
        }
        ModalSheetTrigger.show(
          context,
          sheet: ModalSheet(
            title: passed ? 'Nice work' : 'Not quite',
            message: passed
                ? 'You answered correctly. Keep going!'
                : 'Review the lesson and try the quiz again.',
            variant: passed
                ? ModalSheetVariant.success
                : ModalSheetVariant.fail,
            illustration: IllustrationFrame(
              size: 150,
              child: Icon(
                passed ? Icons.verified_rounded : Icons.refresh_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
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
            illustration: IllustrationFrame(
              size: 150,
              child: Icon(
                Icons.bedtime_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
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
        contentPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        background: const AtlasBackground(seed: 21),
        body: surahAsync.when(
          data: (surah) {
            if (state.questions.isEmpty) {
              return _emptyQuiz(context);
            }

            final scheme = Theme.of(context).colorScheme;
            final surfaces = context.surfaces;

            final question = state.questions[state.currentIndex];
            final qIndex = state.currentIndex + 1;
            final total = state.questions.length;
            final isRecitePrompt = question.type == QuizQuestionType.recitePrompt;
            final recitePassed = recitation.passed == true;
            final canContinueRecite = !isRecitePrompt || recitePassed;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          LabelChip(
                            label: 'Surah ${surah.id}',
                            background: surfaces.card.withValues(alpha: 0.74),
                            borderColor: surfaces.outlineStrong.withValues(alpha: 0.18),
                            foregroundColor: scheme.onSurface,
                          ),
                          LabelChip(
                            label: 'Q $qIndex/$total',
                            background: scheme.primary.withValues(alpha: 0.14),
                            borderColor: scheme.primary.withValues(alpha: 0.75),
                            foregroundColor: scheme.onSurface,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      StarsRow(total: total, filled: state.currentIndex),
                      const SizedBox(height: AppSpacing.lg),
                      AppCard(
                        variant: AppCardVariant.elevated,
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              question.title.toUpperCase(),
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    letterSpacing: 0.45,
                                    fontWeight: FontWeight.w900,
                                    color: scheme.onSurface.withValues(alpha: 0.7),
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              question.prompt,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            if (question.context != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                question.context!,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurface.withValues(alpha: 0.78),
                                    ),
                              ),
                            ],
                            if (isRecitePrompt) ...[
                              const SizedBox(height: AppSpacing.lg),
                              if (recitation.attemptsLeftToday != null)
                                AlertBanner(
                                  message: '${recitation.attemptsLeftToday} attempts left today',
                                  variant: AlertBannerVariant.warning,
                                ),
                              const SizedBox(height: AppSpacing.md),
                              RecorderModule(
                                state: _mapRecorderState(recitation.stage),
                                onPrimaryAction: () {
                                  switch (recitation.stage) {
                                    case QuizRecitationStage.idle:
                                    case QuizRecitationStage.success:
                                    case QuizRecitationStage.fail:
                                      recitationNotifier.setRecording();
                                      break;
                                    case QuizRecitationStage.recording:
                                      recitationNotifier.stopRecording();
                                      break;
                                    case QuizRecitationStage.review:
                                      recitationNotifier.submitRecording();
                                      break;
                                    case QuizRecitationStage.submitting:
                                    case QuizRecitationStage.lockedOut:
                                      break;
                                  }
                                },
                                onSecondaryAction: () => recitationNotifier.setRecording(),
                                onListen: () => recitationNotifier.playRecording(),
                                durationLabel: recitation.durationLabel,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                recitation.resultSummary(),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: recitation.passed == true
                                          ? scheme.primary
                                          : scheme.onSurface.withValues(alpha: 0.78),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              if (recitation.transcript != null && recitation.transcript!.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  recitation.transcript!,
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                        color: scheme.onSurface.withValues(alpha: 0.72),
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              if (recitation.stage == QuizRecitationStage.fail) ...[
                                const SizedBox(height: AppSpacing.md),
                                PrimaryButton(
                                  label: 'Record again',
                                  variant: PrimaryButtonVariant.warning,
                                  onPressed: () => recitationNotifier.setRecording(),
                                ),
                              ],
                            ] else if (question.hasAudio) ...[
                              const SizedBox(height: AppSpacing.lg),
                              Center(
                                child: Icon(
                                  Icons.volume_up_rounded,
                                  size: 40,
                                  color: scheme.onSurface.withValues(alpha: 0.78),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (question.hasOptions) ...[
                        const SizedBox(height: AppSpacing.lg),
                        for (var index = 0; index < question.options.length; index++) ...[
                          QuizOptionCard(
                            label: question.options[index].label,
                            state: notifier.optionState(question, question.options[index]),
                            onTap: () => notifier.selectOption(
                              question.id,
                              question.options[index].id,
                            ),
                          ),
                          if (index != question.options.length - 1) const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: _primaryLabel(state, question),
                  isDisabled:
                      (question.hasOptions && !state.selections.containsKey(question.id)) || !canContinueRecite,
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
            child: Text(
              'Unable to load quiz.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
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
        return RecorderState.review;
      case QuizRecitationStage.submitting:
        return RecorderState.submitting;
      case QuizRecitationStage.success:
      case QuizRecitationStage.fail:
      case QuizRecitationStage.lockedOut:
        return RecorderState.idle;
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
          Text(
            'Quiz content is not available yet.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
