import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/ui/app_app_bar.dart';
import '../../../core/ui/app_card.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/atlas_background.dart';
import '../../../core/ui/label_chip.dart';
import '../../../core/ui/primary_button.dart';
import '../../content/providers/content_providers.dart';
import '../../quiz/models/quiz_models.dart';
import '../../quiz/providers/quiz_providers.dart';

class SurahOverviewScreen extends ConsumerWidget {
  const SurahOverviewScreen({super.key, required this.surahId});

  final int surahId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahAsync = ref.watch(surahContentProvider(surahId));
    final progressAsync = ref.watch(surahProgressProvider(surahId));
    final progress = progressAsync.asData?.value;
    final quizType = quizTypeFromGate(progress?.stage);

    return AppScaffold(
      appBar: const AppAppBar(title: 'Surah Overview'),
      background: const AtlasBackground(seed: 35),
      body: surahAsync.when(
        data: (surah) {
          final scheme = Theme.of(context).colorScheme;
          final surfaces = context.surfaces;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        LabelChip(
                          label: 'Surah ${surah.id}',
                          background: surfaces.card.withValues(alpha: 0.7),
                          borderColor: surfaces.outlineStrong.withValues(alpha: 0.18),
                          foregroundColor: scheme.onSurface,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${surah.ayahs.length} ayahs',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.72),
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(surah.name, style: Theme.of(context).textTheme.displayLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      surah.translation,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.78),
                          ),
                    ),
                    if (quizType != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      PrimaryButton(
                        label: 'Continue ${quizType.label}',
                        onPressed: () => context.push('/child/surah/$surahId/quiz/${quizType.apiValue}'),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final ayah = surah.ayahs[index];
                    final isLocked = progress != null && ayah.id > progress.unlockedAyahMax;
                    final isLast = index == surah.ayahs.length - 1;
                    return Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
                      child: AppCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        variant: AppCardVariant.soft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ayah ${ayah.id}', style: Theme.of(context).textTheme.labelMedium),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              ayah.arabic,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontFamily: 'NotoNaskhArabic',
                                    height: 1.7,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              ayah.translation,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurface.withValues(alpha: 0.78),
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            PrimaryButton(
                              label: isLocked ? 'Locked' : 'Learn this ayah',
                              isDisabled: isLocked,
                              onPressed: isLocked
                                  ? null
                                  : () => context.push('/child/surah/$surahId/ayah/${ayah.id}'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: surah.ayahs.length,
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Unable to load surah.', style: Theme.of(context).textTheme.bodyMedium),
        ),
      ),
    );
  }
}
