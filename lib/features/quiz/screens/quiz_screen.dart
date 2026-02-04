import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/ui/action_icon_button.dart';
import '../../../core/ui/app_app_bar.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/illustration_frame.dart';
import '../../../core/ui/inline_loader.dart';
import '../../../core/ui/modal_sheet.dart';
import '../../../core/ui/primary_button.dart';
import '../../../core/ui/quiz_option_card.dart';
import '../../../core/ui/stars_row.dart';
import '../../content/providers/content_providers.dart';
import '../../rewards/models/reward_event.dart';
import '../models/quiz_models.dart';
import '../providers/quiz_controller.dart';

class QuizScreen extends ConsumerWidget {
  const QuizScreen({
    super.key,
    required this.surahId,
    required this.quizType,
  });

  final int surahId;
  final QuizType quizType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahAsync = ref.watch(surahContentProvider(surahId));
    final params = QuizParams(surahId: surahId, quizType: quizType);
    final state = ref.watch(quizControllerProvider(params));
    final notifier = ref.read(quizControllerProvider(params).notifier);

    ref.listen(quizControllerProvider(params), (previous, next) {
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

      if (previous?.rewardEvent != next.rewardEvent && next.rewardEvent != null) {
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

      final justCompleted = previous?.isSubmitting == true && next.isSubmitting == false && next.score != null;
      if (justCompleted) {
        final passed = next.passed == true;
        ModalSheetTrigger.show(
          context,
          sheet: ModalSheet(
            title: passed ? 'Good job 🎉' : 'Let\'s try again',
            message: passed
                ? 'You answered correctly. Keep going!'
                : 'Review the lesson and try the quiz again.',
            variant: passed ? ModalSheetVariant.success : ModalSheetVariant.fail,
            primaryAction: PrimaryButton(
              label: passed ? 'Continue' : 'Try again',
              onPressed: () {
                context.pop();
                if (passed) {
                  context.pop();
                } else {
                  notifier.resetQuiz();
                }
              },
            ),
          ),
        );
      }
    });

    return AppScaffold(
      appBar: AppAppBar(title: quizType.label),
      body: surahAsync.when(
        data: (surah) {
          if (state.questions.isEmpty) {
            return _emptyQuiz(context);
          }

          final question = state.questions[state.currentIndex];
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
                    Text(question.title.toUpperCase(), style: AppTextStyles.caption),
                    const SizedBox(height: AppSpacing.sm),
                    Text(question.prompt, style: AppTextStyles.title),
                    if (question.context != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(question.context!, style: AppTextStyles.body),
                    ],
                    if (question.hasAudio) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: IllustrationFrame(
                          size: 160,
                          child: Icon(Icons.mic, size: 40, color: AppColors.textNavy),
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
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final option = question.options[index];
                      return QuizOptionCard(
                        label: option.label,
                        state: notifier.optionState(question, option),
                        onTap: () => notifier.selectOption(question.id, option.id),
                      );
                    },
                  ),
                ),
              if (!question.hasOptions) const Spacer(),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: _primaryLabel(state, question),
                isDisabled: question.hasOptions && !state.selections.containsKey(question.id),
                isLoading: state.isSubmitting,
                onPressed: () async {
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
    );
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
