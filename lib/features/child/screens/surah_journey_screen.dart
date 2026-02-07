import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/ui/app_app_bar.dart';
import '../../../core/ui/app_card.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/modal_sheet.dart';
import '../../../core/ui/primary_button.dart';
import '../../journey/models/journey_models.dart';
import '../../journey/providers/journey_providers.dart';
import '../../map/providers/map_providers.dart';
import '../providers/child_providers.dart';
import 'surah_intro_screen.dart';

class SurahJourneyScreen extends ConsumerWidget {
  const SurahJourneyScreen({super.key, required this.surahId});

  final int surahId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider);
    final mapAsync = ref.watch(mapStateProvider);
    final stepsAsync = ref.watch(surahJourneyStepsProvider(surahId));
    final repo = ref.watch(mapRepositoryProvider);

    return AppScaffold(
      appBar: const AppAppBar(title: 'Surah Journey'),
      body: mapAsync.when(
        data: (mapState) {
          final surahNode = mapState?.findSurah(surahId);
          final title = surahNode?.name.isNotEmpty == true ? surahNode!.name : 'Surah $surahId';

          if (surahNode != null && !surahNode.playable) {
            return Center(
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: AppTextStyles.title),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Content not available yet.', style: AppTextStyles.body),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: 'Back',
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
              ),
            );
          }

          return stepsAsync.when(
            data: (steps) {
              final allLocked = steps.isNotEmpty && steps.every((step) => step.progress.status == JourneyLevelStatus.locked);
              final canStart = child != null && (surahNode?.locked != true);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: AppTextStyles.title),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Follow the path to master this surah.', style: AppTextStyles.body),
                  const SizedBox(height: AppSpacing.lg),
                  if (allLocked) ...[
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Start this surah', style: AppTextStyles.title),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            surahNode?.locked == true
                                ? 'No slots available. Complete an active surah to unlock.'
                                : 'This will unlock your first level.',
                            style: AppTextStyles.body,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          PrimaryButton(
                            label: 'Start',
                            isDisabled: !canStart,
                            onPressed: !canStart
                                ? null
                                : () async {
                                    final currentChild = child;
                                    try {
                                      await repo.startSurah(childId: currentChild.id, surahId: surahId);
                                      ref.invalidate(mapStateProvider);
                                      ref.invalidate(surahJourneyStepsProvider(surahId));
                                    } catch (error) {
                                      if (!context.mounted) return;
                                      await ModalSheetTrigger.show(
                                        context,
                                        sheet: ModalSheet(
                                          title: 'Unable to start surah',
                                          message: '$error',
                                          variant: ModalSheetVariant.fail,
                                          primaryAction: PrimaryButton(
                                            label: 'Okay',
                                            onPressed: () => context.pop(),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  Expanded(
                    child: ListView.separated(
                      itemCount: steps.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final step = steps[index];
                        return _JourneyStepCard(
                          step: step,
                          onTap: () async {
                            if (step.isLocked) {
                              await _showLocked(context, step);
                              return;
                            }

                            switch (step.level.type) {
                              case JourneyLevelType.surahIntro:
                                await context.push(
                                  '/child/surah/$surahId/intro/${step.level.id}',
                                  extra: SurahIntroArgs(surahId: surahId, levelId: step.level.id),
                                );
                                break;
                              case JourneyLevelType.verseLesson:
                                final ayahId = step.level.ayahId;
                                if (ayahId == null) return;
                                await context.push('/child/surah/$surahId/ayah/$ayahId');
                                break;
                              case JourneyLevelType.checkpoint:
                                final quizType = step.level.quizType;
                                if (quizType == null) return;
                                await context.push('/child/surah/$surahId/quiz/$quizType');
                                break;
                              case JourneyLevelType.finalExam:
                                await context.push('/child/surah/$surahId/quiz/final');
                                break;
                            }

                            ref.invalidate(mapStateProvider);
                            ref.invalidate(surahJourneyStepsProvider(surahId));
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text('Unable to load journey.', style: AppTextStyles.body),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Unable to load map state.', style: AppTextStyles.body),
        ),
      ),
    );
  }

  Future<void> _showLocked(BuildContext context, JourneyStep step) {
    final lockedUntil = step.progress.lockedUntil;
    final message = lockedUntil != null
        ? 'Try again after ${lockedUntil.toLocal()}.'
        : 'Complete previous levels to unlock.';
    return ModalSheetTrigger.show(
      context,
      sheet: ModalSheet(
        title: 'Locked',
        message: message,
        variant: ModalSheetVariant.info,
        primaryAction: PrimaryButton(
          label: 'Okay',
          onPressed: () => context.pop(),
        ),
      ),
    );
  }
}

class _JourneyStepCard extends StatelessWidget {
  const _JourneyStepCard({
    required this.step,
    required this.onTap,
  });

  final JourneyStep step;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = _title(step.level);
    final status = _status(step.progress.status);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.xs),
          Text(status, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: step.isLocked ? 'Locked' : (step.isCompleted ? 'Review' : 'Open'),
            isDisabled: step.isLocked,
            onPressed: step.isLocked ? null : onTap,
          ),
        ],
      ),
    );
  }

  String _title(JourneyLevel level) {
    switch (level.type) {
      case JourneyLevelType.surahIntro:
        return 'Surah introduction';
      case JourneyLevelType.verseLesson:
        return 'Ayah ${level.ayahId}';
      case JourneyLevelType.checkpoint:
        final label = level.quizType == 'mini_1'
            ? 'Checkpoint (Mini quiz 1)'
            : level.quizType == 'mini_2'
                ? 'Checkpoint (Mini quiz 2)'
                : 'Checkpoint';
        return label;
      case JourneyLevelType.finalExam:
        return 'Final exam';
    }
  }

  String _status(JourneyLevelStatus status) {
    switch (status) {
      case JourneyLevelStatus.locked:
        return 'Locked';
      case JourneyLevelStatus.unlocked:
        return 'Unlocked';
      case JourneyLevelStatus.inProgress:
        return 'In progress';
      case JourneyLevelStatus.completed:
        return 'Completed';
    }
  }
}
