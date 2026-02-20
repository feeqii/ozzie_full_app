import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../child/providers/child_providers.dart';
import '../utils/parent_child_lookup.dart';
import '../ui/parent_scaffold.dart';
import '../ui/parent_tokens.dart';
import '../ui/parent_widgets.dart';

class ParentChildDashboardScreen extends ConsumerWidget {
  const ParentChildDashboardScreen({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenProvider);

    return ParentScaffold(
      child: childrenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _MissingChildState(),
        data: (children) {
          final child = findChildById(children, childId);
          if (child == null) {
            return const _MissingChildState();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ParentHeaderBar(
                title: 'Parental Dashboard',
                onBack: () => context.pop(),
              ),
              const SizedBox(height: ParentSpacing.xl),
              ParentPanel(
                child: Text(
                  '${child.name.toUpperCase()} PANEL',
                  textAlign: TextAlign.center,
                  style: ParentText.title(
                    ParentColors.resolve(
                      Theme.of(context).brightness,
                    ).textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: ParentSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _DashboardTile(
                      label: 'Child Profile',
                      onTap: () =>
                          context.push('/parent/child/$childId/profile'),
                    ),
                  ),
                  const SizedBox(width: ParentSpacing.md),
                  Expanded(
                    child: _DashboardTile(
                      label: 'Child Progress',
                      onTap: () =>
                          context.push('/parent/child/$childId/progress'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ParentSpacing.xl),
              ParentSectionTitle('Parent Settings'),
              const SizedBox(height: ParentSpacing.md),
              Center(
                child: SizedBox(
                  width: 220,
                  child: _DashboardTile(
                    label: 'Control',
                    onTap: () => context.push('/parent/child/$childId/control'),
                  ),
                ),
              ),
              const Spacer(),
              ParentPrimaryButton(
                label: 'Back to child mode',
                onPressed: () => context.go('/child/home'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return ParentPanel(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: ParentSpacing.md,
        vertical: ParentSpacing.xl,
      ),
      child: Center(
        child: Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: ParentText.label(colors.textSecondary),
        ),
      ),
    );
  }
}

class _MissingChildState extends StatelessWidget {
  const _MissingChildState();

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ParentHeaderBar(
          title: 'Parental Dashboard',
          onBack: () => context.go('/parent/dashboard'),
        ),
        const SizedBox(height: ParentSpacing.xl),
        ParentPanel(
          child: Text(
            'Child profile was not found. Return to parent area and pick another child.',
            style: ParentText.body(colors.textSecondary),
          ),
        ),
        const SizedBox(height: ParentSpacing.lg),
        ParentPrimaryButton(
          label: 'Back to parent area',
          onPressed: () => context.go('/parent/dashboard'),
        ),
      ],
    );
  }
}
