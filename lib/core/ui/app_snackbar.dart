import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppSnackbar {
  const AppSnackbar._();

  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
  }) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: AppTextStyles.body.copyWith(color: AppColors.white),
      ),
      backgroundColor: isError ? AppColors.danger : AppColors.textNavy,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
