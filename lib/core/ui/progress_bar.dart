import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_extensions.dart';
import '../theme/app_radii.dart';

class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
  });

  final double value;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 8,
        backgroundColor: surfaces.outlineStrong.withValues(alpha: 0.14),
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.progressActive),
      ),
    );
  }
}
