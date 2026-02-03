import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/ui/app_app_bar.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/app_snackbar.dart';
import '../../../core/ui/child_profile_card.dart';
import '../../../core/ui/empty_state.dart';
import '../../../core/ui/primary_button.dart';
import '../../child/providers/child_providers.dart';

class SelectChildScreen extends ConsumerWidget {
  const SelectChildScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenProvider);

    return AppScaffold(
      appBar: const AppAppBar(title: 'Parental Area', showBack: false),
      body: childrenAsync.when(
        data: (children) {
          if (children.isEmpty) {
            return EmptyState(
              title: 'No children yet',
              message: 'Add your child to begin their recitation journey.',
              buttonLabel: 'Add child',
              onPressed: () => context.go('/parent/child/add'),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Select a child', style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: ListView.separated(
                  itemCount: children.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final child = children[index];
                    return ChildProfileCard(
                      name: child.name,
                      subtitle: 'Tap to continue',
                      onTap: () async {
                        await ref.read(selectedChildIdProvider.notifier).selectChild(child.id);
                        if (context.mounted) {
                          context.go('/child/home');
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Add child',
                onPressed: () => context.go('/parent/child/add'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Unable to load children', style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.sm),
              Text('Please try again.', style: AppTextStyles.body),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Retry',
                onPressed: () {
                  ref.invalidate(childrenProvider);
                  AppSnackbar.show(context, message: 'Retrying...');
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
