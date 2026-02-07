import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/ui/app_app_bar.dart';
import '../../../core/ui/app_card.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/primary_button.dart';
import '../providers/map_providers.dart';

class GalaxyMapScreen extends ConsumerWidget {
  const GalaxyMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapAsync = ref.watch(mapStateProvider);

    return AppScaffold(
      appBar: const AppAppBar(title: 'Galaxy Map'),
      body: mapAsync.when(
        data: (state) {
          if (state == null) {
            return Center(
              child: Text('Select a child to continue.', style: AppTextStyles.body),
            );
          }

          final galaxies = state.galaxies;
          if (galaxies.isEmpty) {
            return Center(
              child: Text('No galaxies available.', style: AppTextStyles.body),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Swipe to explore galaxies',
                style: AppTextStyles.title,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${state.slotsRemaining} of 3 surah slots available',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: PageView.builder(
                  controller: PageController(viewportFraction: 0.9),
                  itemCount: galaxies.length,
                  itemBuilder: (context, index) {
                    final galaxy = galaxies[index];
                    final isLocked = !galaxy.unlocked;
                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isLocked ? 0.45 : 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        child: AppCard(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Galaxy ${galaxy.orderIndex}',
                                style: AppTextStyles.caption,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                galaxy.nameEn,
                                style: AppTextStyles.title,
                              ),
                              if (galaxy.nameAr != null && galaxy.nameAr!.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(galaxy.nameAr!, style: AppTextStyles.arabicBody),
                              ],
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                isLocked
                                    ? 'Locked. Complete the previous galaxy to unlock.'
                                    : galaxy.completed
                                        ? 'Completed'
                                        : 'Unlocked',
                                style: AppTextStyles.body,
                              ),
                              const Spacer(),
                              PrimaryButton(
                                label: isLocked ? 'Locked' : 'Enter galaxy',
                                isDisabled: isLocked,
                                onPressed: isLocked
                                    ? null
                                    : () => context.push('/child/map/galaxy/${galaxy.id}'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Unable to load map.', style: AppTextStyles.body),
        ),
      ),
    );
  }
}

