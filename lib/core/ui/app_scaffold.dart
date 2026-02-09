import 'package:flutter/material.dart';

import '../theme/app_extensions.dart';
import '../theme/app_spacing.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.contentPadding = const EdgeInsets.all(AppSpacing.xl),
    this.background,
    this.extendBodyBehindAppBar = false,
    this.safeAreaTop = true,
    this.safeAreaBottom = true,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final EdgeInsetsGeometry contentPadding;
  final Widget? background;
  final bool extendBodyBehindAppBar;
  final bool safeAreaTop;
  final bool safeAreaBottom;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      backgroundColor: surfaces.canvas,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          if (background != null) Positioned.fill(child: background!),
          SafeArea(
            top: safeAreaTop,
            bottom: safeAreaBottom,
            child: Padding(
              padding: contentPadding,
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}
