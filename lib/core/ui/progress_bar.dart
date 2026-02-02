import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
  });

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 8,
        backgroundColor: AppColors.progressTrack,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.progressActive),
      ),
    );
  }
}
