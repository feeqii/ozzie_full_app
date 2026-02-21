import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../journey/models/journey_models.dart';
import '../../journey/providers/journey_providers.dart';
import '../../map/models/map_models.dart';
import '../../map/providers/map_providers.dart';
import '../providers/child_providers.dart';
import '../ui/lesson_widgets.dart';
import '../ui/mission_buttons.dart';
import '../ui/mission_orbit_icon.dart';
import '../ui/mission_scaffold.dart';
import '../ui/mission_status_tag.dart';
import '../ui/mission_tokens.dart';
import 'surah_intro_screen.dart';

class SurahJourneyScreen extends ConsumerStatefulWidget {
  const SurahJourneyScreen({super.key, required this.surahId});

  final int surahId;

  @override
  ConsumerState<SurahJourneyScreen> createState() => _SurahJourneyScreenState();
}

class _SurahJourneyScreenState extends ConsumerState<SurahJourneyScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _scrollViewportKey = GlobalKey();
  final GlobalKey _trackKey = GlobalKey();
  String? _lastCenteredSignature;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(selectedChildProvider);
    final mapAsync = ref.watch(mapStateProvider);
    final stepsAsync = ref.watch(surahJourneyStepsProvider(widget.surahId));
    final repo = ref.watch(mapRepositoryProvider);

    final colors = MissionColors.resolve(Theme.of(context).brightness);

    return MissionScaffold(
      extendToBottom: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LessonNavBar(
            title: widget.surahId == 1 ? 'Al-Fatiha' : 'Ayat Flow',
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
                final surah = mapState?.findSurah(widget.surahId);
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
                    final displaySteps = steps.reversed.toList();
                    final currentDisplayIndex = nextStep == null
                        ? -1
                        : displaySteps.indexWhere(
                            (step) => step.level.id == nextStep.level.id,
                          );
                    final dockHeight = _MissionDock.estimatedHeight(
                      hasStep: nextStep != null,
                    );

                    if (currentDisplayIndex >= 0) {
                      _queueCenterCurrentNode(
                        signature:
                            '${widget.surahId}:${steps.map((step) => '${step.level.id}:${step.progress.status.name}').join('|')}',
                        currentDisplayIndex: currentDisplayIndex,
                        dockHeight: dockHeight,
                      );
                    }

                    return Stack(
                      children: [
                        SingleChildScrollView(
                          key: _scrollViewportKey,
                          controller: _scrollController,
                          padding: EdgeInsets.only(
                            bottom: dockHeight + MissionSpacing.xl,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _JourneyHero(
                                surah: surah,
                                steps: steps,
                                statusLabel: _surahStatusLabel(surah),
                              ),
                              const SizedBox(height: MissionSpacing.lg),
                              _JourneyTrack(
                                key: _trackKey,
                                steps: steps,
                                currentLevelId: nextStep?.level.id,
                                onTap: (step) => _openStep(
                                  context: context,
                                  ref: ref,
                                  step: step,
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
                                              surahId: widget.surahId,
                                            );
                                            ref.invalidate(mapStateProvider);
                                            ref.invalidate(
                                              surahJourneyStepsProvider(
                                                widget.surahId,
                                              ),
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
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: SafeArea(
                            top: false,
                            child: _MissionDock(
                              title: nextStep != null
                                  ? _cardTitle(nextStep)
                                  : 'All steps complete',
                              subtitle: nextStep != null
                                  ? _cardSubtitle(nextStep)
                                  : 'Great work. Revisit any step to practice again.',
                              progressLabel: nextStep != null
                                  ? _dockProgressLabel(nextStep, steps.length)
                                  : '${steps.length}/${steps.length}',
                              buttonLabel: nextStep == null
                                  ? null
                                  : nextStep.isLocked
                                  ? 'Locked'
                                  : 'Start mission',
                              onPressed: nextStep == null || nextStep.isLocked
                                  ? null
                                  : () => _openStep(
                                      context: context,
                                      ref: ref,
                                      step: nextStep,
                                    ),
                            ),
                          ),
                        ),
                      ],
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

  void _queueCenterCurrentNode({
    required String signature,
    required int currentDisplayIndex,
    required double dockHeight,
  }) {
    if (_lastCenteredSignature == signature) {
      return;
    }
    _lastCenteredSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _centerCurrentNode(
        currentDisplayIndex: currentDisplayIndex,
        dockHeight: dockHeight,
      );
    });
  }

  void _centerCurrentNode({
    required int currentDisplayIndex,
    required double dockHeight,
  }) {
    if (!_scrollController.hasClients) {
      return;
    }

    final viewportContext = _scrollViewportKey.currentContext;
    final trackContext = _trackKey.currentContext;
    if (viewportContext == null || trackContext == null) {
      return;
    }

    final viewportBox = viewportContext.findRenderObject() as RenderBox?;
    final trackBox = trackContext.findRenderObject() as RenderBox?;
    if (viewportBox == null || trackBox == null) {
      return;
    }

    final trackTopInViewport = trackBox.localToGlobal(
      Offset.zero,
      ancestor: viewportBox,
    );

    final nodeCenterInViewport =
        trackTopInViewport.dy +
        _JourneyTrackMetrics.nodeCenterY(currentDisplayIndex);
    final viewportHeight = viewportBox.size.height;
    final activeViewportHeight =
        (viewportHeight - dockHeight - MissionSpacing.sm).clamp(
          160.0,
          viewportHeight,
        );
    final targetCenter = activeViewportHeight * 0.5;
    final offsetDelta = nodeCenterInViewport - targetCenter;

    final targetOffset = (_scrollController.offset + offsetDelta).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    if ((targetOffset - _scrollController.offset).abs() < 1) {
      return;
    }
    _scrollController.jumpTo(targetOffset);
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

  static String _dockProgressLabel(JourneyStep step, int total) {
    final idx = step.level.orderIndex;
    return '$idx/$total';
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

class _JourneyHero extends StatelessWidget {
  const _JourneyHero({
    required this.surah,
    required this.steps,
    required this.statusLabel,
  });

  final SurahNode surah;
  final List<JourneyStep> steps;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final colors = MissionColors.resolve(Theme.of(context).brightness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          surah.name,
          style: MissionText.heading(colors.textPrimary).copyWith(fontSize: 34),
        ),
        const SizedBox(height: MissionSpacing.xs),
        Text(surah.translation, style: MissionText.body(colors.textSecondary)),
        const SizedBox(height: MissionSpacing.sm),
        Row(
          children: [MissionStatusTag(label: statusLabel, icon: Icons.route)],
        ),
      ],
    );
  }
}

class _JourneyPill extends StatelessWidget {
  const _JourneyPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = MissionColors.resolve(Theme.of(context).brightness);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MissionSpacing.sm,
        vertical: MissionSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.line.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.textPrimary),
          const SizedBox(width: MissionSpacing.xs),
          Text(
            label,
            style: MissionText.micro(
              colors.textPrimary,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MissionDock extends StatelessWidget {
  const _MissionDock({
    required this.title,
    required this.subtitle,
    required this.progressLabel,
    this.buttonLabel,
    this.onPressed,
  });

  final String title;
  final String subtitle;
  final String progressLabel;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  static double estimatedHeight({required bool hasStep}) {
    return hasStep ? 250 : 196;
  }

  @override
  Widget build(BuildContext context) {
    final colors = MissionColors.resolve(Theme.of(context).brightness);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MissionRadius.lg),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          MissionSpacing.lg,
          MissionSpacing.md,
          MissionSpacing.lg,
          MissionSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(MissionRadius.lg),
          border: Border.all(color: colors.line.withValues(alpha: 0.45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: MissionText.heading(
                      colors.textPrimary,
                    ).copyWith(fontSize: 26),
                  ),
                ),
                _JourneyPill(
                  icon: Icons.my_location_rounded,
                  label: progressLabel,
                ),
              ],
            ),
            const SizedBox(height: MissionSpacing.xs),
            Text(
              subtitle,
              style: MissionText.body(
                colors.textSecondary,
              ).copyWith(height: 1.35),
            ),
            if ((buttonLabel ?? '').isNotEmpty) ...[
              const SizedBox(height: MissionSpacing.md),
              MissionButton(label: buttonLabel!, onPressed: onPressed),
            ],
          ],
        ),
      ),
    );
  }
}

