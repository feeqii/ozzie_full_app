import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme_v2/ozzie_theme.dart';

class OzzieTopBar extends StatelessWidget implements PreferredSizeWidget {
  const OzzieTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = false,
    this.trailing,
    this.useHeroBackground = false,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final Widget? trailing;
  final bool useHeroBackground;

  @override
  Widget build(BuildContext context) {
    final tokens = context.ozzieTokens;
    final c = tokens.colors;
    final fg = useHeroBackground ? Colors.white : c.textPrimary;
    final subtitleStyle = tokens.type.caption.copyWith(
      color: fg.withValues(alpha: 0.9),
      fontWeight: FontWeight.w700,
    );

    return AppBar(
      elevation: 0,
      toolbarHeight: subtitle == null ? kToolbarHeight : kToolbarHeight + 10,
      scrolledUnderElevation: 0,
      backgroundColor: useHeroBackground ? Colors.transparent : c.canvas,
      foregroundColor: fg,
      centerTitle: true,
      leading: showBack
          ? IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: fg),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/child/home');
                }
              },
            )
          : null,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: tokens.type.headline.copyWith(color: fg),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: subtitleStyle,
            ),
        ],
      ),
      actions: [if (trailing != null) trailing!, const SizedBox(width: 8)],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);
}
