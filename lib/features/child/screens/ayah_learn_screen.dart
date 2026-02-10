import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/ui/app_app_bar.dart';
import '../../../core/ui/app_card.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/atlas_illustrations.dart';
import '../../../core/ui/atlas_background.dart';
import '../../../core/ui/illustration_frame.dart';
import '../../../core/ui/primary_button.dart';
import '../../../core/ui/secondary_button.dart';
import '../../content/providers/content_providers.dart';
import '../../progress/widgets/practice_session_boundary.dart';

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

    return PracticeSessionBoundary(
      child: AppScaffold(
        appBar: const AppAppBar(title: 'Ayah'),
        background: const AtlasBackground(seed: 29),
        body: surahAsync.when(
          data: (surah) {
            final ayah = surah.ayahs.firstWhere(
              (item) => item.id == ayahId,
              orElse: () => surah.ayahs.first,
            );

            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          IllustrationFrame(
                            size: 190,
                            child: const AtlasIllustration(kind: AtlasIllustrationKind.lesson),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppCard(
                            variant: AppCardVariant.elevated,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'AYAH ${ayah.id}',
                                  style: Theme.of(context).textTheme.labelMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  ayah.arabic,
                                  style: AppTextStyles.arabicTitle.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  ayah.transliteration,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  ayah.translation,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppCard(
                            variant: AppCardVariant.soft,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Meaning', style: Theme.of(context).textTheme.headlineSmall),
                                const SizedBox(height: AppSpacing.sm),
                                Text(ayah.meaning, style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                          const Spacer(),
                          PrimaryButton(
                            label: 'Practice recitation',
                            onPressed: () => context.push('/child/surah/$surahId/ayah/$ayahId/recite'),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SecondaryButton(
                            label: 'Back',
                            onPressed: () => context.pop(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text('Unable to load ayah.', style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      ),
    );
  }
}
