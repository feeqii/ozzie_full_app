import 'package:flutter/material.dart';

import 'parent_tokens.dart';
import 'parent_widgets.dart';

class ParentPinBoxes extends StatelessWidget {
  const ParentPinBoxes({super.key, required this.value, this.length = 4});

  final String value;
  final int length;

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < length; i++) ...[
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(ParentRadius.sm),
              border: Border.all(
                color: i < value.length ? colors.textPrimary : colors.border,
                width: 1.2,
              ),
            ),
            alignment: Alignment.center,
            child: i < value.length
                ? Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors.textPrimary,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
          ),
          if (i != length - 1) const SizedBox(width: ParentSpacing.sm),
        ],
      ],
    );
  }
}

class ParentPinKeypad extends StatelessWidget {
  const ParentPinKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return Column(
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', '<'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: ParentSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final key in row)
                  SizedBox(
                    width: 86,
                    child: key.isEmpty
                        ? const SizedBox(height: 52)
                        : key == '<'
                        ? ParentIconButton(
                            icon: Icons.close_rounded,
                            onPressed: onBackspace,
                            semanticLabel: 'Delete digit',
                          )
                        : TextButton(
                            onPressed: () => onDigit(key),
                            style: TextButton.styleFrom(
                              foregroundColor: colors.textPrimary,
                              textStyle: ParentText.heading(
                                colors.textPrimary,
                              ).copyWith(fontSize: 32),
                            ),
                            child: Text(key),
                          ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
