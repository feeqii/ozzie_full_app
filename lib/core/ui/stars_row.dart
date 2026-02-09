import 'package:flutter/material.dart';

import '../theme/app_extensions.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final glow = context.surfaces.mapGlow;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        total,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            index < filled ? Icons.star : Icons.star_border,
            color: index < filled ? glow : scheme.onSurface.withValues(alpha: 0.55),
            size: 18,
          ),
        ),
      ),
    );
  }
}
