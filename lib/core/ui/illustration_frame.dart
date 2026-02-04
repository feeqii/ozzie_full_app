import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class IllustrationFrame extends StatelessWidget {
  const IllustrationFrame({
    super.key,
    this.child,
    this.size = 140,
  });

  final Widget? child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.gamificationLight,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.progressTrack, width: 1),
      ),
      child: Center(child: child),
    );
  }
}
