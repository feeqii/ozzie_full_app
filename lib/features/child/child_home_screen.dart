import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/ui/app_app_bar.dart';
import '../../core/ui/app_card.dart';
import '../../core/ui/app_scaffold.dart';
import '../../core/ui/label_chip.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/secondary_button.dart';
import '../auth/controllers/auth_controller.dart';
import '../child/providers/child_providers.dart';
import '../content/providers/content_providers.dart';

class ChildHomeScreen extends ConsumerWidget {
  const ChildHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider);
    final surahsAsync = ref.watch(surahSummariesProvider);

    return AppScaffold(
      appBar: const AppAppBar(title: 'Learning Journey', showBack: false),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  child == null ? 'Welcome' : 'Welcome, ${child.name}',
                  style: AppTextStyles.title,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Pick a surah to begin your lesson.', style: AppTextStyles.body),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
          surahsAsync.when(
            data: (surahs) {
              if (surahs.isEmpty) {
                return SliverToBoxAdapter(
                  child: Text('No surahs available.', style: AppTextStyles.body),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final surah = surahs[index];
                    final isLast = index == surahs.length - 1;
                    return Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
                      child: AppCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                LabelChip(
                                  label: 'Surah ${surah.id}',
                                  background: AppColors.gamificationLight,
                                ),
                                const Spacer(),
                                Text(
                                  '${surah.ayahCount} ayahs',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(surah.name, style: AppTextStyles.title),
                            const SizedBox(height: AppSpacing.xs),
                            Text(surah.translation, style: AppTextStyles.body),
                            const SizedBox(height: AppSpacing.sm),
                            Text(surah.summary, style: AppTextStyles.caption),
                            const SizedBox(height: AppSpacing.md),
                            PrimaryButton(
                              label: 'View overview',
                              onPressed: () => context.go('/child/surah/${surah.id}'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: surahs.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => SliverToBoxAdapter(
              child: Text('Unable to load surahs.', style: AppTextStyles.body),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'View progress',
                  onPressed: () => context.go('/child/progress'),
                ),
                const SizedBox(height: AppSpacing.sm),
                SecondaryButton(
                  label: 'Change child',
                  onPressed: () => context.go('/parent/child/select'),
                ),
                const SizedBox(height: AppSpacing.sm),
                PrimaryButton(
                  label: 'Log out',
                  variant: PrimaryButtonVariant.danger,
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).signOut();
                    await ref.read(selectedChildIdProvider.notifier).clear();
                    if (context.mounted) {
                      context.go('/auth/entry');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
