import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/ui/app_app_bar.dart';
import '../../../core/ui/app_card.dart';
import '../../../core/ui/app_scaffold.dart';
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
        appBar: const AppAppBar(title: 'Ayah Learn'),
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
                          const IllustrationFrame(
                            size: 180,
                            child: Icon(Icons.menu_book, size: 48),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppCard(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('Ayah ${ayah.id}', style: AppTextStyles.caption),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  ayah.arabic,
                                  style: AppTextStyles.arabicTitle,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  ayah.transliteration,
                                  style: AppTextStyles.body,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  ayah.translation,
                                  style: AppTextStyles.body,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppCard(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Meaning', style: AppTextStyles.title),
                                const SizedBox(height: AppSpacing.sm),
                                Text(ayah.meaning, style: AppTextStyles.body),
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
                            label: 'Back to overview',
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
            child: Text('Unable to load ayah.', style: AppTextStyles.body),
          ),
        ),
      ),
    );
  }
}
