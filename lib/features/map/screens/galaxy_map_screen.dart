import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/ui/app_app_bar.dart';
import '../../../core/ui/cosmic_background.dart';
import '../../../core/ui/label_chip.dart';
import '../../../core/ui/primary_button.dart';
import '../../map/models/map_models.dart';
import '../providers/map_providers.dart';

class GalaxyMapScreen extends ConsumerStatefulWidget {
  const GalaxyMapScreen({super.key});

  @override
  ConsumerState<GalaxyMapScreen> createState() => _GalaxyMapScreenState();
}

class _GalaxyMapScreenState extends ConsumerState<GalaxyMapScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.86);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapAsync = ref.watch(mapStateProvider);
    final surfaces = context.surfaces;

    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, _) {
        final page = (_pageController.hasClients
            ? (_pageController.page ?? _pageController.initialPage.toDouble())
            : 0.0);
        final parallax = -page * 34;

        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: surfaces.canvas,
          appBar: const AppAppBar(
            title: 'Galaxies',
            variant: AppAppBarVariant.overlay,
            foregroundColor: Colors.white,
          ),
          body: Stack(
            children: [
              CosmicBackground(parallax: parallax),
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

                      final galaxies = [...state.galaxies]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
                      if (galaxies.isEmpty) {
                        return Center(
                          child: Text(
                            'No galaxies available.',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              LabelChip(
                                label: '${state.slotsRemaining} slots left',
                                background: Colors.white.withValues(alpha: 0.12),
                                borderColor: Colors.white.withValues(alpha: 0.18),
                                foregroundColor: Colors.white,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              LabelChip(
                                label: 'Swipe to explore',
                                background: Colors.white.withValues(alpha: 0.12),
                                borderColor: Colors.white.withValues(alpha: 0.18),
                                foregroundColor: Colors.white,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Expanded(
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: galaxies.length,
                              itemBuilder: (context, index) {
                                final galaxy = galaxies[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                  child: _GalaxyMedallion(
                                    galaxy: galaxy,
                                    slotsRemaining: state.slotsRemaining,
                                    onEnter: galaxy.unlocked ? () => context.push('/child/map/galaxy/${galaxy.id}') : null,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => Center(
                      child: Text(
                        'Unable to load map.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GalaxyMedallion extends StatelessWidget {
  const _GalaxyMedallion({
    required this.galaxy,
    required this.slotsRemaining,
    required this.onEnter,
  });

  final GalaxyNode galaxy;
  final int slotsRemaining;
  final VoidCallback? onEnter;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final isLocked = !galaxy.unlocked;
    final isCompleted = galaxy.completed;

    final title = galaxy.nameEn.isNotEmpty ? galaxy.nameEn : 'Galaxy ${galaxy.orderIndex}';

    return AnimatedOpacity(
      duration: context.motion.medium,
      opacity: isLocked ? 0.55 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.20),
            width: 1.6,
          ),
          color: Colors.white.withValues(alpha: 0.10),
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _Badge(
                          label: 'GALAXY ${galaxy.orderIndex}',
                          glow: isLocked ? null : surfaces.mapGlow,
                        ),
                        const Spacer(),
                        if (isCompleted)
                          _Badge(
                            label: 'STAMPED',
                            glow: surfaces.mapGlow,
                            icon: Icons.verified_rounded,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _GalaxyCoin(
                          index: galaxy.orderIndex,
                          locked: isLocked,
                          completed: isCompleted,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: Colors.white,
                            height: 1.0,
                          ),
                    ),
                    if ((galaxy.nameAr ?? '').isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        galaxy.nameAr!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      isLocked
                          ? 'Locked. Complete the previous galaxy to unlock.'
                          : isCompleted
                              ? 'Completed. You can revisit any planet.'
                              : 'Unlocked. Choose a planet to begin.',
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: isLocked ? 'Locked' : 'Enter galaxy',
              isDisabled: isLocked,
              onPressed: onEnter,
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    this.icon,
    this.glow,
  });

  final String label;
  final IconData? icon;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1.2),
        boxShadow: glow == null
            ? const []
            : [
                BoxShadow(
                  color: glow!.withValues(alpha: 0.22),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.90),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
          ),
        ],
      ),
    );
  }
}

class _GalaxyCoin extends StatelessWidget {
  const _GalaxyCoin({
    required this.index,
    required this.locked,
    required this.completed,
  });

  final int index;
  final bool locked;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final glow = context.surfaces.mapGlow;
    final size = 220.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withValues(alpha: locked ? 0.12 : 0.18),
                Colors.white.withValues(alpha: locked ? 0.05 : 0.10),
                Colors.transparent,
              ],
              stops: const [0, 0.65, 1],
            ),
          ),
        ),
        Container(
          height: size * 0.86,
          width: size * 0.86,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                glow.withValues(alpha: locked ? 0.12 : 0.36),
                Colors.white.withValues(alpha: locked ? 0.05 : 0.12),
                glow.withValues(alpha: locked ? 0.12 : 0.36),
              ],
              stops: const [0, 0.5, 1],
              transform: GradientRotation(index * math.pi / 6),
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: locked ? 0.12 : 0.22),
              width: 1.6,
            ),
          ),
          child: Center(
            child: Text(
              '$index',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 72,
                    letterSpacing: -1,
                    height: 1,
                  ),
            ),
          ),
        ),
        if (locked)
          const Icon(
            Icons.lock_rounded,
            color: Colors.white,
            size: 34,
          ),
        if (!locked && completed)
          Icon(
            Icons.verified_rounded,
            color: glow.withValues(alpha: 0.95),
            size: 34,
          ),
      ],
    );
  }
}
