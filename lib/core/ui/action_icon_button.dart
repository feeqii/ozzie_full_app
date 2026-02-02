import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';

enum ActionIconButtonShape { square, round }

class ActionIconButton extends StatelessWidget {
  const ActionIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.shape = ActionIconButtonShape.square,
    this.useInnerShadow = false,
    this.backgroundColor = AppColors.white,
    this.borderColor = AppColors.black,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final ActionIconButtonShape shape;
  final bool useInnerShadow;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(
      shape == ActionIconButtonShape.round ? 999 : AppRadii.md,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: radius,
        border: Border.all(color: borderColor, width: 1.4),
        boxShadow: useInnerShadow
            ? AppShadows.inner(color: AppColors.actionInnerShadowBlue)
            : AppShadows.soft,
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppColors.textNavy, size: 20),
        ),
      ),
    );
  }
}
