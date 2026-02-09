import 'package:flutter/material.dart';

import '../theme/app_extensions.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';

enum AppCardVariant { standard, elevated, soft, mapNode }

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.variant = AppCardVariant.standard,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final AppCardVariant variant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final scheme = Theme.of(context).colorScheme;

    final Color background = switch (variant) {
      AppCardVariant.standard => surfaces.card,
      AppCardVariant.elevated => surfaces.card,
      AppCardVariant.soft => surfaces.cardSubtle,
      AppCardVariant.mapNode => surfaces.card,
    };

    final Color border = switch (variant) {
      AppCardVariant.mapNode => surfaces.outlineStrong,
      _ => surfaces.outline,
    };

    final double borderWidth = variant == AppCardVariant.mapNode ? 1.6 : 1.2;

    final List<BoxShadow> shadows = switch (variant) {
      AppCardVariant.elevated => AppShadows.card,
      AppCardVariant.mapNode => AppShadows.soft,
      _ => const [],
    };

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: border, width: borderWidth),
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        overlayColor: WidgetStatePropertyAll(scheme.primary.withValues(alpha: 0.06)),
        child: content,
      ),
    );
  }
}

