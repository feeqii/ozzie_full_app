import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../child/providers/child_providers.dart';
import '../../child/ui/mission_buttons.dart';
import '../../child/ui/mission_orbit_icon.dart';
import '../../child/ui/mission_scaffold.dart';
import '../../child/ui/mission_speech_bubble.dart';
import '../../child/ui/mission_status_tag.dart';
import '../../child/ui/mission_top_bar.dart';
import '../../child/ui/mission_tokens.dart';
import '../../parent/utils/parent_access_gate.dart';
import '../models/map_models.dart';
import '../providers/map_providers.dart';

class GalaxyMapScreen extends ConsumerStatefulWidget {
  const GalaxyMapScreen({super.key});

  @override
  ConsumerState<GalaxyMapScreen> createState() => _GalaxyMapScreenState();
}

class _GalaxyMapScreenState extends ConsumerState<GalaxyMapScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final mapAsync = ref.watch(mapStateProvider);
    final child = ref.watch(selectedChildProvider);

    final colors = MissionColors.resolve(Theme.of(context).brightness);

    return MissionScaffold(
      extendToBottom: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MissionTopBar(
            child: child,
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
                  'Unable to load map right now.',
                  style: MissionText.body(colors.textSecondary),
                ),
              ),
              data: (mapState) {
                if (mapState == null || mapState.galaxies.isEmpty) {
                  return Center(
                    child: Text(
                      'No galaxy map available yet.',
                      style: MissionText.body(colors.textSecondary),
                    ),
                  );
                }

                final galaxies = [...mapState.galaxies]
                  ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

                if (_selectedIndex >= galaxies.length) {
                  _selectedIndex = galaxies.length - 1;
                }

                final selected = galaxies[_selectedIndex];
                final subtitle = selected.unlocked
                    ? selected.completed
                          ? 'Completed zone. You can revisit any surah.'
                          : 'Zone unlocked. Tap to continue your journey.'
                    : 'This zone is locked until the previous one is complete.';

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: MissionSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MissionSpeechBubble(
                        text: selected.unlocked
                            ? '${selected.nameEn} is ready. Pick a route and keep going.'
                            : '${selected.nameEn} is still locked. Complete earlier missions first.',
                      ),
                      const SizedBox(height: MissionSpacing.md),
                      Center(
                        child: GestureDetector(
                          onTap: selected.unlocked
                              ? () => context.push(
                                  '/child/map/galaxy/${selected.id}',
                                )
                              : null,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colors.surface,
                                  border: Border.all(
                                    color: colors.line.withValues(alpha: 0.4),
                                    width: 1.2,
                                  ),
                                ),
                              ),
                              MissionOrbitIcon(
                                size: 136,
                                opacity: selected.unlocked ? 1 : 0.45,
                              ),
                              if (!selected.unlocked)
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colors.surface,
                                    border: Border.all(
                                      color: colors.textPrimary,
                                      width: 1.1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.lock_rounded,
                                    color: colors.textPrimary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: MissionSpacing.md),
                      Center(
                        child: Text(
                          selected.nameEn.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: MissionText.title(
                            colors.textPrimary,
                          ).copyWith(fontSize: 20),
                        ),
                      ),
                      if ((selected.nameAr ?? '').isNotEmpty)
                        Center(
                          child: Text(
                            selected.nameAr!,
                            style: MissionText.body(colors.textSecondary),
                          ),
                        ),
                      const SizedBox(height: MissionSpacing.sm),
                      Center(
                        child: MissionStatusTag(
                          label: mapState.slotsRemaining > 0
                              ? '${mapState.slotsRemaining} active slots left'
                              : 'No free active slots',
                          icon: Icons.auto_awesome,
                        ),
                      ),
                      const SizedBox(height: MissionSpacing.md),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: MissionText.body(colors.textSecondary),
                      ),
                      const SizedBox(height: MissionSpacing.lg),
                      _GalaxySelectorRow(
                        galaxies: galaxies,
                        selectedIndex: _selectedIndex,
                        onSelect: (index) =>
                            setState(() => _selectedIndex = index),
                      ),
                      const SizedBox(height: MissionSpacing.xl),
                      MissionButton(
                        label: selected.unlocked
                            ? 'Enter ${selected.nameEn}'
                            : 'Zone locked',
                        onPressed: selected.unlocked
                            ? () => context.push(
                                '/child/map/galaxy/${selected.id}',
                              )
                            : null,
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
}

class _GalaxySelectorRow extends StatelessWidget {
  const _GalaxySelectorRow({
    required this.galaxies,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<GalaxyNode> galaxies;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = MissionColors.resolve(Theme.of(context).brightness);

    final start = (selectedIndex - 1).clamp(0, galaxies.length - 1);
    final end = (start + 2).clamp(0, galaxies.length - 1);
    final visible = [for (var i = start; i <= end; i++) i];

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: 40,
          left: 24,
          right: 24,
          child: Container(
            height: 1.1,
            color: colors.line.withValues(alpha: 0.6),
          ),
        ),
        Row(
          children: [
            for (final index in visible)
              Expanded(
                child: GestureDetector(
                  onTap: () => onSelect(index),
                  child: Column(
                    children: [
                      Container(
                        width: index == selectedIndex ? 84 : 70,
                        height: index == selectedIndex ? 84 : 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.surface,
                          border: Border.all(
                            color: index == selectedIndex
                                ? colors.textPrimary
                                : colors.line,
                            width: index == selectedIndex ? 1.4 : 1.0,
                          ),
                        ),
                        child: Center(
                          child: MissionOrbitIcon(
                            size: index == selectedIndex ? 52 : 42,
                            opacity: galaxies[index].unlocked ? 1 : 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: MissionSpacing.xs),
                      Text(
                        galaxies[index].nameEn.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        textScaler: const TextScaler.linear(1),
                        style: MissionText.micro(colors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
