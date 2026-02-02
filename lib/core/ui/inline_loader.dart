import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class InlineLoader extends StatelessWidget {
  const InlineLoader({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: const CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.textNavy),
      ),
    );
  }
}
