import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/ui/app_app_bar.dart';
import '../../../core/ui/cosmic_background.dart';
import '../../../core/ui/modal_sheet.dart';
import '../../../core/ui/primary_button.dart';
import '../../child/providers/child_providers.dart';
import '../models/map_models.dart';
import '../providers/map_providers.dart';

class PlanetMapScreen extends ConsumerWidget {
  const PlanetMapScreen({super.key, required this.galaxyId});

  final int galaxyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapAsync = ref.watch(mapStateProvider);
    final selectedChild = ref.watch(selectedChildProvider);
    final repo = ref.watch(mapRepositoryProvider);
    final surfaces = context.surfaces;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: surfaces.canvas,
      appBar: const AppAppBar(
        title: 'Planets',
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
                data: (state) {
                  if (state == null) {
                    return Center(
                      child: Text(
                        'Select a child to continue.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
                      ),
                    );
                  }

                  GalaxyNode? galaxy;
                  for (final item in state.galaxies) {
                    if (item.id == galaxyId) {
                      galaxy = item;
                      break;
                    }
                  }
                  if (galaxy == null) {
                    return Center(
                      child: Text(
                        'Galaxy not found.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
                      ),
                    );
                  }

                  final galaxyNode = galaxy;
                  final surahs = [...galaxyNode.surahs]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        galaxyNode.nameEn.isNotEmpty ? '${galaxyNode.nameEn} Galaxy' : 'Galaxy',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(color: Colors.white),
                      ),
                      if ((galaxyNode.nameAr ?? '').isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          galaxyNode.nameAr!,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        state.slotsRemaining == 0
                            ? 'No slots left. Complete an active surah to unlock more.'
                            : '${state.slotsRemaining} active surah slots available',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.82)),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Expanded(
                        child: _PlanetOrbit(
                          surahs: surahs,
                          onTap: (surah) async {
                            if (surah.locked || selectedChild == null) return;

                            if (!surah.isActive && !surah.isCompleted) {
                              try {
                                await repo.startSurah(childId: selectedChild.id, surahId: surah.id);
                                ref.invalidate(mapStateProvider);
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
                                return;
                              }
                            }

                            if (!context.mounted) return;
                            context.push('/child/surah/${surah.id}');
                          },
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Text(
                    'Unable to load planets.',
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
}

typedef _PlanetTap = Future<void> Function(SurahNode surah);

class _PlanetOrbit extends StatelessWidget {
  const _PlanetOrbit({
    required this.surahs,
    required this.onTap,
  });

  final List<SurahNode> surahs;
  final _PlanetTap onTap;

  @override
  Widget build(BuildContext context) {
    final glow = context.surfaces.mapGlow;
    final fog = context.surfaces.mapFog;

    if (surahs.isEmpty) {
      return Center(
        child: Text(
          'No planets found.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final w = size.width;
        final h = size.height;

        final nodeSize = (w * 0.22).clamp(74.0, 96.0);
        final top = nodeSize * 0.15;
        final bottom = nodeSize * 0.15;
        final usableH = (h - top - bottom).clamp(1, h);

        final cx = w / 2;
        final amplitude = w * 0.32;
        final waves = 2.0;

        final points = <Offset>[];
        for (var i = 0; i < surahs.length; i++) {
          final t = surahs.length == 1 ? 0.5 : (i / (surahs.length - 1));
          final x = cx + math.sin(t * math.pi * waves) * amplitude;
          final y = top + t * usableH;
          points.add(Offset(x, y));
        }

        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _OrbitPainter(
                  points: points,
                  glow: glow,
                  fog: fog,
                ),
              ),
            ),
            for (var i = 0; i < surahs.length; i++)
              Positioned(
                left: points[i].dx - nodeSize / 2,
                top: points[i].dy - nodeSize / 2,
                width: nodeSize,
                child: _PlanetNode(
                  surah: surahs[i],
                  size: nodeSize,
                  onTap: () => onTap(surahs[i]),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter({
    required this.points,
    required this.glow,
    required this.fog,
  });

  final List<Offset> points;
  final Color glow;
  final Color fog;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.14);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
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
    canvas.drawPath(path, base);
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.glow != glow || oldDelegate.fog != fog;
  }
}

class _PlanetNode extends StatelessWidget {
  const _PlanetNode({
    required this.surah,
    required this.size,
    required this.onTap,
  });

  final SurahNode surah;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glow = context.surfaces.mapGlow;

    final locked = surah.locked;
    final active = surah.isActive;
    final completed = surah.isCompleted;

    final label = completed
        ? 'Completed'
        : active
            ? 'Active'
            : locked
                ? _reasonLabel(surah.lockReason)
                : 'Available';

    final title = surah.name.isNotEmpty ? surah.name : 'Surah ${surah.id}';

    return AnimatedOpacity(
      duration: context.motion.medium,
      opacity: locked ? 0.55 : 1,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: locked ? null : onTap,
              customBorder: const CircleBorder(),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (active)
                    Container(
                      height: size,
                      width: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: glow.withValues(alpha: 0.30),
                            blurRadius: 24,
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
                      gradient: locked
                          ? RadialGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.12),
                                Colors.white.withValues(alpha: 0.05),
                              ],
                            )
                          : RadialGradient(
                              colors: [
                                glow.withValues(alpha: completed ? 0.25 : 0.22),
                                Colors.white.withValues(alpha: 0.10),
                              ],
                              stops: const [0, 1],
                            ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: locked ? 0.14 : 0.22),
                        width: 1.6,
                      ),
                    ),
                  ),
                  Text(
                    '${surah.orderIndex}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 22,
                          height: 1,
                        ),
                  ),
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
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                  letterSpacing: 0.5,
                ),
          ),
        ],
      ),
    );
  }

  String _reasonLabel(String? reason) {
    switch (reason) {
      case 'NO_SLOTS':
        return 'No slots';
      case 'COMING_SOON':
        return 'Coming soon';
      case 'GALAXY_LOCKED':
        return 'Galaxy locked';
      default:
        return 'Locked';
    }
  }
}

