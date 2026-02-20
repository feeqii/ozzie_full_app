import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'mission_tokens.dart';

class MissionOrbitIcon extends StatelessWidget {
  const MissionOrbitIcon({
    super.key,
    this.size = 86,
    this.color,
    this.opacity = 1,
  });

  final double size;
  final Color? color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final colors = MissionColors.resolve(Theme.of(context).brightness);

    return Opacity(
      opacity: opacity,
      child: SvgPicture.asset(
        'assets/illustrations/mission_orbit.svg',
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(
          color ?? colors.textPrimary,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
