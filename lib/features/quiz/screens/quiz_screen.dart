import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/ui/recorder_module.dart';
import '../../../core/ui/quiz_option_card.dart';
import '../../child/ui/lesson_widgets.dart';
import '../../child/ui/mission_buttons.dart';
import '../../child/ui/mission_card.dart';
import '../../child/ui/mission_scaffold.dart';
import '../../child/ui/mission_tokens.dart';
import '../../content/providers/content_providers.dart';
import '../../progress/providers/progress_refresh.dart';
import '../../progress/widgets/practice_session_boundary.dart';
import '../../rewards/models/reward_event.dart';
import '../models/quiz_models.dart';
import '../models/quiz_recitation_state.dart';
import '../providers/quiz_controller.dart';
import '../providers/quiz_recitation_controller.dart';

class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key, required this.surahId, required this.quizType});

  final int surahId;
  final QuizType quizType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = MissionColors.resolve(Theme.of(context).brightness);
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
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }

      if (previous?.rewardEvent != next.rewardEvent &&
          next.rewardEvent != null) {
        HapticFeedback.mediumImpact();
        final event = next.rewardEvent!;
        final isFinal = event.type == RewardType.trophy;
        final args = RewardScreenArgs(
          event: event,
          primaryLabel: isFinal ? 'Back to ayat flow' : 'Continue',
          primaryRoute: isFinal
              ? '/child/surah/$surahId/journey'
              : '/child/surah/$surahId/journey',
          secondaryLabel: 'Back home',
          secondaryRoute: '/child/home',
        );
        notifier.clearReward();
        context.push('/child/reward', extra: args);
        return;
      }

      if (previous?.lockedUntil != next.lockedUntil &&
          next.lockedUntil != null) {
        HapticFeedback.mediumImpact();
        _showInfoSheet(
          context,
          title: 'Try again tomorrow',
          message: 'You used all attempts for this quiz today.',
          primaryLabel: 'Back to ayat flow',
          onPrimary: () {
            context.pop();
            context.go('/child/surah/$surahId/journey');
          },
        );
        return;
      }

      final feedbackTriggered =
          previous?.showFeedback != true && next.showFeedback;
      if (feedbackTriggered && next.questions.isNotEmpty) {
        final question = next.questions[next.currentIndex];
        if (question.hasOptions) {
          final correct = notifier.isCorrectSelection(question);
          if (correct) {
            HapticFeedback.mediumImpact();
            showLessonFeedbackSheet(
              context: context,
              sheet: LessonFeedbackSheet(
                title: 'Good job',
                message: 'You answered correctly',
                emphasis: 'Lets have another one',
                primaryLabel: 'Next',
                onPrimary: () async {
                  context.pop();
                  if (notifier.isLastQuestion) {
                    await notifier.submitQuiz();
                    return;
                  }
                  notifier.nextQuestion();
                },
              ),
            );
          } else {
            HapticFeedback.lightImpact();
            final style = next.wrongFeedbackStyle;
            final showAnswer = style == QuizWrongFeedbackStyle.detailed;
            final correctOption = question.options.firstWhere(
              (option) => option.id == question.correctOptionId,
              orElse: () => const QuizQuestionOption(id: '', label: ''),
            );

            showLessonFeedbackSheet(
              context: context,
              sheet: LessonFeedbackSheet(
                title: 'Incorrect',
                titleColor: const Color(0xFFCF6660),
                message: showAnswer
                    ? 'Try again with the correct phrase.'
                    : 'You can do this. Give it another shot.',
                detailLabel: showAnswer ? 'Correct answer is' : null,
                detailValue: showAnswer ? correctOption.label : null,
                primaryLabel: 'Try again',
                onPrimary: () {
                  context.pop();
                  notifier.retryCurrentQuestion(clearSelection: true);
                },
              ),
            );
          }
        }
      }

      final justCompleted =
          previous?.isSubmitting == true &&
          next.isSubmitting == false &&
          next.score != null;
      if (justCompleted && next.rewardEvent == null) {
        if (next.childId.isNotEmpty) {
          refreshChildProgress(ref.invalidate, next.childId);
        }

        final passed = next.passed == true;
        if (passed) {
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.lightImpact();
        }

        _showInfoSheet(
          context,
          title: passed ? 'Perfect' : 'Almost',
          message: passed
              ? 'Mission checkpoint complete.'
              : 'Review and try this checkpoint again.',
          primaryLabel: passed ? 'Back to ayat flow' : 'Try again',
          onPrimary: () {
            context.pop();
            if (passed) {
              context.go('/child/surah/$surahId/journey');
              return;
            }
            recitationNotifier.reset();
            notifier.resetQuiz();
          },
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
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }

      if (previous?.showMicSettingsPrompt != next.showMicSettingsPrompt &&
          next.showMicSettingsPrompt) {
        HapticFeedback.selectionClick();
        _showInfoSheet(
          context,
          title: 'Microphone access required',
          message: 'Enable the microphone in Settings to record.',
          primaryLabel: 'Open settings',
          onPrimary: () async {
            await openAppSettings();
            if (context.mounted) {
              context.pop();
            }
          },
          secondaryLabel: 'Not now',
          onSecondary: () => context.pop(),
        );
        recitationNotifier.clearMicPermissionPrompt();
      }

      final lockedUntil = next.lockedUntil;
      if (previous?.lockedUntil != lockedUntil &&
          lockedUntil != null &&
          lockedUntil.isAfter(DateTime.now())) {
        HapticFeedback.mediumImpact();
        _showInfoSheet(
          context,
          title: 'Try again tomorrow',
          message: 'Recitation attempts are done for today.',
          primaryLabel: 'Back to ayat flow',
          onPrimary: () {
            context.pop();
            context.go('/child/surah/$surahId/journey');
          },
        );
      }
    });

    return PracticeSessionBoundary(
      child: MissionScaffold(
        extendToBottom: true,
        child: surahAsync.when(
          data: (surah) {
            if (state.questions.isEmpty) {
              return Center(
                child: Text(
                  'Quiz content is not available yet.',
                  style: MissionText.body(colors.textSecondary),
                ),
              );
            }

            final question = state.questions[state.currentIndex];
            final isRecitePrompt =
                question.type == QuizQuestionType.recitePrompt;
            final recitePassed = recitation.passed == true;
            final canContinueRecite = !isRecitePrompt || recitePassed;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LessonNavBar(
                  title: '${surah.name} - ${quizType.label}',
                  leadingIcon: Icons.close_rounded,
                  onLeadingTap: () =>
                      context.go('/child/surah/$surahId/journey'),
                ),
                const SizedBox(height: MissionSpacing.md),
                LessonStarsBar(
                  total: 6,
                  filled: _filledStars(state.currentIndex),
                ),
                const SizedBox(height: MissionSpacing.md),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: MissionSpacing.xxl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MissionCard(
                          padding: const EdgeInsets.all(MissionSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                question.title.toUpperCase(),
                                style: MissionText.label(colors.textSecondary),
                              ),
                              const SizedBox(height: MissionSpacing.xs),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      question.prompt,
                                      style: MissionText.heading(
                                        colors.textPrimary,
                                      ).copyWith(fontSize: 44),
                                    ),
                                  ),
                                  if (question.hasAudio)
                                    MissionIconButton(
                                      icon: Icons.volume_up_rounded,
                                      onPressed: () {
                                        // TODO(quiz-audio): wire question-level voice prompt playback.
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Question audio placeholder.',
                                            ),
                                          ),
                                        );
                                      },
                                      semanticLabel: 'Play question audio',
                                    ),
                                ],
                              ),
                              if (question.context != null) ...[
                                const SizedBox(height: MissionSpacing.sm),
                                Container(
                                  height: 1,
                                  color: colors.line.withValues(alpha: 0.45),
                                ),
                                const SizedBox(height: MissionSpacing.sm),
                                Text(
                                  question.context!,
                                  style: MissionText.body(colors.textSecondary),
                                ),
                              ],
                              if (isRecitePrompt) ...[
                                const SizedBox(height: MissionSpacing.md),
                                RecorderModule(
                                  state: _mapRecorderState(recitation.stage),
                                  onPrimaryAction: () {
                                    switch (recitation.stage) {
                                      case QuizRecitationStage.idle:
                                      case QuizRecitationStage.success:
                                      case QuizRecitationStage.fail:
                                        HapticFeedback.selectionClick();
                                        recitationNotifier.setRecording();
                                        break;
                                      case QuizRecitationStage.recording:
                                        HapticFeedback.lightImpact();
                                        recitationNotifier.stopRecording();
                                        break;
                                      case QuizRecitationStage.review:
                                        HapticFeedback.selectionClick();
                                        recitationNotifier.submitRecording();
                                        break;
                                      case QuizRecitationStage.submitting:
                                      case QuizRecitationStage.lockedOut:
                                        break;
                                    }
                                  },
                                  onSecondaryAction: () {
                                    HapticFeedback.selectionClick();
                                    recitationNotifier.setRecording();
                                  },
                                  onListen: () {
                                    HapticFeedback.selectionClick();
                                    recitationNotifier.playRecording();
                                  },
                                  durationLabel: recitation.durationLabel,
                                ),
                                const SizedBox(height: MissionSpacing.xs),
                                Text(
                                  recitation.resultSummary(),
                                  textAlign: TextAlign.center,
                                  style: MissionText.micro(
                                    colors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (!isRecitePrompt) ...[
                          const SizedBox(height: MissionSpacing.md),
                          if (question.type == QuizQuestionType.completeVerse)
                            _CompleteVerseGrid(
                              question: question,
                              notifier: notifier,
                            )
                          else
                            Column(
                              children: [
                                for (
                                  var index = 0;
                                  index < question.options.length;
                                  index++
                                ) ...[
                                  _LessonOptionTile(
                                    option: question.options[index],
                                    state: notifier.optionState(
                                      question,
                                      question.options[index],
                                    ),
                                    leadingLabel:
                                        '${String.fromCharCode(65 + index)})',
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      notifier.selectOption(
                                        question.id,
                                        question.options[index].id,
                                      );
                                    },
                                  ),
                                  if (index != question.options.length - 1)
                                    const SizedBox(height: MissionSpacing.sm),
                                ],
                              ],
                            ),
                        ],
                        const SizedBox(height: MissionSpacing.lg),
                        MissionButton(
                          label: _primaryLabel(state, question),
                          onPressed:
                              ((question.hasOptions &&
                                      !state.selections.containsKey(
                                        question.id,
                                      )) ||
                                  !canContinueRecite ||
                                  state.isSubmitting)
                              ? null
                              : () async {
                                  if (isRecitePrompt) {
                                    if (state.currentIndex <
                                        state.questions.length - 1) {
                                      notifier.nextQuestion();
                                      return;
                                    }
                                    await notifier.submitQuiz();
                                    return;
                                  }

                                  if (!state.showFeedback) {
                                    await notifier.submitCurrentAnswer();
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Text(
              'Unable to load quiz.',
              style: MissionText.body(colors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }

  static String _primaryLabel(QuizState state, QuizQuestion question) {
    if (state.isSubmitting) {
      return 'Submitting';
    }
    if (question.type == QuizQuestionType.recitePrompt) {
      return state.currentIndex < state.questions.length - 1
          ? 'Next'
          : 'Submit';
    }
    return 'Submit';
  }

  static int _filledStars(int currentIndex) {
    final filled = 3 + currentIndex;
    return filled.clamp(1, 6);
  }

  static RecorderState _mapRecorderState(QuizRecitationStage stage) {
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

  static void _showInfoSheet(
    BuildContext context, {
    required String title,
    required String message,
    required String primaryLabel,
    required VoidCallback onPrimary,
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final colors = MissionColors.resolve(Theme.of(context).brightness);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            MissionSpacing.lg,
            MissionSpacing.xl,
            MissionSpacing.lg,
            MissionSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                style: MissionText.heading(colors.textPrimary),
              ),
              const SizedBox(height: MissionSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: MissionText.body(colors.textSecondary),
              ),
              const SizedBox(height: MissionSpacing.lg),
              MissionButton(
                label: primaryLabel,
                variant: MissionButtonVariant.outline,
                onPressed: onPrimary,
              ),
              if ((secondaryLabel ?? '').isNotEmpty) ...[
                const SizedBox(height: MissionSpacing.md),
                TextButton(
                  onPressed: onSecondary,
                  child: Text(
                    secondaryLabel!,
                    style: MissionText.title(colors.textSecondary),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CompleteVerseGrid extends StatelessWidget {
  const _CompleteVerseGrid({required this.question, required this.notifier});

  final QuizQuestion question;
  final QuizController notifier;

  @override
  Widget build(BuildContext context) {
    final options = question.options;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: options.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: MissionSpacing.sm,
        mainAxisSpacing: MissionSpacing.sm,
        childAspectRatio: 1.52,
      ),
      itemBuilder: (_, index) {
        final option = options[index];
        return _LessonOptionTile(
          option: option,
          state: notifier.optionState(question, option),
          onTap: () {
            HapticFeedback.selectionClick();
            notifier.selectOption(question.id, option.id);
          },
        );
      },
    );
  }
}

class _LessonOptionTile extends StatelessWidget {
  const _LessonOptionTile({
    required this.option,
    required this.state,
    this.leadingLabel,
    this.onTap,
  });

  final QuizQuestionOption option;
  final QuizOptionState state;
  final String? leadingLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = MissionColors.resolve(Theme.of(context).brightness);
    final enabled = state != QuizOptionState.disabled && onTap != null;

    final background = switch (state) {
      QuizOptionState.normal => colors.surfaceElevated,
      QuizOptionState.selected => colors.surface,
      QuizOptionState.correct => const Color(0xFF8CC84B),
      QuizOptionState.wrong => const Color(0xFFCF6660).withValues(alpha: 0.18),
      QuizOptionState.disabled => colors.surface.withValues(alpha: 0.45),
    };

    final border = switch (state) {
      QuizOptionState.normal => colors.line,
      QuizOptionState.selected => colors.textPrimary,
      QuizOptionState.correct => const Color(0xFF5C8D2E),
      QuizOptionState.wrong => const Color(0xFFCF6660),
      QuizOptionState.disabled => colors.line.withValues(alpha: 0.45),
    };

    final textColor = state == QuizOptionState.disabled
        ? colors.textSecondary.withValues(alpha: 0.7)
        : colors.textPrimary;

    return Opacity(
      opacity: enabled ? 1 : 0.88,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(MissionRadius.sm),
          child: Ink(
            padding: const EdgeInsets.all(MissionSpacing.sm),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(MissionRadius.sm),
              border: Border.all(color: border, width: 1.25),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${leadingLabel ?? ''} ${option.label}'.trim(),
                        style: MissionText.label(textColor),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if ((option.subtitle ?? '').isNotEmpty) ...[
                        const SizedBox(height: MissionSpacing.xs),
                        Text(
                          option.subtitle!,
                          style: MissionText.body(textColor).copyWith(
                            fontFamily: 'NotoNaskhArabic',
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: MissionSpacing.xs),
                MissionIconButton(
                  icon: Icons.volume_up_rounded,
                  onPressed: () {
                    // TODO(quiz-option-audio): connect per-option pronunciation playback.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Option audio placeholder.'),
                      ),
                    );
                  },
                  semanticLabel: 'Play option audio',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
