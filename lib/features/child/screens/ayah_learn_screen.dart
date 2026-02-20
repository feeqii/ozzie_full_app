import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/providers/content_providers.dart';
import '../../progress/widgets/practice_session_boundary.dart';
import '../ui/lesson_widgets.dart';
import '../ui/mission_buttons.dart';
import '../ui/mission_card.dart';
import '../ui/mission_scaffold.dart';
import '../ui/mission_tokens.dart';

class AyahLearnScreen extends ConsumerWidget {
  const AyahLearnScreen({
    super.key,
    required this.surahId,
    required this.ayahId,
  });

  final int surahId;
  final int ayahId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahAsync = ref.watch(surahContentProvider(surahId));
    final colors = MissionColors.resolve(Theme.of(context).brightness);

    return PracticeSessionBoundary(
      child: MissionScaffold(
        extendToBottom: true,
        child: surahAsync.when(
          data: (surah) {
            final ayah = surah.ayahs.firstWhere(
              (item) => item.id == ayahId,
              orElse: () => surah.ayahs.first,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LessonNavBar(
                  title: '${surah.name} - verse ${ayah.id}',
                  leadingIcon: Icons.close_rounded,
                  onLeadingTap: () =>
                      context.go('/child/surah/$surahId/journey'),
                ),
                const SizedBox(height: MissionSpacing.md),
                const LessonStarsBar(total: 6, filled: 1),
                const SizedBox(height: MissionSpacing.md),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: MissionSpacing.xxl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LessonMediaPanel(
                          caption: 'Tap anywhere to play guided verse audio.',
                          onTap: () => _showAudioPlaceholder(context),
                          onAudioTap: () => _showAudioPlaceholder(context),
                        ),
                        const SizedBox(height: MissionSpacing.md),
                        MissionCard(
                          padding: const EdgeInsets.all(MissionSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                ayah.arabic,
                                textAlign: TextAlign.center,
                                style: MissionText.heading(colors.textPrimary)
                                    .copyWith(
                                      fontFamily: 'NotoNaskhArabic',
                                      height: 1.65,
                                    ),
                              ),
                              const SizedBox(height: MissionSpacing.sm),
                              Container(
                                height: 1,
                                color: colors.line.withValues(alpha: 0.45),
                              ),
                              const SizedBox(height: MissionSpacing.sm),
                              Text(
                                ayah.transliteration,
                                textAlign: TextAlign.center,
                                style: MissionText.body(colors.textPrimary),
                              ),
                              const SizedBox(height: MissionSpacing.xs),
                              Text(
                                ayah.translation,
                                textAlign: TextAlign.center,
                                style: MissionText.body(colors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: MissionSpacing.md),
                        MissionCard(
                          padding: const EdgeInsets.all(MissionSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Meaning',
                                style: MissionText.title(colors.textPrimary),
                              ),
                              const SizedBox(height: MissionSpacing.xs),
                              Text(
                                ayah.meaning,
                                style: MissionText.body(colors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: MissionSpacing.xl),
                        MissionButton(
                          label: 'Tap to recite',
                          onPressed: () => context.push(
                            '/child/surah/$surahId/ayah/$ayahId/recite',
                          ),
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
              'Unable to load this verse.',
              style: MissionText.body(colors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }

  void _showAudioPlaceholder(BuildContext context) {
    // TODO(lesson-audio): wire verse-level guided playback from content/audio backend.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audio playback placeholder.')),
    );
  }
}
