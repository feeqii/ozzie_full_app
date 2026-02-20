import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../child/providers/child_providers.dart';
import '../ui/parent_scaffold.dart';
import '../ui/parent_tokens.dart';
import '../ui/parent_widgets.dart';

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenProvider);
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return ParentScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ParentHeaderBar(
            title: 'Parental Area',
            onBack: () => context.go('/child/home'),
            trailing: ParentIconButton(
              icon: Icons.settings_outlined,
              onPressed: () => context.push('/parent/settings'),
              semanticLabel: 'Parent settings',
            ),
          ),
          const SizedBox(height: ParentSpacing.lg),
          ParentSectionTitle('Select a child'),
          const SizedBox(height: ParentSpacing.md),
          Expanded(
            child: childrenAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _ParentAreaError(
                onRetry: () => ref.invalidate(childrenProvider),
              ),
              data: (children) {
                if (children.isEmpty) {
                  return Center(
                    child: ParentRoundAvatar(
                      label: 'Add New Child',
                      isAdd: true,
                      onTap: () => context.push('/parent/child/add'),
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: ParentSpacing.xl),
                  child: Wrap(
                    spacing: ParentSpacing.lg,
                    runSpacing: ParentSpacing.xl,
                    alignment: WrapAlignment.start,
                    children: [
                      for (final child in children)
                        ParentRoundAvatar(
                          label: child.name,
                          onTap: () async {
                            await ref
                                .read(selectedChildIdProvider.notifier)
                                .selectChild(child.id);
                            if (!context.mounted) {
                              return;
                            }
                            context.push('/parent/child/${child.id}/dashboard');
                          },
                        ),
                      ParentRoundAvatar(
                        label: 'Add New Child',
                        isAdd: true,
                        onTap: () => context.push('/parent/child/add'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: ParentSpacing.md),
          Text(
            'Parent controls are intentionally separated from child mode.',
            textAlign: TextAlign.center,
            style: ParentText.micro(colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ParentAreaError extends StatelessWidget {
  const _ParentAreaError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return Center(
      child: ParentPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Unable to load child profiles.',
              textAlign: TextAlign.center,
              style: ParentText.title(colors.textPrimary),
            ),
            const SizedBox(height: ParentSpacing.sm),
            ParentPrimaryButton(label: 'Retry', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
