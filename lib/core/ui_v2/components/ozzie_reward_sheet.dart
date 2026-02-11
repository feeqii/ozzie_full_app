import 'package:flutter/material.dart';

import '../../theme_v2/ozzie_theme.dart';
import 'ozzie_button.dart';

class OzzieRewardSheet extends StatelessWidget {
  const OzzieRewardSheet({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel = 'Awesome',
    this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = context.ozzieTokens;
    final c = tokens.colors;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(tokens.radius.xl),
          ),
          border: Border.all(color: c.outline),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.auto_awesome_rounded, color: c.warning, size: 34),
              const SizedBox(height: 10),
              Text(
                title,
                style: tokens.type.headline.copyWith(color: c.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: tokens.type.body.copyWith(color: c.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OzzieButton(
                label: actionLabel,
                icon: Icons.celebration_rounded,
                onPressed: onAction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
