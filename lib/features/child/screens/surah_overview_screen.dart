import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/lesson_widgets.dart';
import '../ui/mission_buttons.dart';
import '../ui/mission_scaffold.dart';
import '../ui/mission_tokens.dart';
import '../../child/providers/child_providers.dart';
import '../../content/providers/content_providers.dart';
import '../../journey/models/journey_models.dart';
import '../../journey/providers/journey_providers.dart';
import '../../map/providers/map_providers.dart';

class SurahOverviewScreen extends ConsumerWidget {
  const SurahOverviewScreen({super.key, required this.surahId});

  final int surahId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahAsync = ref.watch(surahContentProvider(surahId));
    final colors = MissionColors.resolve(Theme.of(context).brightness);

    return MissionScaffold(
      extendToBottom: true,
      child: surahAsync.when(
        data: (surah) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LessonNavBar(
                title: '${surah.name} overview',
                onLeadingTap: () => context.pop(),
              ),
              const SizedBox(height: MissionSpacing.md),
              Text(
                '${surah.ayahs.length} verses',
                textAlign: TextAlign.center,
                style: MissionText.label(colors.textSecondary),
              ),
              const SizedBox(height: MissionSpacing.md),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: MissionSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LessonMediaPanel(
                        height: 430,
                        caption:
                            'Listen and view this surah overview before beginning the mission.',
                        onTap: () => _showAudioPlaceholder(context),
                        onAudioTap: () => _showAudioPlaceholder(context),
                      ),
                      const SizedBox(height: MissionSpacing.lg),
                      MissionButton(
                        label: 'Start mission',
                        variant: MissionButtonVariant.outline,
                        onPressed: () async {
                          final child = ref.read(selectedChildProvider);
                          if (child == null) {
                            return;
                          }

                          try {
                            final journeyRepo = ref.read(
                              journeyRepositoryProvider,
                            );
                            final mapRepo = ref.read(mapRepositoryProvider);
                            final levels = await journeyRepo.fetchLevels(
                              surahId: surahId,
                            );
                            final introLevel = levels.firstWhere(
                              (level) =>
                                  level.type == JourneyLevelType.surahIntro,
                              orElse: () => const JourneyLevel(
                                id: '',
                                surahId: 0,
                                type: JourneyLevelType.verseLesson,
                                orderIndex: 0,
                              ),
                            );

                            if (introLevel.id.isNotEmpty) {
                              await mapRepo.completeLevel(
                                childId: child.id,
                                levelId: introLevel.id,
                              );
                              ref.invalidate(mapStateProvider);
                              ref.invalidate(
                                surahJourneyStepsProvider(surahId),
                              );
                            }

                            if (context.mounted) {
                              context.push('/child/surah/$surahId/journey');
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not start mission. Please try again.',
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
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(
            'Unable to load this surah right now.',
            style: MissionText.body(colors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  void _showAudioPlaceholder(BuildContext context) {
    // TODO(lesson-audio): wire intro media playback endpoint/source for each surah.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audio preview will be connected soon.')),
    );
  }
}
