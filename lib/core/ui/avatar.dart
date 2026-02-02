import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    this.image,
    this.size = 56,
    this.initials,
  });

  final ImageProvider? image;
  final double size;
  final String? initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.progressTrack, width: 1.2),
        color: AppColors.gamificationLight,
        image: image != null
            ? DecorationImage(image: image!, fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: image == null
          ? Text(
              initials ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textNavy,
              ),
            )
          : null,
    );
  }
}
