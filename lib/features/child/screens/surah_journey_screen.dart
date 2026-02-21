import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../journey/models/journey_models.dart';
import '../../journey/providers/journey_providers.dart';
import '../../map/models/map_models.dart';
import '../../map/providers/map_providers.dart';
import '../providers/child_providers.dart';
import '../ui/mission_buttons.dart';
import '../ui/mission_card.dart';
import '../ui/mission_orbit_icon.dart';
import '../ui/mission_scaffold.dart';
import '../ui/mission_status_tag.dart';
import '../ui/mission_tokens.dart';
import '../ui/lesson_widgets.dart';
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

    final colors = MissionColors.resolve(Theme.of(context).brightness);

    return MissionScaffold(
      extendToBottom: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LessonNavBar(
            title: surahId == 1 ? 'Al-Fatiha' : 'Ayat Flow',
            onLeadingTap: () => context.go('/child/home'),
          ),
          const SizedBox(height: MissionSpacing.md),
          Expanded(
            child: mapAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Text(
                  'Unable to load mission map.',
                  style: MissionText.body(colors.textSecondary),
                ),
              ),
              data: (mapState) {
                final surah = mapState?.findSurah(surahId);
                if (surah == null) {
                  return Center(
                    child: Text(
                      'Mission not found.',
                      style: MissionText.body(colors.textSecondary),
                    ),
                  );
                }

                return stepsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Center(
                    child: Text(
                      'Unable to load mission steps.',
                      style: MissionText.body(colors.textSecondary),
                    ),
                  ),
                  data: (stepsRaw) {
                    final steps = [...stepsRaw]
                      ..sort(
                        (a, b) =>
                            a.level.orderIndex.compareTo(b.level.orderIndex),
                      );
                    final nextStep = _resolveNextStep(steps);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.only(
                        bottom: MissionSpacing.xxl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            surah.name,
                            style: MissionText.heading(colors.textPrimary),
                          ),
                          const SizedBox(height: MissionSpacing.xs),
                          Text(
                            surah.translation,
                            style: MissionText.body(colors.textSecondary),
                          ),
                          const SizedBox(height: MissionSpacing.sm),
                          MissionStatusTag(
                            label: _surahStatusLabel(surah),
                            icon: Icons.route,
                          ),
                          const SizedBox(height: MissionSpacing.lg),
                          _JourneyTrack(
                            steps: steps,
                            onTap: (step) => _openStep(
                              context: context,
                              ref: ref,
                              step: step,
                            ),
                          ),
                          const SizedBox(height: MissionSpacing.lg),
                          if (nextStep != null)
                            MissionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    _cardTitle(nextStep),
                                    style: MissionText.heading(
                                      colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: MissionSpacing.sm),
                                  Text(
                                    _cardSubtitle(nextStep),
                                    style: MissionText.body(
                                      colors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: MissionSpacing.md),
                                  MissionButton(
                                    label: nextStep.isLocked
                                        ? 'Locked'
                                        : 'Start mission',
                                    onPressed: nextStep.isLocked
                                        ? null
                                        : () => _openStep(
                                            context: context,
                                            ref: ref,
                                            step: nextStep,
                                          ),
                                  ),
                                ],
                              ),
                            )
                          else
                            MissionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'All steps complete',
                                    style: MissionText.heading(
                                      colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: MissionSpacing.sm),
                                  Text(
                                    'Great work. Revisit any step to practice again.',
                                    style: MissionText.body(
                                      colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_allLocked(steps)) ...[
                            const SizedBox(height: MissionSpacing.md),
                            MissionButton(
                              label: surah.locked
                                  ? 'No slots available'
                                  : 'Activate mission',
                              onPressed: surah.locked || child == null
                                  ? null
                                  : () async {
                                      try {
                                        await repo.startSurah(
                                          childId: child.id,
                                          surahId: surahId,
                                        );
                                        ref.invalidate(mapStateProvider);
                                        ref.invalidate(
                                          surahJourneyStepsProvider(surahId),
                                        );
                                      } catch (_) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Could not activate mission. Please try again.',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _openStep({
    required BuildContext context,
    required WidgetRef ref,
    required JourneyStep step,
  }) async {
    if (step.isLocked) {
      final colors = MissionColors.resolve(Theme.of(context).brightness);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Complete earlier steps to unlock this mission.',
            style: MissionText.body(colors.primaryText),
          ),
        ),
      );
      return;
    }

    switch (step.level.type) {
      case JourneyLevelType.surahIntro:
        await context.push(
          '/child/surah/${step.level.surahId}/intro/${step.level.id}',
          extra: SurahIntroArgs(
            surahId: step.level.surahId,
            levelId: step.level.id,
          ),
        );
        break;
      case JourneyLevelType.verseLesson:
        final ayahId = step.level.ayahId;
        if (ayahId == null) {
          return;
        }
        await context.push('/child/surah/${step.level.surahId}/ayah/$ayahId');
        break;
      case JourneyLevelType.checkpoint:
        final quizType = step.level.quizType;
        if (quizType == null) {
          return;
        }
        await context.push('/child/surah/${step.level.surahId}/quiz/$quizType');
        break;
      case JourneyLevelType.finalExam:
        await context.push('/child/surah/${step.level.surahId}/quiz/final');
        break;
    }

    ref.invalidate(mapStateProvider);
    ref.invalidate(surahJourneyStepsProvider(step.level.surahId));
  }

  static JourneyStep? _resolveNextStep(List<JourneyStep> steps) {
    for (final step in steps) {
      if (step.isUnlocked && !step.isCompleted) {
        return step;
      }
    }
    for (final step in steps) {
      if (step.isLocked) {
        return step;
      }
    }
    return steps.isEmpty ? null : steps.last;
  }

  static bool _allLocked(List<JourneyStep> steps) {
    return steps.isNotEmpty && steps.every((step) => step.isLocked);
  }

  static String _surahStatusLabel(SurahNode surah) {
    if (surah.locked) {
      return 'Locked';
    }
    if (surah.isCompleted) {
      return 'Completed';
    }
    if (surah.isActive) {
      return 'In progress';
    }
    return 'Available';
  }

  static String _cardTitle(JourneyStep step) {
    switch (step.level.type) {
      case JourneyLevelType.surahIntro:
        return 'Learn the mission';
      case JourneyLevelType.verseLesson:
        final ayah = step.level.ayahId;
        return ayah == null ? 'Verse lesson' : 'Verse $ayah';
      case JourneyLevelType.checkpoint:
        return 'Memorize checkpoint';
      case JourneyLevelType.finalExam:
        return 'Final challenge';
    }
  }

  static String _cardSubtitle(JourneyStep step) {
    switch (step.level.type) {
      case JourneyLevelType.surahIntro:
        return 'Start with context and goals before the verses.';
      case JourneyLevelType.verseLesson:
        return 'Practice reading and reciting this verse with confidence.';
      case JourneyLevelType.checkpoint:
        return 'Review what you learned before unlocking the next step.';
      case JourneyLevelType.finalExam:
        return 'Show mastery and complete this surah mission.';
    }
  }
}

