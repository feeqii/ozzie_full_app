import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../map/providers/map_providers.dart';
import '../providers/child_providers.dart';
import '../ui/lesson_widgets.dart';
import '../ui/mission_buttons.dart';
import '../ui/mission_card.dart';
import '../ui/mission_scaffold.dart';
import '../ui/mission_tokens.dart';

class SurahIntroArgs {
  const SurahIntroArgs({required this.surahId, required this.levelId});

  final int surahId;
  final String levelId;
}

class SurahIntroScreen extends ConsumerWidget {
  const SurahIntroScreen({
    super.key,
    required this.surahId,
    required this.levelId,
  });

  final int surahId;
  final String levelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider);
    final repo = ref.watch(mapRepositoryProvider);
    final colors = MissionColors.resolve(Theme.of(context).brightness);

    return MissionScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LessonNavBar(
            title: 'Surah Introduction',
            onLeadingTap: () => context.pop(),
          ),
          const SizedBox(height: MissionSpacing.xl),
          Expanded(
            child: Center(
              child: MissionCard(
                padding: const EdgeInsets.all(MissionSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.background.withValues(alpha: 0.45),
                          border: Border.all(
                            color: colors.line.withValues(alpha: 0.45),
                            width: 1.2,
                          ),
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 58,
                          color: colors.textPrimary.withValues(alpha: 0.82),
                        ),
                      ),
                    ),
                    const SizedBox(height: MissionSpacing.lg),
                    Text(
                      'Before we begin',
                      style: MissionText.heading(colors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: MissionSpacing.sm),
                    Text(
                      'Let\'s learn what this surah is about, then we\'ll start verse by verse.',
                      style: MissionText.body(colors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: MissionSpacing.lg),
                    MissionButton(
                      label: 'I understand, continue',
                      onPressed: child == null
                          ? null
                          : () async {
                              try {
                                await repo.completeLevel(
                                  childId: child.id,
                                  levelId: levelId,
                                );
                                if (context.mounted) {
                                  context.pop();
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Could not continue right now. Please try again.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
