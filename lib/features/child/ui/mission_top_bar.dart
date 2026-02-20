import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_mode.dart';
import '../models/child_profile.dart';
import 'mission_buttons.dart';
import 'mission_tokens.dart';

class MissionTopBar extends ConsumerWidget {
  const MissionTopBar({
    super.key,
    this.child,
    this.showBack = false,
    this.onBack,
    this.onProgress,
    this.onParentActions,
  });

  final ChildProfile? child;
  final bool showBack;
  final VoidCallback? onBack;
  final VoidCallback? onProgress;
  final VoidCallback? onParentActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final colors = MissionColors.resolve(brightness);
    ref.watch(appThemeModeProvider);
    final isDark = brightness == Brightness.dark;

    return Row(
      children: [
        if (showBack)
          Padding(
            padding: const EdgeInsets.only(right: MissionSpacing.sm),
            child: MissionIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: onBack,
              semanticLabel: 'Back',
            ),
          ),
        Expanded(
          child: Row(
            children: [
              _AvatarBadge(initial: _initial(child?.name)),
              const SizedBox(width: MissionSpacing.xs),
              Expanded(
                child: Text(
                  (child?.name ?? 'Explorer').toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textScaler: const TextScaler.linear(1),
                  style: MissionText.label(
                    colors.textPrimary,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        MissionIconButton(
          icon: Icons.local_fire_department_outlined,
          onPressed: onProgress,
          semanticLabel: 'Progress',
        ),
        const SizedBox(width: MissionSpacing.sm),
        MissionIconButton(
          icon: Icons.admin_panel_settings_outlined,
          onPressed: onParentActions,
          semanticLabel: 'Parent Dashboard',
        ),
        const SizedBox(width: MissionSpacing.sm),
        MissionIconButton(
          icon: isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
          onPressed: () {
            final nextMode = isDark ? ThemeMode.light : ThemeMode.dark;
            ref.read(appThemeModeProvider.notifier).setThemeMode(nextMode);
          },
          semanticLabel: 'Toggle Theme',
        ),
      ],
    );
  }

  static String _initial(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'O';
    }
    final trimmed = value.trim();
    return trimmed.substring(0, 1).toUpperCase();
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    final colors = MissionColors.resolve(Theme.of(context).brightness);

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surface,
        border: Border.all(color: colors.line, width: 1.1),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: MissionText.label(
          colors.textPrimary,
        ).copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
