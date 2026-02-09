import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_extensions.dart';
import '../theme/app_spacing.dart';
import 'action_icon_button.dart';

enum AppAppBarVariant { standard, overlay }

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.fallbackRoute,
    this.actions,
    this.variant = AppAppBarVariant.standard,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String title;
  final bool showBack;
  final String? fallbackRoute;
  final List<Widget>? actions;
  final AppAppBarVariant variant;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surfaces = context.surfaces;

    final bg = backgroundColor ??
        (variant == AppAppBarVariant.overlay ? Colors.transparent : surfaces.canvas);
    final fg = foregroundColor ?? scheme.onSurface;

    final leading = showBack
        ? (variant == AppAppBarVariant.overlay
            ? Padding(
                padding: const EdgeInsets.only(left: AppSpacing.md),
                child: ActionIconButton(
                  icon: Icons.arrow_back,
                  shape: ActionIconButtonShape.round,
                  backgroundColor: surfaces.card.withValues(alpha: 0.82),
                  borderColor: surfaces.outlineStrong.withValues(alpha: 0.35),
                  iconColor: fg,
                  onPressed: () => _handleBack(context),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _handleBack(context),
              ))
        : null;

    return AppBar(
      title: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: fg,
            ),
      ),
      leading: leading,
      actions: actions,
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _handleBack(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
      return;
    }
    final location = GoRouterState.of(context).uri.path;
    final target = fallbackRoute ?? _fallbackFor(location);
    context.go(target);
  }

  String _fallbackFor(String location) {
    if (location.startsWith('/auth')) {
      return '/auth/entry';
    }
    if (location.startsWith('/parent')) {
      return '/parent/dashboard';
    }
    return '/child/home';
  }
}