class _JourneyTrack extends StatelessWidget {
  const _JourneyTrack({required this.steps, required this.onTap});

  final List<JourneyStep> steps;
  final ValueChanged<JourneyStep> onTap;

  @override
  Widget build(BuildContext context) {
    final displaySteps = steps.reversed.toList();

    return Column(
      children: [
        for (var i = 0; i < displaySteps.length; i++) ...[
          _JourneyNode(
            step: displaySteps[i],
            alignRight: i.isOdd,
            onTap: () => onTap(displaySteps[i]),
          ),
          if (i != displaySteps.length - 1) _Connector(alignRight: i.isOdd),
        ],
      ],
    );
  }
}

class _JourneyNode extends StatelessWidget {
  const _JourneyNode({
    required this.step,
    required this.alignRight,
    required this.onTap,
  });

  final JourneyStep step;
  final bool alignRight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = MissionColors.resolve(Theme.of(context).brightness);

    final locked = step.isLocked;
    final completed = step.isCompleted;

    final badgeLabel = switch (step.level.type) {
      JourneyLevelType.checkpoint => 'MEMORIZE',
      JourneyLevelType.finalExam => 'MASTER',
      _ => null,
    };

    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: SizedBox(
        width: 230,
        child: Column(
          crossAxisAlignment: alignRight
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (badgeLabel != null)
              Padding(
                padding: const EdgeInsets.only(bottom: MissionSpacing.xs),
                child: MissionStatusTag(
                  label: badgeLabel,
                  icon: Icons.military_tech_outlined,
                ),
              ),
            GestureDetector(
              onTap: onTap,
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.surface,
                  border: Border.all(color: colors.textPrimary, width: 1.1),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow,
                      blurRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    MissionOrbitIcon(size: 48, opacity: locked ? 0.35 : 1),
                    if (locked)
                      Icon(Icons.lock, size: 20, color: colors.textPrimary)
                    else if (completed)
                      Icon(
                        Icons.check_circle,
                        size: 20,
                        color: MissionPalette.green,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector({required this.alignRight});

  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final colors = MissionColors.resolve(Theme.of(context).brightness);

    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: SizedBox(
        width: 230,
        height: 44,
        child: CustomPaint(
          painter: _ConnectorPainter(
            color: colors.textPrimary,
            alignRight: alignRight,
          ),
        ),
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  const _ConnectorPainter({required this.color, required this.alignRight});

  final Color color;
  final bool alignRight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = color;

    final startX = alignRight ? size.width - 62 : 62.0;
    final endX = alignRight ? 72.0 : size.width - 72;

    final path = Path()
      ..moveTo(startX, 0)
      ..cubicTo(
        alignRight ? size.width - 2 : 2,
        size.height * 0.32,
        alignRight ? size.width * 0.55 : size.width * 0.45,
        size.height * 0.7,
        endX,
        size.height,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter oldDelegate) {
    return color != oldDelegate.color || alignRight != oldDelegate.alignRight;
  }
}