class _JourneyTrackMetrics {
  const _JourneyTrackMetrics._();

  static const double topPadding = 22;
  static const double bottomPadding = 44;
  static const double nodeSize = 82;
  static const double rowStride = 142;

  static double totalHeight(int count) {
    if (count <= 0) {
      return topPadding + bottomPadding;
    }
    return topPadding + bottomPadding + nodeSize + (count - 1) * rowStride;
  }

  static double nodeCenterY(int index) {
    return topPadding + (index * rowStride) + (nodeSize * 0.5);
  }

  static double nodeCenterX(double width, int index) {
    final sideInset = (width * 0.14).clamp(26.0, 72.0);
    final centerLeft = (sideInset + (nodeSize * 0.5)).toDouble();
    final centerRight = (width - sideInset - (nodeSize * 0.5)).toDouble();
    return index.isOdd ? centerRight : centerLeft;
  }
}

class _JourneyTrack extends StatelessWidget {
  const _JourneyTrack({
    super.key,
    required this.steps,
    required this.onTap,
    this.currentLevelId,
  });

  final List<JourneyStep> steps;
  final ValueChanged<JourneyStep> onTap;
  final String? currentLevelId;

  @override
  Widget build(BuildContext context) {
    final displaySteps = steps.reversed.toList();
    final colors = MissionColors.resolve(Theme.of(context).brightness);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final points = List<Offset>.generate(displaySteps.length, (index) {
          return Offset(
            _JourneyTrackMetrics.nodeCenterX(width, index),
            _JourneyTrackMetrics.nodeCenterY(index),
          );
        });

        final currentIndex = currentLevelId == null
            ? null
            : displaySteps.indexWhere(
                (step) => step.level.id == currentLevelId,
              );
        final validCurrentIndex = (currentIndex != null && currentIndex >= 0)
            ? currentIndex
            : null;

        return SizedBox(
          height: _JourneyTrackMetrics.totalHeight(displaySteps.length),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _JourneySplinePainter(
                    points: points,
                    lineColor: colors.line.withValues(alpha: 0.72),
                    activeColor: MissionPalette.orange.withValues(alpha: 0.85),
                    currentIndex: validCurrentIndex,
                  ),
                ),
              ),
              for (var i = 0; i < displaySteps.length; i++) ...[
                _JourneyNodeSlot(
                  center: points[i],
                  step: displaySteps[i],
                  isCurrent: displaySteps[i].level.id == currentLevelId,
                  onTap: () => onTap(displaySteps[i]),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _JourneyNodeSlot extends StatelessWidget {
  const _JourneyNodeSlot({
    required this.center,
    required this.step,
    required this.isCurrent,
    required this.onTap,
  });

  final Offset center;
  final JourneyStep step;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = MissionColors.resolve(Theme.of(context).brightness);
    final badge = switch (step.level.type) {
      JourneyLevelType.checkpoint => 'MEMORIZE',
      JourneyLevelType.finalExam => 'MASTER',
      _ => null,
    };

    final label = switch (step.level.type) {
      JourneyLevelType.surahIntro => 'Intro',
      JourneyLevelType.verseLesson =>
        step.level.ayahId == null ? 'Verse' : 'Verse ${step.level.ayahId}',
      JourneyLevelType.checkpoint => 'Checkpoint',
      JourneyLevelType.finalExam => 'Final',
    };

    return Stack(
      children: [
        if (badge != null)
          Positioned(
            left: center.dx - 58,
            top: center.dy - (_JourneyTrackMetrics.nodeSize * 0.5) - 32,
            child: MissionStatusTag(
              label: badge,
              icon: Icons.military_tech_outlined,
            ),
          ),
        Positioned(
          left: center.dx - (_JourneyTrackMetrics.nodeSize * 0.5),
          top: center.dy - (_JourneyTrackMetrics.nodeSize * 0.5),
          child: _JourneyNode(step: step, isCurrent: isCurrent, onTap: onTap),
        ),
        Positioned(
          left: center.dx - 54,
          top: center.dy + (_JourneyTrackMetrics.nodeSize * 0.5) + 8,
          width: 108,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style:
                MissionText.micro(
                  isCurrent ? colors.textPrimary : colors.textSecondary,
                ).copyWith(
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _JourneyNode extends StatelessWidget {
  const _JourneyNode({
    required this.step,
    required this.isCurrent,
    required this.onTap,
  });

  final JourneyStep step;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = MissionColors.resolve(Theme.of(context).brightness);
    final locked = step.isLocked;
    final completed = step.isCompleted;

    final borderColor = locked
        ? colors.line
        : isCurrent
        ? MissionPalette.orange
        : colors.textPrimary;

    final fill = locked
        ? colors.surface.withValues(alpha: 0.84)
        : isCurrent
        ? colors.surfaceElevated
        : colors.surface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        width: _JourneyTrackMetrics.nodeSize,
        height: _JourneyTrackMetrics.nodeSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          border: Border.all(color: borderColor, width: isCurrent ? 2.1 : 1.2),
          boxShadow: [
            if (isCurrent)
              BoxShadow(
                color: MissionPalette.orange.withValues(alpha: 0.24),
                blurRadius: 16,
                offset: const Offset(0, 2),
              ),
            BoxShadow(
              color: colors.shadow,
              blurRadius: 0,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            MissionOrbitIcon(size: 52, opacity: locked ? 0.35 : 1),
            if (locked)
              Icon(Icons.lock, size: 21, color: colors.textPrimary)
            else if (completed)
              const Icon(
                Icons.check_circle,
                size: 22,
                color: MissionPalette.green,
              )
            else if (isCurrent)
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: MissionPalette.orange,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _JourneySplinePainter extends CustomPainter {
  const _JourneySplinePainter({
    required this.points,
    required this.lineColor,
    required this.activeColor,
    required this.currentIndex,
  });

  final List<Offset> points;
  final Color lineColor;
  final Color activeColor;
  final int? currentIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      return;
    }

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.4
      ..color = lineColor;

    final path = _buildPath(points);
    canvas.drawPath(path, basePaint);

    if (currentIndex == null || currentIndex! <= 0) {
      return;
    }

    final t = (currentIndex! / (points.length - 1)).clamp(0.0, 1.0);
    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.2
      ..color = activeColor;

    final metricsIterator = path.computeMetrics().iterator;
    if (!metricsIterator.moveNext()) {
      return;
    }
    final metric = metricsIterator.current;
    final activePath = metric.extractPath(0, metric.length * t);
    canvas.drawPath(activePath, activePaint);
  }

  Path _buildPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final dy = curr.dy - prev.dy;

      path.cubicTo(
        prev.dx,
        prev.dy + (dy * 0.45),
        curr.dx,
        curr.dy - (dy * 0.45),
        curr.dx,
        curr.dy,
      );
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _JourneySplinePainter oldDelegate) {
    if (lineColor != oldDelegate.lineColor ||
        activeColor != oldDelegate.activeColor ||
        currentIndex != oldDelegate.currentIndex ||
        points.length != oldDelegate.points.length) {
      return true;
    }

    for (var i = 0; i < points.length; i++) {
      if (points[i] != oldDelegate.points[i]) {
        return true;
      }
    }
    return false;
  }
}
