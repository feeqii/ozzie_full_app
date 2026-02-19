import 'package:flutter/material.dart';

class IllustrationPlaceholder extends StatelessWidget {
  const IllustrationPlaceholder({
    super.key,
    required this.title,
    required this.note,
    this.height = 220,
  });

  final String title;
  final String note;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          width: 1.2,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? <Color>[
                  theme.colorScheme.primary.withValues(alpha: 0.16),
                  theme.colorScheme.secondary.withValues(alpha: 0.11),
                ]
              : <Color>[
                  theme.colorScheme.primary.withValues(alpha: 0.17),
                  theme.colorScheme.secondary.withValues(alpha: 0.16),
                ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'ILLUSTRATION PLACEHOLDER',
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(note, style: theme.textTheme.bodyMedium),
          const Spacer(),
          Text(
            'Replace in production with original OYD illustration assets.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
