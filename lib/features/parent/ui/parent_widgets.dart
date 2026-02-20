import 'package:flutter/material.dart';

import 'parent_tokens.dart';

class ParentHeaderBar extends StatelessWidget {
  const ParentHeaderBar({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.centerTitle = true,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return Row(
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: onBack == null
              ? const SizedBox.shrink()
              : ParentIconButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: onBack,
                  semanticLabel: 'Back',
                ),
        ),
        const SizedBox(width: ParentSpacing.sm),
        Expanded(
          child: Text(
            title,
            textAlign: centerTitle ? TextAlign.center : TextAlign.left,
            style: ParentText.title(
              colors.textPrimary,
            ).copyWith(fontSize: 18, letterSpacing: 0.8),
          ),
        ),
        const SizedBox(width: ParentSpacing.sm),
        SizedBox(
          width: 44,
          height: 44,
          child: trailing ?? const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class ParentIconButton extends StatelessWidget {
  const ParentIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: colors.border, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: colors.textPrimary, size: 20),
          ),
        ),
      ),
    );
  }
}

class ParentPanel extends StatelessWidget {
  const ParentPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(ParentSpacing.md),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(ParentRadius.sm),
        border: Border.all(color: colors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(ParentRadius.sm),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class ParentActionTile extends StatelessWidget {
  const ParentActionTile({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return ParentPanel(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: ParentSpacing.md,
        vertical: ParentSpacing.lg,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: colors.textPrimary),
            const SizedBox(width: ParentSpacing.sm),
          ],
          Expanded(
            child: Text(label, style: ParentText.label(colors.textPrimary)),
          ),
          Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
        ],
      ),
    );
  }
}

class ParentRoundAvatar extends StatelessWidget {
  const ParentRoundAvatar({
    super.key,
    required this.label,
    this.onTap,
    this.isAdd = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isAdd;

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isAdd
                  ? colors.textSecondary.withValues(alpha: 0.25)
                  : colors.surfaceMuted,
              border: Border.all(color: colors.border, width: 1.1),
            ),
            child: Icon(
              isAdd ? Icons.add : Icons.image_outlined,
              size: 44,
              color: isAdd ? colors.surface : colors.textSecondary,
            ),
          ),
          const SizedBox(height: ParentSpacing.sm),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: ParentText.label(colors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class ParentPrimaryButton extends StatelessWidget {
  const ParentPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(ParentRadius.md),
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: ParentSpacing.md,
              vertical: ParentSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ParentRadius.md),
              border: Border.all(
                color: danger ? colors.danger : colors.border,
                width: 1.2,
              ),
              gradient: danger
                  ? null
                  : const LinearGradient(
                      colors: [
                        ParentPalette.orange,
                        ParentPalette.green,
                        ParentPalette.blue,
                      ],
                    ),
              color: danger ? colors.danger : null,
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: ParentPalette.light),
                  const SizedBox(width: ParentSpacing.sm),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: ParentText.title(ParentPalette.light),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ParentSectionTitle extends StatelessWidget {
  const ParentSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return Text(
      text.toUpperCase(),
      style: ParentText.label(colors.textSecondary).copyWith(fontSize: 20),
    );
  }
}
