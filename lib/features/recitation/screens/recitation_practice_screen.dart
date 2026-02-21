import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../child/ui/lesson_widgets.dart';
import '../../child/ui/mission_buttons.dart';
import '../../child/ui/mission_card.dart';
import '../../child/ui/mission_scaffold.dart';
import '../../child/ui/mission_tokens.dart';
import '../../content/providers/content_providers.dart';
import '../../progress/providers/progress_refresh.dart';
import '../../progress/widgets/practice_session_boundary.dart';
import '../../quiz/models/quiz_models.dart';
import '../../../core/ui/recorder_module.dart';
import '../models/ayah_lesson_question.dart';
import '../models/recitation_state.dart';
import '../providers/recitation_controller.dart';

class RecitationPracticeScreen extends ConsumerStatefulWidget {
  const RecitationPracticeScreen({
    super.key,
    required this.surahId,
    required this.ayahId,
  });

  final int surahId;
  final int ayahId;

  @override
  ConsumerState<RecitationPracticeScreen> createState() =>
      _RecitationPracticeScreenState();
}

class _RecitationPracticeScreenState
    extends ConsumerState<RecitationPracticeScreen> {
  bool _didRequestPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didRequestPermission) {
        return;
      }
      _didRequestPermission = true;
      final params = RecitationParams(
        surahId: widget.surahId,
        ayahId: widget.ayahId,
      );
      ref
          .read(recitationControllerProvider(params).notifier)
          .ensureMicPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    final surahId = widget.surahId;
    final ayahId = widget.ayahId;
    final colors = MissionColors.resolve(Theme.of(context).brightness);
    final surahAsync = ref.watch(surahContentProvider(surahId));
    final params = RecitationParams(surahId: surahId, ayahId: ayahId);
    final controller = ref.watch(recitationControllerProvider(params));
    final notifier = ref.read(recitationControllerProvider(params).notifier);

    ref.listen(recitationControllerProvider(params), (previous, next) {
      final finishedUpload =
          previous?.stage == RecitationStage.uploading &&
          next.stage != RecitationStage.uploading &&
          (next.errorMessage == null || next.errorMessage!.isEmpty);
      if (finishedUpload && next.childId.isNotEmpty) {
        refreshChildProgress(ref.invalidate, next.childId);
      }

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
          title: 'Microphone access required',
          message:
              'Enable microphone access from Settings to record recitation.',
          primaryLabel: 'Open settings',
          onPrimary: () async {
            await openAppSettings();
            if (context.mounted) {
              context.pop();
            }
          },
        );
        notifier.clearMicPermissionPrompt();
      }

      final stageChanged = previous?.stage != next.stage;

      if (stageChanged &&
          (next.stage == RecitationStage.feedbackSuccess ||
              next.stage == RecitationStage.feedbackFail) &&
          next.rewardEvent == null) {
        final passed = next.stage == RecitationStage.feedbackSuccess;
        if (passed) {
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.lightImpact();
        }
        _showAttemptResultSheet(
          state: next,
          passed: passed,
          onPrimary: () {
            context.pop();
            if (!passed) {
              notifier.setRecording();
              return;
            }

            final hasPassesRemaining = (next.passesRemaining ?? 0) > 0;
            if (hasPassesRemaining) {
              notifier.setRecording();
              return;
            }

            context.go('/child/surah/$surahId/journey');
          },
        );
      }

      if (stageChanged && next.stage == RecitationStage.lessonCompleted) {
        if (next.childId.isNotEmpty) {
          refreshChildProgress(ref.invalidate, next.childId);
        }
        HapticFeedback.mediumImpact();
        _showInfoSheet(
          title: 'Level passed',
          message: 'Great work. You earned hasanat for this ayah level.',
          primaryLabel: 'Continue',
          secondaryLabel: 'Go back to ayat flow',
          onPrimary: () {
            context.pop();
            if (next.nextGate != null && next.nextGate!.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) {
                  return;
                }
                _showMiniQuizPrompt(surahId: surahId, gate: next.nextGate);
              });
              return;
            }
            if (next.nextAyahId != null) {
              context.go('/child/surah/$surahId/ayah/${next.nextAyahId}');
              return;
            }
            context.go('/child/surah/$surahId/journey');
          },
          onSecondary: () {
            context.pop();
            context.go('/child/surah/$surahId/journey');
          },
        );
      }

      if (stageChanged && next.stage == RecitationStage.gateToQuiz) {
        HapticFeedback.mediumImpact();
        _showMiniQuizPrompt(surahId: surahId, gate: next.nextGate);
      }

      if (stageChanged && next.stage == RecitationStage.interventionRequired) {
        HapticFeedback.selectionClick();
        _showInfoSheet(
          title: 'Let\'s review first',
          message: 'Read and listen once more, then recite again.',
          primaryLabel: 'Back to verse',
          onPrimary: () {
            context.pop();
            context.go('/child/surah/$surahId/ayah/$ayahId');
          },
        );
      }

      if (stageChanged && next.stage == RecitationStage.lockedOut) {
        HapticFeedback.mediumImpact();
        _showInfoSheet(
          title: 'Try again tomorrow',
          message: 'You used all attempts for today.',
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
            final ayah = surah.ayahs.firstWhere(
              (item) => item.id == ayahId,
              orElse: () => surah.ayahs.first,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LessonNavBar(
                  title: '${surah.name} - verse $ayahId',
                  leadingIcon: Icons.close_rounded,
                  onLeadingTap: () =>
                      context.go('/child/surah/$surahId/journey'),
                ),
                const SizedBox(height: MissionSpacing.md),
                LessonStarsBar(total: 6, filled: _filledForState(controller)),
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
                                ayah.arabic,
                                textAlign: TextAlign.center,
                                style: MissionText.heading(colors.textPrimary)
                                    .copyWith(
                                      fontFamily: 'NotoNaskhArabic',
                                      height: 1.62,
                                    ),
                              ),
                              const SizedBox(height: MissionSpacing.sm),
                              Container(
                                height: 1,
                                color: colors.line.withValues(alpha: 0.45),
                              ),
                              const SizedBox(height: MissionSpacing.sm),
                              Text(
                                ayah.transliteration,
                                textAlign: TextAlign.center,
                                style: MissionText.body(colors.textPrimary),
                              ),
                              const SizedBox(height: MissionSpacing.xs),
                              Text(
                                ayah.translation,
                                textAlign: TextAlign.center,
                                style: MissionText.body(colors.textSecondary),
                              ),
                              const SizedBox(height: MissionSpacing.sm),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  MissionIconButton(
                                    icon: Icons.play_arrow_rounded,
                                    onPressed: () {
                                      // TODO(lesson-audio): play tutor recitation sample from backend/source.
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Tutor audio placeholder.',
                                          ),
                                        ),
                                      );
                                    },
                                    semanticLabel: 'Play tutor audio',
                                  ),
                                  const SizedBox(width: MissionSpacing.sm),
                                  MissionIconButton(
                                    icon: Icons.visibility_off_outlined,
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Hide helper placeholder.',
                                          ),
                                        ),
                                      );
                                    },
                                    semanticLabel: 'Hide helper',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: MissionSpacing.md),
                        if (controller.isComprehension &&
                            controller.currentLessonQuestion != null) ...[
                          _ComprehensionQuestionCard(
                            state: controller,
                            notifier: notifier,
                          ),
                        ] else ...[
                          RecorderModule(
                            state: _mapRecorderState(controller.stage),
                            onPrimaryAction: () {
                              switch (controller.stage) {
                                case RecitationStage.idle:
                                  HapticFeedback.selectionClick();
                                  notifier.setRecording();
                                  break;
                                case RecitationStage.recording:
                                  HapticFeedback.lightImpact();
                                  notifier.stopRecording();
                                  break;
                                case RecitationStage.review:
                                  HapticFeedback.selectionClick();
                                  notifier.submitRecording();
                                  break;
                                case RecitationStage.feedbackSuccess:
                                case RecitationStage.feedbackFail:
                                  HapticFeedback.selectionClick();
                                  notifier.setRecording();
                                  break;
                                case RecitationStage.uploading:
                                case RecitationStage.interventionRequired:
                                case RecitationStage.lockedOut:
                                case RecitationStage.gateToQuiz:
                                case RecitationStage.comprehension:
                                case RecitationStage.lessonCompleted:
                                  break;
                              }
                            },
                            onSecondaryAction: () {
                              HapticFeedback.selectionClick();
                              notifier.setRecording();
                            },
                            onListen: () {
                              HapticFeedback.selectionClick();
                              notifier.playRecording();
                            },
                            durationLabel: controller.durationLabel,
                          ),
                          const SizedBox(height: MissionSpacing.sm),
                          if (controller.attemptsLeftToday != null)
                            Text(
                              '${controller.attemptsLeftToday} attempts left today',
                              textAlign: TextAlign.center,
                              style: MissionText.micro(colors.textSecondary),
                            ),
                        ],
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
              'Unable to load recitation.',
              style: MissionText.body(colors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }

  void _showAttemptResultSheet({
    required RecitationState state,
    required bool passed,
    required VoidCallback onPrimary,
  }) {
    final attemptsLeft = state.attemptsLeftToday;
    final detailed = state.showDetailedFeedback;
    final hasPassesRemaining = (state.passesRemaining ?? 0) > 0;

    if (passed) {
      showLessonFeedbackSheet(
        context: context,
        sheet: LessonFeedbackSheet(
          title: 'Good job',
          message: 'Time to boost your recitation',
          emphasis: state.passesRemaining == null
              ? null
              : '${state.passesRemaining} passes left to mastery',
          primaryLabel: hasPassesRemaining ? 'Recite again' : 'Continue',
          onPrimary: onPrimary,
        ),
      );
      return;
    }

    final showCorrectiveHint =
        detailed || (DateTime.now().millisecond % 2 == 0);
    showLessonFeedbackSheet(
      context: context,
      sheet: LessonFeedbackSheet(
        title: 'Incorrect',
        titleColor: const Color(0xFFCF6660),
        message: showCorrectiveHint
            ? 'Try reciting it one more time.'
            : 'Keep going, you\'re close.',
        emphasis: attemptsLeft == null ? null : '$attemptsLeft attempts left',
        detailLabel: showCorrectiveHint ? 'Time elapsed' : null,
        detailValue: showCorrectiveHint ? state.durationLabel : null,
        primaryLabel: 'Try again',
        onPrimary: onPrimary,
      ),
    );
  }

  void _showInfoSheet({
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
      builder: (sheetContext) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            MissionSpacing.lg,
            MissionSpacing.xl,
            MissionSpacing.lg,
            MissionSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: MissionColors.resolve(
              Theme.of(context).brightness,
            ).surfaceElevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                style: MissionText.heading(
                  MissionColors.resolve(
                    Theme.of(context).brightness,
                  ).textPrimary,
                ),
              ),
              const SizedBox(height: MissionSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: MissionText.body(
                  MissionColors.resolve(
                    Theme.of(context).brightness,
                  ).textSecondary,
                ),
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
                    style: MissionText.title(
                      MissionColors.resolve(
                        Theme.of(context).brightness,
                      ).textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showMiniQuizPrompt({required int surahId, required String? gate}) {
    final quizType = quizTypeFromGate(gate);
    final route = quizType == null
        ? '/child/surah/$surahId/journey'
        : '/child/surah/$surahId/quiz/${quizType.apiValue}';
    _showInfoSheet(
      title: 'Challenge time',
      message: 'A quick check is unlocked. Let\'s go.',
      primaryLabel: 'Lets go',
      secondaryLabel: 'Go back to ayat flow',
      onPrimary: () {
        context.pop();
        context.push(route);
      },
      onSecondary: () {
        context.pop();
        context.go('/child/surah/$surahId/journey');
      },
    );
  }

  RecorderState _mapRecorderState(RecitationStage stage) {
    switch (stage) {
      case RecitationStage.idle:
        return RecorderState.idle;
      case RecitationStage.recording:
        return RecorderState.recording;
      case RecitationStage.review:
        return RecorderState.review;
      case RecitationStage.uploading:
      case RecitationStage.interventionRequired:
      case RecitationStage.lockedOut:
      case RecitationStage.gateToQuiz:
      case RecitationStage.comprehension:
      case RecitationStage.lessonCompleted:
        return RecorderState.submitting;
      case RecitationStage.feedbackSuccess:
      case RecitationStage.feedbackFail:
        return RecorderState.idle;
    }
  }

  int _filledForState(RecitationState state) {
    switch (state.stage) {
      case RecitationStage.idle:
      case RecitationStage.recording:
      case RecitationStage.review:
        return 2;
      case RecitationStage.uploading:
      case RecitationStage.feedbackSuccess:
      case RecitationStage.feedbackFail:
        return 3;
      case RecitationStage.gateToQuiz:
      case RecitationStage.lessonCompleted:
        return 6;
      case RecitationStage.comprehension:
        final filled = 4 + state.lessonQuestionIndex;
        return filled.clamp(4, 5);
      case RecitationStage.interventionRequired:
      case RecitationStage.lockedOut:
        return 2;
    }
  }
}

class _ComprehensionQuestionCard extends StatelessWidget {
  const _ComprehensionQuestionCard({
    required this.state,
    required this.notifier,
  });

  final RecitationState state;
  final RecitationController notifier;

  @override
  Widget build(BuildContext context) {
    final colors = MissionColors.resolve(Theme.of(context).brightness);
    final question = state.currentLessonQuestion;
    if (question == null) {
      return const SizedBox.shrink();
    }

    final selectedId = notifier.selectedLessonOptionFor(question.id);

    return Column(
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
              Text(
                question.prompt,
                style: MissionText.heading(
                  colors.textPrimary,
                ).copyWith(fontSize: 38),
              ),
              if ((question.context ?? '').isNotEmpty) ...[
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
            ],
          ),
        ),
        const SizedBox(height: MissionSpacing.md),
        for (var i = 0; i < question.options.length; i++) ...[
          _ComprehensionOptionTile(
            option: question.options[i],
            selected: selectedId == question.options[i].id,
            leadingLabel: '${String.fromCharCode(65 + i)})',
            onTap: () => notifier.selectLessonOption(
              question.id,
              question.options[i].id,
            ),
          ),
          if (i != question.options.length - 1)
            const SizedBox(height: MissionSpacing.sm),
        ],
        const SizedBox(height: MissionSpacing.lg),
        MissionButton(
          label: 'Submit',
          onPressed: selectedId == null || state.isBusy
              ? null
              : () {
                  final correct = notifier.isCurrentLessonAnswerCorrect();
                  if (correct) {
                    showLessonFeedbackSheet(
                      context: context,
                      sheet: LessonFeedbackSheet(
                        title: 'Good job',
                        message: 'Correct answer.',
                        emphasis: notifier.isLastLessonQuestion()
                            ? 'Level completion unlocked.'
                            : 'Continue to the next question.',
                        primaryLabel: notifier.isLastLessonQuestion()
                            ? 'Finish level'
                            : 'Next',
                        onPrimary: () async {
                          context.pop();
                          if (notifier.isLastLessonQuestion()) {
                            await notifier.completeAyahLesson();
                            return;
                          }
                          notifier.nextLessonQuestion();
                        },
                      ),
                    );
                    return;
                  }

                  final correctOption = question.options.firstWhere(
                    (option) => option.id == question.correctOptionId,
                    orElse: () => question.options.first,
                  );
                  showLessonFeedbackSheet(
                    context: context,
                    sheet: LessonFeedbackSheet(
                      title: 'Incorrect',
                      titleColor: const Color(0xFFCF6660),
                      message: 'Try again with the correct option.',
                      detailLabel: 'Correct answer is',
                      detailValue: correctOption.label,
                      primaryLabel: 'Try again',
                      onPrimary: () {
                        context.pop();
                        notifier.retryCurrentLessonQuestion(
                          clearSelection: true,
                        );
                      },
                    ),
                  );
                },
        ),
      ],
    );
  }
}

class _ComprehensionOptionTile extends StatelessWidget {
  const _ComprehensionOptionTile({
    required this.option,
    required this.selected,
    required this.leadingLabel,
    required this.onTap,
  });

  final AyahLessonOption option;
  final bool selected;
  final String leadingLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = MissionColors.resolve(Theme.of(context).brightness);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(MissionRadius.sm),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(MissionSpacing.sm),
          decoration: BoxDecoration(
            color: selected ? colors.surface : colors.surfaceElevated,
            borderRadius: BorderRadius.circular(MissionRadius.sm),
            border: Border.all(
              color: selected ? colors.textPrimary : colors.line,
              width: 1.25,
            ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$leadingLabel ${option.label}'.trim(),
                      style: MissionText.label(colors.textPrimary),
                    ),
                    if ((option.subtitle ?? '').isNotEmpty) ...[
                      const SizedBox(height: MissionSpacing.xs),
                      Text(
                        option.subtitle!,
                        style: MissionText.body(
                          colors.textSecondary,
                        ).copyWith(fontFamily: 'NotoNaskhArabic'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
