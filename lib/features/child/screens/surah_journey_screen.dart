import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/ui/app_app_bar.dart';
import '../../../core/ui/cosmic_background.dart';
import '../../../core/ui/atlas_illustrations.dart';
import '../../../core/ui/illustration_frame.dart';
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
    final surfaces = context.surfaces;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: surfaces.canvas,
      appBar: const AppAppBar(
        title: 'Journey',
        variant: AppAppBarVariant.overlay,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          const CosmicBackground(parallax: 0),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: mapAsync.when(
                data: (mapState) {
                  final surahNode = mapState?.findSurah(surahId);
                  final title = surahNode?.name.isNotEmpty == true ? surahNode!.name : 'Surah $surahId';

                  if (surahNode != null && !surahNode.playable) {
                    return Center(
                      child: _GlassPanel(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Content not available yet.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              PrimaryButton(
                                label: 'Back',
                                onPressed: () => context.pop(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return stepsAsync.when(
                    data: (stepsRaw) {
                      final steps = [...stepsRaw]..sort((a, b) => a.level.orderIndex.compareTo(b.level.orderIndex));
                      final allLocked = steps.isNotEmpty && steps.every((step) => step.progress.status == JourneyLevelStatus.locked);
                      final canStart = child != null && (surahNode?.locked != true);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Follow the constellation. Master every step.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.84)),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          if (allLocked) ...[
                            _GlassPanel(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Start this surah',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      surahNode?.locked == true
                                          ? 'No slots available. Complete an active surah to unlock.'
                                          : 'This unlocks your first level.',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    PrimaryButton(
                                      label: 'Begin',
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
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                          Expanded(
                            child: _JourneyPathMap(
                              steps: steps,
                              onTap: (step) async {
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
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => Center(
                      child: Text(
                        'Unable to load journey.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Text(
                    'Unable to load map state.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLocked(BuildContext context, JourneyStep step) {
    final lockedUntil = step.progress.lockedUntil;
    final message = lockedUntil != null ? 'Try again tomorrow.' : 'Complete the previous step to unlock this.';
    HapticFeedback.mediumImpact();
    return ModalSheetTrigger.show(
      context,
      sheet: ModalSheet(
        title: 'Locked',
        message: message,
        variant: ModalSheetVariant.info,
        illustration: const IllustrationFrame(
          size: 150,
          child: AtlasIllustration(kind: AtlasIllustrationKind.locked),
        ),
        primaryAction: PrimaryButton(
          label: 'Okay',
          onPressed: () => context.pop(),
        ),
      ),
    );
  }
}

class _JourneyPathMap extends StatelessWidget {
  const _JourneyPathMap({
    required this.steps,
    required this.onTap,
  });

  final List<JourneyStep> steps;
  final Future<void> Function(JourneyStep step) onTap;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return Center(
        child: Text(
          'No steps yet.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final gap = 160.0;
        final nodeSize = (w * 0.22).clamp(78.0, 96.0);
        final top = nodeSize * 0.7;
        final bottom = nodeSize * 0.8;

        final height = top + (steps.length - 1) * gap + bottom;
        final cx = w / 2;
        final amplitude = w * 0.30;
        final waves = 2.0;

        final points = <Offset>[];
        for (var i = 0; i < steps.length; i++) {
          final t = steps.length == 1 ? 0.5 : (i / (steps.length - 1));
          final x = cx + math.sin(t * math.pi * waves) * amplitude;
          final y = top + i * gap;
          points.add(Offset(x, y));
        }

        final unlockedUntil = _furthestUnlockedIndex(steps);

        return SingleChildScrollView(
          child: SizedBox(
            height: math.max(constraints.maxHeight, height),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _JourneyPathPainter(
                      points: points,
                      unlockedUntil: unlockedUntil,
                      glow: context.surfaces.mapGlow,
                    ),
                  ),
                ),
                for (var i = 0; i < steps.length; i++)
                  Positioned(
                    left: points[i].dx - nodeSize / 2,
                    top: points[i].dy - nodeSize / 2,
                    width: nodeSize,
                    child: _JourneyNode(
                      step: steps[i],
                      index: i,
                      size: nodeSize,
                      onTap: () => onTap(steps[i]),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _furthestUnlockedIndex(List<JourneyStep> steps) {
    var furthest = -1;
    for (var i = 0; i < steps.length; i++) {
      if (steps[i].isUnlocked || steps[i].isCompleted) {
        furthest = i;
      }
    }
    return furthest;
  }
}

class _JourneyPathPainter extends CustomPainter {
  _JourneyPathPainter({
    required this.points,
    required this.unlockedUntil,
    required this.glow,
  });

  final List<Offset> points;
  final int unlockedUntil;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final dimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = Colors.white.withValues(alpha: 0.14);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..color = glow.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      path.quadraticBezierTo(p1.dx, p1.dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, dimPaint);

    if (unlockedUntil < 0) return;

    final brightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.4
      ..color = glow.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final bright = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < math.min(unlockedUntil, points.length - 1); i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      bright.quadraticBezierTo(p1.dx, p1.dy, mid.dx, mid.dy);
    }
    canvas.drawPath(bright, brightPaint);
  }

  @override
  bool shouldRepaint(covariant _JourneyPathPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.unlockedUntil != unlockedUntil || oldDelegate.glow != glow;
  }
}

class _JourneyNode extends StatelessWidget {
  const _JourneyNode({
    required this.step,
    required this.index,
    required this.size,
    required this.onTap,
  });

  final JourneyStep step;
  final int index;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glow = context.surfaces.mapGlow;
    final locked = step.isLocked;
    final completed = step.isCompleted;

    final label = _label(step.level);
    final status = _status(step.progress.status);

    final icon = _icon(step.level);

    return AnimatedOpacity(
      duration: context.motion.medium,
      opacity: locked ? 0.55 : 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: locked ? null : onTap,
              customBorder: const CircleBorder(),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!locked)
                    Container(
                      height: size,
                      width: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: glow.withValues(alpha: completed ? 0.35 : 0.22),
                            blurRadius: 22,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  Container(
                    height: size,
                    width: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: locked ? 0.10 : 0.14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: locked ? 0.12 : 0.22),
                        width: 1.6,
                      ),
                    ),
                  ),
                  Icon(icon, color: Colors.white, size: 26),
                  if (locked)
                    const Positioned(
                      bottom: 10,
                      child: Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                    ),
                  if (!locked && completed)
                    Positioned(
                      bottom: 10,
                      child: Icon(Icons.verified_rounded, color: glow.withValues(alpha: 0.95), size: 18),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _GlassPanel(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                          letterSpacing: 0.5,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _icon(JourneyLevel level) {
    switch (level.type) {
      case JourneyLevelType.surahIntro:
        return Icons.menu_book_rounded;
      case JourneyLevelType.verseLesson:
        return Icons.auto_stories_rounded;
      case JourneyLevelType.checkpoint:
        return Icons.flash_on_rounded;
      case JourneyLevelType.finalExam:
        return Icons.military_tech_rounded;
    }
  }

  String _label(JourneyLevel level) {
    switch (level.type) {
      case JourneyLevelType.surahIntro:
        return 'INTRO';
      case JourneyLevelType.verseLesson:
        return level.ayahId == null ? 'VERSE' : 'VERSE ${level.ayahId}';
      case JourneyLevelType.checkpoint:
        return level.quizType == 'mini_1'
            ? 'MEMORIZE I'
            : level.quizType == 'mini_2'
                ? 'MEMORIZE II'
                : 'CHECKPOINT';
      case JourneyLevelType.finalExam:
        return 'MASTER';
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

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16), width: 1.4),
      ),
      child: child,
    );
  }
}
