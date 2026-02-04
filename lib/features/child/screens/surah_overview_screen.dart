import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/ui/app_app_bar.dart';
import '../../../core/ui/app_card.dart';
import '../../../core/ui/app_scaffold.dart';
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
      body: surahAsync.when(
        data: (surah) {
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
                          background: AppColors.gamificationLight,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text('${surah.ayahs.length} ayahs', style: AppTextStyles.caption),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(surah.name, style: AppTextStyles.title),
                    const SizedBox(height: AppSpacing.xs),
                    Text(surah.translation, style: AppTextStyles.body),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ayah ${ayah.id}', style: AppTextStyles.caption),
                            const SizedBox(height: AppSpacing.xs),
                            Text(ayah.arabic, style: AppTextStyles.arabicBody),
                            const SizedBox(height: AppSpacing.xs),
                            Text(ayah.translation, style: AppTextStyles.body),
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
          child: Text('Unable to load surah.', style: AppTextStyles.body),
        ),
      ),
    );
  }
}
