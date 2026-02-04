import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.fallbackRoute,
    this.actions,
  });

  final String title;
  final bool showBack;
  final String? fallbackRoute;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: AppTextStyles.title),
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                final router = GoRouter.of(context);
                if (router.canPop()) {
                  context.pop();
                  return;
                }
                final location = GoRouterState.of(context).uri.path;
                final target = fallbackRoute ?? _fallbackFor(location);
                context.go(target);
              },
            )
          : null,
      actions: actions,
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.textNavy,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

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
