import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/ui/app_app_bar.dart';
import '../../../core/ui/app_card.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/modal_sheet.dart';
import '../../../core/ui/primary_button.dart';
import '../../child/providers/child_providers.dart';
import '../models/map_models.dart';
import '../providers/map_providers.dart';

class PlanetMapScreen extends ConsumerWidget {
  const PlanetMapScreen({super.key, required this.galaxyId});

  final int galaxyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapAsync = ref.watch(mapStateProvider);
    final selectedChild = ref.watch(selectedChildProvider);
    final repo = ref.watch(mapRepositoryProvider);

    return AppScaffold(
      appBar: const AppAppBar(title: 'Planet Map'),
      body: mapAsync.when(
        data: (state) {
          if (state == null) {
            return Center(
              child: Text('Select a child to continue.', style: AppTextStyles.body),
            );
          }

          GalaxyNode? galaxy;
          for (final item in state.galaxies) {
            if (item.id == galaxyId) {
              galaxy = item;
              break;
            }
          }
          if (galaxy == null) {
            return Center(
              child: Text('Galaxy not found.', style: AppTextStyles.body),
            );
          }

          final galaxyNode = galaxy;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${galaxyNode.nameEn} Galaxy', style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${state.slotsRemaining} active surah slots available',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: GridView.builder(
                  itemCount: galaxyNode.surahs.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (context, index) {
                    final surah = galaxyNode.surahs[index];
                    return _PlanetCard(
                      surah: surah,
                      onTap: () async {
                        if (surah.locked || selectedChild == null) return;

                        if (!surah.isActive && !surah.isCompleted) {
                          try {
                            await repo.startSurah(childId: selectedChild.id, surahId: surah.id);
                            ref.invalidate(mapStateProvider);
                          } catch (error) {
                            if (!context.mounted) return;
                            await ModalSheetTrigger.show(
                              context,
                              sheet: ModalSheet(
                                title: 'Unable to start surah',
                                message: '$error',
                                variant: ModalSheetVariant.fail,
                                primaryAction: PrimaryButton(
                                  label: 'Okay',
                                  onPressed: () => context.pop(),
                                ),
                              ),
                            );
                            return;
                          }
                        }

                        if (!context.mounted) return;
                        context.push('/child/surah/${surah.id}');
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Unable to load planets.', style: AppTextStyles.body),
        ),
      ),
    );
  }
}

class _PlanetCard extends StatelessWidget {
  const _PlanetCard({
    required this.surah,
    required this.onTap,
  });

  final SurahNode surah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLocked = surah.locked;
    final label = surah.isCompleted
        ? 'Completed'
        : surah.isActive
            ? 'Active'
            : isLocked
                ? _reasonLabel(surah.lockReason)
                : 'Available';

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: isLocked ? 0.45 : 1,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Surah ${surah.id}', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.xs),
            Text(
              surah.name,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            PrimaryButton(
              label: isLocked ? 'Locked' : (surah.isActive ? 'Continue' : 'Start'),
              isDisabled: isLocked,
              onPressed: isLocked ? null : onTap,
            ),
          ],
        ),
      ),
    );
  }

  String _reasonLabel(String? reason) {
    switch (reason) {
      case 'NO_SLOTS':
        return 'Complete an active surah to unlock';
      case 'COMING_SOON':
        return 'Coming soon';
      case 'GALAXY_LOCKED':
        return 'Galaxy locked';
      default:
        return 'Locked';
    }
  }
}
