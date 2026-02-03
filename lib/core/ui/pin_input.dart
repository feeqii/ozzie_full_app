import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_text_button.dart';

class PinInput extends StatelessWidget {
  const PinInput({
    super.key,
    this.length = 4,
    this.onChanged,
    this.onForgotPin,
    this.value,
  });

  final int length;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onForgotPin;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            length,
            (index) => SizedBox(
              width: 52,
              child: TextField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                obscureText: true,
                readOnly: true,
                controller: TextEditingController(
                  text: (value != null && value!.length > index) ? '•' : '',
                ),
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
        ),
        if (onForgotPin != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppTextButton(label: 'Forgot PIN?', onPressed: onForgotPin),
        ],
      ],
    );
  }
}
