import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/ui/app_app_bar.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/atlas_background.dart';
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
      appBar: AppAppBar(
        title: 'Parental Area',
        showBack: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard_outlined),
            onPressed: () => context.push('/parent/dashboard'),
          ),
        ],
      ),
      background: const AtlasBackground(seed: 77, intensity: 0.7, showGrid: false),
      body: childrenAsync.when(
        data: (children) {
          if (children.isEmpty) {
            return EmptyState(
              title: 'No children yet',
              message: 'Add your child to begin their recitation journey.',
              buttonLabel: 'Add child',
              onPressed: () => context.push('/parent/child/add'),
            );
          }

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
                        Text('Select a child', style: Theme.of(context).textTheme.displayLarge),
                        const SizedBox(height: AppSpacing.lg),
                        ...children
                            .asMap()
                            .entries
                            .map(
                              (entry) => Padding(
                                padding: EdgeInsets.only(
                                  bottom: entry.key == children.length - 1 ? 0 : AppSpacing.md,
                                ),
                                child: ChildProfileCard(
                                  name: entry.value.name,
                                  subtitle: 'Tap to continue',
                                  onTap: () async {
                                    await ref
                                        .read(selectedChildIdProvider.notifier)
                                        .selectChild(entry.value.id);
                                    if (context.mounted) {
                                      context.push('/child/home');
                                    }
                                  },
                                ),
                              ),
                            ),
                        const Spacer(),
                        PrimaryButton(
                          label: 'Add child',
                          onPressed: () => context.push('/parent/child/add'),
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
        error: (error, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Unable to load children', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Please try again.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
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
