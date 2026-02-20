import 'package:flutter/material.dart';

import 'mission_buttons.dart';
import 'mission_tokens.dart';

class LessonNavBar extends StatelessWidget {
  const LessonNavBar({
    super.key,
    required this.title,
    this.onLeadingTap,
    this.leadingIcon,
    this.trailing,
  });

  final String title;
  final VoidCallback? onLeadingTap;
  final IconData? leadingIcon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = MissionColors.resolve(Theme.of(context).brightness);

    return Row(
      children: [
        MissionIconButton(
          icon: leadingIcon ?? Icons.arrow_back_rounded,
          onPressed: onLeadingTap,
          semanticLabel: 'Back',
        ),
        const SizedBox(width: MissionSpacing.sm),
        Expanded(
          child: Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: MissionText.title(
              colors.textPrimary,
            ).copyWith(fontSize: 19, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: MissionSpacing.sm),
        SizedBox(
          width: 44,
          height: 44,
          child: Align(
            alignment: Alignment.center,
            child: trailing ?? const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class LessonStarsBar extends StatelessWidget {
  const LessonStarsBar({super.key, this.total = 6, required this.filled});

  final int total;
  final int filled;

  @override
  Widget build(BuildContext context) {
    final colors = MissionColors.resolve(Theme.of(context).brightness);

    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          Icon(
            i < filled ? Icons.star_rounded : Icons.star_border_rounded,
            size: 22,
            color: i < filled
                ? colors.textPrimary
                : colors.textSecondary.withValues(alpha: 0.85),
          ),
          if (i != total - 1)
            Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.symmetric(
                  horizontal: MissionSpacing.xs,
                ),
                color: colors.line.withValues(alpha: 0.55),
              ),
            ),
        ],
      ],
    );
  }
}

class LessonMediaPanel extends StatelessWidget {
  const LessonMediaPanel({
    super.key,
    this.onTap,
    this.onAudioTap,
    this.caption,
    this.height = 260,
  });

  final VoidCallback? onTap;
  final VoidCallback? onAudioTap;
  final String? caption;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = MissionColors.resolve(Theme.of(context).brightness);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(MissionRadius.sm),
          border: Border.all(
            color: colors.line.withValues(alpha: 0.55),
            width: 1.2,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Container(
                width: 144,
                height: 144,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.background.withValues(alpha: 0.45),
                ),
                child: Icon(
                  Icons.image_outlined,
                  size: 56,
                  color: colors.textSecondary.withValues(alpha: 0.65),
                ),
              ),
            ),
            Positioned(
              top: MissionSpacing.sm,
              right: MissionSpacing.sm,
              child: MissionIconButton(
                icon: Icons.volume_up_rounded,
                onPressed: onAudioTap,
                semanticLabel: 'Play audio',
              ),
            ),
            if ((caption ?? '').isNotEmpty)
              Positioned(
                left: MissionSpacing.md,
                right: MissionSpacing.md,
                bottom: MissionSpacing.md,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MissionSpacing.sm,
                    vertical: MissionSpacing.xs,
                  ),
                  color: colors.background,
                  child: Text(
                    caption!,
                    textAlign: TextAlign.center,
                    style: MissionText.micro(colors.primaryText),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LessonFeedbackSheet extends StatelessWidget {
  const LessonFeedbackSheet({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.emphasis,
    this.detailLabel,
    this.detailValue,
    this.titleColor,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? emphasis;
  final String? detailLabel;
  final String? detailValue;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final colors = MissionColors.resolve(Theme.of(context).brightness);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        MissionSpacing.lg,
        MissionSpacing.xl,
        MissionSpacing.lg,
        MissionSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.background.withValues(alpha: 0.45),
            ),
            child: Icon(
              Icons.image_outlined,
              size: 48,
              color: colors.textSecondary.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: MissionSpacing.lg),
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: MissionText.heading(
              titleColor ?? colors.textPrimary,
            ).copyWith(fontSize: 38, letterSpacing: 0.4),
          ),
          const SizedBox(height: MissionSpacing.sm),
          Text(
            message.toUpperCase(),
            textAlign: TextAlign.center,
            style: MissionText.label(colors.textPrimary).copyWith(fontSize: 22),
          ),
          if ((emphasis ?? '').isNotEmpty) ...[
            const SizedBox(height: MissionSpacing.md),
            Text(
              emphasis!,
              textAlign: TextAlign.center,
              style: MissionText.title(
                colors.textSecondary,
              ).copyWith(fontSize: 18),
            ),
          ],
          if ((detailLabel ?? '').isNotEmpty ||
              (detailValue ?? '').isNotEmpty) ...[
            const SizedBox(height: MissionSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: MissionSpacing.md,
                vertical: MissionSpacing.sm,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colors.line.withValues(alpha: 0.4)),
                  bottom: BorderSide(color: colors.line.withValues(alpha: 0.4)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      (detailLabel ?? '').toUpperCase(),
                      style: MissionText.label(colors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: MissionSpacing.sm),
                  Flexible(
                    child: Text(
                      (detailValue ?? '').toUpperCase(),
                      textAlign: TextAlign.right,
                      style: MissionText.label(colors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: MissionSpacing.lg),
          MissionButton(
            label: primaryLabel,
            variant: MissionButtonVariant.outline,
            onPressed: onPrimary,
          ),
        ],
      ),
    );
  }
}

Future<void> showLessonFeedbackSheet({
  required BuildContext context,
  required LessonFeedbackSheet sheet,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => sheet,
  );
}
