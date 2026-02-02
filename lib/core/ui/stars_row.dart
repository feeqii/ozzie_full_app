import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StarsRow extends StatelessWidget {
  const StarsRow({
    super.key,
    required this.total,
    required this.filled,
  });

  final int total;
  final int filled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        total,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            index < filled ? Icons.star : Icons.star_border,
            color: AppColors.textNavy,
            size: 18,
          ),
        ),
      ),
    );
  }
}
