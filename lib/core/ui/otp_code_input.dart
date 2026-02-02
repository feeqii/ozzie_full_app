import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class OtpCodeInput extends StatelessWidget {
  const OtpCodeInput({
    super.key,
    this.length = 6,
    this.onChanged,
  });

  final int length;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        length,
        (index) => SizedBox(
          width: 46,
          child: TextField(
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            onChanged: (value) {
              if (value.isNotEmpty && index < length - 1) {
                FocusScope.of(context).nextFocus();
              }
              onChanged?.call(value);
            },
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: AppColors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: const BorderSide(color: AppColors.progressTrack),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: const BorderSide(color: AppColors.textNavy, width: 1.4),
              ),
            ),
            style: AppTextStyles.title,
          ),
        ),
      ),
    );
  }
}
