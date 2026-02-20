import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../map/models/map_models.dart';
import '../map/providers/map_providers.dart';
import '../parent/utils/parent_access_gate.dart';
import 'providers/child_providers.dart';
import 'ui/mission_buttons.dart';
import 'ui/mission_orbit_icon.dart';
import 'ui/mission_scaffold.dart';
import 'ui/mission_speech_bubble.dart';
import 'ui/mission_status_tag.dart';
import 'ui/mission_top_bar.dart';
import 'ui/mission_tokens.dart';

class ChildHomeScreen extends ConsumerStatefulWidget {
  const ChildHomeScreen({super.key});

  @override
  ConsumerState<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends ConsumerState<ChildHomeScreen> {
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
                  'Unable to load mission control.',
                  style: MissionText.body(colors.textSecondary),
                ),
              ),
              data: (mapState) {
                if (mapState == null || mapState.galaxies.isEmpty) {
                  return Center(
                    child: Text(
                      'No missions available yet.',
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
                final message = selected.unlocked
                    ? '${selected.nameEn} is ready. Pick a route and keep going.'
                    : '${selected.nameEn} is locked. Finish earlier zones first.';
                final subtitle = selected.unlocked
                    ? 'Zone unlocked. Tap to continue your journey.'
                    : 'Complete previous zones to unlock this one.';

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: MissionSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MissionSpeechBubble(text: message),
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
                                width: 214,
                                height: 214,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colors.surface.withValues(alpha: 0.44),
                                  border: Border.all(
                                    color: colors.line.withValues(alpha: 0.35),
                                    width: 1.2,
                                  ),
                                ),
                              ),
                              MissionOrbitIcon(
                                size: 152,
                                opacity: selected.unlocked ? 1 : 0.45,
                              ),
                              if (!selected.unlocked)
                                Container(
                                  width: 62,
                                  height: 62,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colors.surface,
                                    border: Border.all(
                                      color: colors.textPrimary,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.lock_rounded,
                                    color: colors.textPrimary,
                                    size: 26,
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
                          style: MissionText.heading(colors.textPrimary),
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
                              : 'No active slots left',
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
                            : '${selected.nameEn} locked',
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
