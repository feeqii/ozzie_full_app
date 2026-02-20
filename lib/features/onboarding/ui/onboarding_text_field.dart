import 'package:flutter/material.dart';

import '../theme/onboarding_tokens.dart';

class OnboardingTextField extends StatefulWidget {
  const OnboardingTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.errorText,
    this.onChanged,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  State<OnboardingTextField> createState() => _OnboardingTextFieldState();
}

class _OnboardingTextFieldState extends State<OnboardingTextField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant OnboardingTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _isObscured = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = OnboardingColors.resolve(Theme.of(context).brightness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: OnboardingTypography.label(colors.textPrimary),
        ),
        const SizedBox(height: OnboardingSpacing.sm),
        TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: _isObscured,
          onChanged: widget.onChanged,
          style: OnboardingTypography.bodyStrong(colors.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: OnboardingTypography.body(colors.textSecondary),
            errorText: widget.errorText,
            filled: true,
            fillColor: colors.surface,
            suffixIcon: widget.obscureText
                ? IconButton(
                    onPressed: () => setState(() => _isObscured = !_isObscured),
                    icon: Icon(
                      _isObscured
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: colors.textSecondary,
                    ),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: OnboardingSpacing.md,
              vertical: OnboardingSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OnboardingRadii.sm),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OnboardingRadii.sm),
              borderSide: BorderSide(color: colors.primary, width: 1.4),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(OnboardingRadii.sm),
              borderSide: BorderSide(color: colors.border),
            ),
          ),
        ),
      ],
    );
  }
}
