import 'package:flutter/material.dart';

class AppSnackbar {
  const AppSnackbar._();

  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isError ? scheme.error : scheme.inverseSurface;
    final fg = isError ? scheme.onError : scheme.onInverseSurface;

    final snackBar = SnackBar(
      content: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: fg),
      ),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
