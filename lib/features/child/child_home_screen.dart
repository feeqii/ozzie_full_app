import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/ui/app_app_bar.dart';
import '../../core/ui/app_scaffold.dart';
import '../../core/ui/primary_button.dart';
import '../auth/controllers/auth_controller.dart';
import '../child/providers/child_providers.dart';

class ChildHomeScreen extends ConsumerWidget {
  const ChildHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider);

    return AppScaffold(
      appBar: const AppAppBar(title: 'Child Home', showBack: false),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            child == null ? 'Child Home' : 'Welcome, ${child.name}',
            style: AppTextStyles.title,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Placeholder for learning journey.', style: AppTextStyles.body),
          const Spacer(),
          PrimaryButton(
            label: 'Change child',
            onPressed: () => context.go('/parent/child/select'),
          ),
          const SizedBox(height: AppSpacing.md),
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
    );
  }
}
