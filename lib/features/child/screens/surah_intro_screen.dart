import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/ui/app_app_bar.dart';
import '../../../core/ui/app_card.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/primary_button.dart';
import '../../map/providers/map_providers.dart';
import '../providers/child_providers.dart';

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

    return AppScaffold(
      appBar: const AppAppBar(title: 'Surah Introduction'),
      body: Center(
        child: AppCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Before we begin', style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Let\'s learn what this surah is about, then we\'ll start verse by verse.',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'I understand, continue',
                isDisabled: child == null,
                onPressed: child == null
                    ? null
                    : () async {
                        await repo.completeLevel(childId: child.id, levelId: levelId);
                        if (context.mounted) {
                          context.pop();
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

