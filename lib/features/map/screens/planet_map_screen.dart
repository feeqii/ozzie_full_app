import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../child/providers/child_providers.dart';
import '../../child/ui/mission_buttons.dart';
import '../../child/ui/mission_card.dart';
import '../../child/ui/mission_orbit_icon.dart';
import '../../child/ui/mission_scaffold.dart';
import '../../child/ui/mission_speech_bubble.dart';
import '../../child/ui/mission_top_bar.dart';
import '../../child/ui/mission_tokens.dart';
import '../../parent/utils/parent_access_gate.dart';
import '../models/map_models.dart';
import '../providers/map_providers.dart';

class PlanetMapScreen extends ConsumerStatefulWidget {
  const PlanetMapScreen({super.key, required this.galaxyId});

  final int galaxyId;

  @override
  ConsumerState<PlanetMapScreen> createState() => _PlanetMapScreenState();
}

class _PlanetMapScreenState extends ConsumerState<PlanetMapScreen> {
  int? _selectedSurahId;
  bool _isStarting = false;

  @override
  Widget build(BuildContext context) {
    final mapAsync = ref.watch(mapStateProvider);
    final child = ref.watch(selectedChildProvider);
    final repo = ref.watch(mapRepositoryProvider);

    final colors = MissionColors.resolve(Theme.of(context).brightness);

    return MissionScaffold(
      extendToBottom: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MissionTopBar(
            child: child,
            showBack: true,
            onBack: () => context.pop(),
            onProgress: () => context.push('/child/progress'),
            onParentActions: () => openParentRouteWithPin(
              context: context,
              ref: ref,
              nextRoute: '/parent/dashboard',
            ),
          ),
          const SizedBox(height: MissionSpacing.md),
          Expanded(
            child: mapAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Text(
                  'Unable to load this zone.',
                  style: MissionText.body(colors.textSecondary),
                ),
              ),
              data: (mapState) {
                final galaxy = _findGalaxy(mapState);
                if (galaxy == null) {
                  return Center(
                    child: Text(
                      'Galaxy not found.',
                      style: MissionText.body(colors.textSecondary),
                    ),
                  );
                }

                final surahs = [...galaxy.surahs]
                  ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

                if (surahs.isEmpty) {
                  return Center(
                    child: Text(
                      'No missions in this zone yet.',
                      style: MissionText.body(colors.textSecondary),
                    ),
                  );
                }

                _selectedSurahId ??= _initialSurahSelection(surahs);
                if (!surahs.any((surah) => surah.id == _selectedSurahId)) {
                  _selectedSurahId = _initialSurahSelection(surahs);
                }

                final selected = surahs.firstWhere(
                  (surah) => surah.id == _selectedSurahId,
                );

                final bubbleText = selected.locked
                    ? '${selected.name} is locked for now. Finish the earlier mission first.'
                    : selected.isCompleted
                    ? '${selected.name} is completed. You can revisit it anytime.'
                    : '${selected.name} is waiting. Start your journey now.';
                final buttonLabel = selected.locked
                    ? 'Locked'
                    : selected.isCompleted
                    ? 'Review mission'
                    : 'Start mission';
                final buttonDisabled = selected.locked || _isStarting;

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: MissionSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Text(
                          galaxy.nameEn.toUpperCase(),
                          style: MissionText.title(
                            colors.textPrimary,
                          ).copyWith(fontSize: 20),
                        ),
                      ),
                      if ((galaxy.nameAr ?? '').isNotEmpty)
                        Center(
                          child: Text(
                            galaxy.nameAr!,
                            style: MissionText.body(colors.textSecondary),
                          ),
                        ),
                      const SizedBox(height: MissionSpacing.md),
                      SizedBox(
                        height: 330,
                        child: _SurahOrbit(
                          surahs: surahs,
                          selectedSurahId: selected.id,
                          onSelect: (surahId) =>
                              setState(() => _selectedSurahId = surahId),
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          final curved = CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          );
                          return FadeTransition(
                            opacity: curved,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.03),
                                end: Offset.zero,
                              ).animate(curved),
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey<int>(selected.id),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: MissionSpacing.sm),
                              MissionSpeechBubble(text: bubbleText),
                              const SizedBox(height: MissionSpacing.md),
                              MissionCard(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      selected.name,
                                      style: MissionText.heading(
                                        colors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: MissionSpacing.xs),
                                    Text(
                                      selected.translation,
                                      style: MissionText.body(
                                        colors.textSecondary,
                                      ),
                                    ),
                                    if (selected.ayahCount != null) ...[
                                      const SizedBox(height: MissionSpacing.sm),
                                      Text(
                                        '${selected.ayahCount} ayahs',
                                        style: MissionText.micro(
                                          colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: MissionSpacing.md),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      transitionBuilder: (child, animation) {
                                        final curved = CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeOutCubic,
                                        );
                                        return FadeTransition(
                                          opacity: curved,
                                          child: SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(0, 0.04),
                                              end: Offset.zero,
                                            ).animate(curved),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: KeyedSubtree(
                                        key: ValueKey<String>(
                                          '${selected.id}-$buttonLabel-$buttonDisabled',
                                        ),
                                        child: MissionButton(
                                          label: buttonLabel,
                                          onPressed: buttonDisabled
                                              ? null
                                              : () async {
                                                  final selectedChild = child;
                                                  if (selectedChild == null) {
                                                    return;
                                                  }

                                                  setState(
                                                    () => _isStarting = true,
                                                  );
                                                  try {
                                                    if (!selected.isActive &&
                                                        !selected.isCompleted) {
                                                      await repo.startSurah(
                                                        childId:
                                                            selectedChild.id,
                                                        surahId: selected.id,
                                                      );
                                                      ref.invalidate(
                                                        mapStateProvider,
                                                      );
                                                    }
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    context.push(
                                                      '/child/surah/${selected.id}',
                                                    );
                                                  } catch (_) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Could not start mission. Please try again.',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  } finally {
                                                    if (mounted) {
                                                      setState(
                                                        () =>
                                                            _isStarting = false,
                                                      );
                                                    }
                                                  }
                                                },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  GalaxyNode? _findGalaxy(MapState? mapState) {
    if (mapState == null) {
      return null;
    }
    for (final galaxy in mapState.galaxies) {
      if (galaxy.id == widget.galaxyId) {
        return galaxy;
      }
    }
    return null;
  }

  int _initialSurahSelection(List<SurahNode> surahs) {
    for (final surah in surahs) {
      if (surah.isActive) {
        return surah.id;
      }
    }
    for (final surah in surahs) {
      if (!surah.locked) {
        return surah.id;
      }
    }
    return surahs.first.id;
  }
}

class _SurahOrbit extends StatelessWidget {
  const _SurahOrbit({
    required this.surahs,
    required this.selectedSurahId,
    required this.onSelect,
  });

  final List<SurahNode> surahs;
  final int selectedSurahId;
  final ValueChanged<int> onSelect;

  void _stepSelection(double velocityX) {
    if (surahs.length <= 1) {
      return;
    }

    final currentIndex = surahs.indexWhere(
      (surah) => surah.id == selectedSurahId,
    );
    if (currentIndex == -1) {
      return;
    }

    final delta = velocityX < 0 ? 1 : -1;
    final nextIndex = (currentIndex + delta).clamp(0, surahs.length - 1);
    if (nextIndex == currentIndex) {
      return;
    }

    onSelect(surahs[nextIndex].id);
  }

  @override
  Widget build(BuildContext context) {
    final colors = MissionColors.resolve(Theme.of(context).brightness);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final velocityX = details.velocity.pixelsPerSecond.dx;
        if (velocityX.abs() < 240) {
          return;
        }
        _stepSelection(velocityX);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final center = Offset(
            constraints.maxWidth / 2,
            constraints.maxHeight / 2 - 8,
          );
          final radiusX = constraints.maxWidth * 0.36;
          final radiusY = constraints.maxHeight * 0.28;
          final selectedIndex = surahs.indexWhere(
            (surah) => surah.id == selectedSurahId,
          );
          final selectedTheta = selectedIndex <= 0
              ? -math.pi / 2
              : ((selectedIndex / surahs.length) * (math.pi * 2) - math.pi / 2);
          final cometTheta = surahs.length <= 1
              ? selectedTheta
              : selectedTheta - 0.12;
          const cometSize = 12.0;
          final cometX = center.dx + math.cos(cometTheta) * radiusX;
          final cometY = center.dy + math.sin(cometTheta) * radiusY;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _OrbitPainter(
                    center: center,
                    radiusX: radiusX,
                    radiusY: radiusY,
                    color: colors.line.withValues(alpha: 0.5),
                  ),
                ),
              ),
              Positioned(
                left: center.dx - 54,
                top: center.dy - 54,
                child: Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        MissionPalette.blue.withValues(alpha: 0.92),
                        MissionPalette.green.withValues(alpha: 0.92),
                      ],
                    ),
                    border: Border.all(color: colors.textPrimary, width: 1.2),
                  ),
                  child: const Center(
                    child: MissionOrbitIcon(
                      size: 66,
                      color: MissionPalette.light,
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 430),
                curve: Curves.easeInOutCubic,
                left: cometX - (cometSize / 2),
                top: cometY - (cometSize / 2),
                child: IgnorePointer(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey<int>(selectedSurahId),
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    tween: Tween(begin: 0.82, end: 1),
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: Container(
                      width: cometSize,
                      height: cometSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [MissionPalette.orange, MissionPalette.green],
                        ),
                        border: Border.all(
                          color: colors.surfaceElevated,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: MissionPalette.orange.withValues(
                              alpha: 0.24,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              for (var i = 0; i < surahs.length; i++)
                _OrbitNode(
                  surah: surahs[i],
                  index: i,
                  total: surahs.length,
                  selected: surahs[i].id == selectedSurahId,
                  center: center,
                  radiusX: radiusX,
                  radiusY: radiusY,
                  onSelect: onSelect,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _OrbitNode extends StatelessWidget {
  const _OrbitNode({
    required this.surah,
    required this.index,
    required this.total,
    required this.selected,
    required this.center,
    required this.radiusX,
    required this.radiusY,
    required this.onSelect,
  });

  final SurahNode surah;
  final int index;
  final int total;
  final bool selected;
  final Offset center;
  final double radiusX;
  final double radiusY;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = MissionColors.resolve(Theme.of(context).brightness);

    final theta = total == 1
        ? 0.0
        : ((index / total) * (math.pi * 2) - math.pi / 2);
    final x = center.dx + math.cos(theta) * radiusX;
    final y = center.dy + math.sin(theta) * radiusY;

    return Positioned(
      left: x - 24,
      top: y - 24,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelect(surah.id),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 230),
              curve: Curves.easeOutBack,
              scale: selected ? 1 : 0.93,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 230),
                curve: Curves.easeOutCubic,
                width: selected ? 54 : 48,
                height: selected ? 54 : 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.surface,
                  border: Border.all(
                    color: selected
                        ? MissionPalette.orange
                        : colors.line.withValues(alpha: 0.7),
                    width: selected ? 1.7 : 1.0,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: MissionPalette.orange.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    scale: selected ? 1 : 0.92,
                    child: MissionOrbitIcon(
                      size: selected ? 31 : 27,
                      opacity: surah.locked ? 0.4 : 0.95,
                    ),
                  ),
                ),
              ),
            ),
            if (surah.locked)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.surface,
                  border: Border.all(color: colors.textPrimary, width: 1),
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 12,
                  color: colors.textPrimary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({
    required this.center,
    required this.radiusX,
    required this.radiusY,
    required this.color,
  });

  final Offset center;
  final double radiusX;
  final double radiusY;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: center,
      width: radiusX * 2,
      height: radiusY * 2,
    );

    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) {
    return center != oldDelegate.center ||
        radiusX != oldDelegate.radiusX ||
        radiusY != oldDelegate.radiusY ||
        color != oldDelegate.color;
  }
}
