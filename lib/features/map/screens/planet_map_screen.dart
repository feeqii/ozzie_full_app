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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.md,
                        ),
                        child: Column(
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
                          ],
                        ),
                      ),
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
        final w = constraints.maxWidth;
        final viewportH = constraints.maxHeight;

        // Big, thumb-first planets. We allow scroll so these can stay large.
        final nodeSize = (w * 0.46).clamp(150.0, 176.0);
        final labelWidth = math.min(w - AppSpacing.lg, nodeSize * 1.65);
        final labelHeight = 54.0;

        final gap = nodeSize + 88;
        final contentH = math.max(
          viewportH,
          (surahs.length - 1) * gap + nodeSize + labelHeight + AppSpacing.xl,
        );

        // Bottom-up reading: easiest/first planet at the bottom.
        final surahsDisplay = surahs.reversed.toList(growable: false);

        final cx = w / 2;
        final side = AppSpacing.sm.toDouble();
        final amplitude = math.max(0.0, (w - labelWidth - side * 2) / 2);
        final waves = 2.0;

        final points = <Offset>[];
        for (var i = 0; i < surahsDisplay.length; i++) {
          final t = surahsDisplay.length == 1 ? 0.5 : (i / (surahsDisplay.length - 1));
          final x = cx + math.sin(t * math.pi * waves) * amplitude;
          final y = AppSpacing.md + t * (contentH - nodeSize - labelHeight - AppSpacing.xl);
          points.add(Offset(x, y));
        }

        return _PlanetOrbitScroll(
          contentHeight: contentH,
          points: points,
          glow: glow,
          fog: fog,
          nodes: [
            for (var i = 0; i < surahsDisplay.length; i++)
              _PlanetNodeSpec(
                surah: surahsDisplay[i],
                center: points[i],
              ),
          ],
          nodeSize: nodeSize,
          labelWidth: labelWidth,
          labelHeight: labelHeight,
          onTap: onTap,
        );
      },
    );
  }
}

class _PlanetNodeSpec {
  const _PlanetNodeSpec({
    required this.surah,
    required this.center,
  });

  final SurahNode surah;
  final Offset center;
}

class _PlanetOrbitScroll extends StatefulWidget {
  const _PlanetOrbitScroll({
    required this.contentHeight,
    required this.points,
    required this.glow,
    required this.fog,
    required this.nodes,
    required this.nodeSize,
    required this.labelWidth,
    required this.labelHeight,
    required this.onTap,
  });

  final double contentHeight;
  final List<Offset> points;
  final Color glow;
  final Color fog;
  final List<_PlanetNodeSpec> nodes;
  final double nodeSize;
  final double labelWidth;
  final double labelHeight;
  final _PlanetTap onTap;

  @override
  State<_PlanetOrbitScroll> createState() => _PlanetOrbitScrollState();
}

class _PlanetOrbitScrollState extends State<_PlanetOrbitScroll> {
  late final ScrollController _controller;
  bool _jumped = false;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Always open the map near the "start" (bottom) so kids see the next action first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _jumped) return;
      if (!_controller.hasClients) return;
      _jumped = true;
      _controller.jumpTo(_controller.position.maxScrollExtent);
    });

    return Scrollbar(
      controller: _controller,
      child: SingleChildScrollView(
        controller: _controller,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        child: SizedBox(
          height: widget.contentHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _OrbitPainter(
                    points: widget.points,
                    glow: widget.glow,
                    fog: widget.fog,
                  ),
                ),
              ),
              for (final node in widget.nodes)
                Positioned(
                  left: node.center.dx - widget.labelWidth / 2,
                  top: node.center.dy - widget.nodeSize / 2,
                  width: widget.labelWidth,
                  child: _PlanetNode(
                    surah: node.surah,
                    size: widget.nodeSize,
                    labelWidth: widget.labelWidth,
                    labelHeight: widget.labelHeight,
                    onTap: () => widget.onTap(node.surah),
                  ),
                ),
            ],
          ),
        ),
      ),
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
    required this.labelWidth,
    required this.labelHeight,
    required this.onTap,
  });

  final SurahNode surah;
  final double size;
  final double labelWidth;
  final double labelHeight;
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
                          fontSize: (size * 0.15).clamp(20.0, 28.0),
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
          SizedBox(
            width: labelWidth,
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                    fontSize: (size * 0.11).clamp(16.0, 20.0),
                  ),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: labelWidth,
            height: labelHeight,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                    letterSpacing: 0.5,
                    height: 1.1,
                  ),
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
