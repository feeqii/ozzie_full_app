import 'package:flutter/material.dart';

import '../theme/app_extensions.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
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
    final surfaces = context.surfaces;
    final scheme = Theme.of(context).colorScheme;

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
                  fillColor: surfaces.card,
                  contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: BorderSide(color: surfaces.outlineStrong.withValues(alpha: 0.16), width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: BorderSide(color: scheme.primary, width: 1.8),
                  ),
                ),
                style: Theme.of(context).textTheme.headlineSmall,
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
