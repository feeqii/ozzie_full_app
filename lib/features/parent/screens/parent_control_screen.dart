import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../child/providers/child_providers.dart';
import '../utils/parent_child_lookup.dart';
import '../ui/parent_scaffold.dart';
import '../ui/parent_tokens.dart';
import '../ui/parent_widgets.dart';

class ParentControlScreen extends ConsumerStatefulWidget {
  const ParentControlScreen({super.key, required this.childId});

  final String childId;

  @override
  ConsumerState<ParentControlScreen> createState() =>
      _ParentControlScreenState();
}

class _ParentControlScreenState extends ConsumerState<ParentControlScreen> {
  static const _goalSteps = [5, 10, 15, 30, 45];

  int _selectedGoal = 5;
  bool _showIllustrations = true;
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(childrenProvider);
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return ParentScaffold(
      child: childrenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _MissingControlState(),
        data: (children) {
          final child = findChildById(children, widget.childId);
          if (child == null) {
            return const _MissingControlState();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ParentHeaderBar(title: 'Control', onBack: () => context.pop()),
              const SizedBox(height: ParentSpacing.xl),
              ParentSectionTitle('Daily Time Goal'),
              const SizedBox(height: ParentSpacing.sm),
              _GoalStepper(
                values: _goalSteps,
                selected: _selectedGoal,
                onSelect: (value) {
                  setState(() => _selectedGoal = value);
                  // TODO(parent-control): persist daily goal when product settings API is finalized.
                },
              ),
              const SizedBox(height: ParentSpacing.lg),
              ParentPanel(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'SHOW ILLUSTRATIONS',
                        style: ParentText.label(colors.textPrimary),
                      ),
                    ),
                    Switch.adaptive(
                      value: _showIllustrations,
                      activeThumbColor: colors.success,
                      activeTrackColor: colors.success.withValues(alpha: 0.45),
                      onChanged: (value) {
                        setState(() => _showIllustrations = value);
                        // TODO(parent-control): persist child illustration preference in backend settings.
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ParentSpacing.sm),
              ParentActionTile(
                label: 'Notifications',
                icon: Icons.notifications_outlined,
                onTap: () => context.push(
                  '/parent/child/${widget.childId}/control/notifications',
                ),
              ),
              const SizedBox(height: ParentSpacing.xl),
              ParentSectionTitle('Child Accounts Management'),
              const SizedBox(height: ParentSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ParentRoundAvatar(
                    label: 'Delete ${child.name}',
                    onTap: _isDeleting ? null : _confirmDeleteChild,
                  ),
                  ParentRoundAvatar(
                    label: 'Add New Child',
                    isAdd: true,
                    onTap: () => context.push('/parent/child/add'),
                  ),
                ],
              ),
              const Spacer(),
              ParentPrimaryButton(
                label: _isDeleting ? 'Deleting...' : 'Back to dashboard',
                onPressed: _isDeleting ? null : () => context.pop(),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteChild() async {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            'Delete child profile',
            style: ParentText.title(colors.textPrimary),
          ),
          content: Text(
            'This will permanently remove this child profile and related progress data.',
            style: ParentText.body(colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: ParentText.label(colors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('Delete', style: ParentText.label(colors.danger)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _isDeleting = true);

    try {
      await ref.read(childRepositoryProvider).deleteChild(widget.childId);
      ref.invalidate(childrenProvider);
      final remaining = await ref.read(childrenProvider.future);

      if (remaining.isEmpty) {
        await ref.read(selectedChildIdProvider.notifier).clear();
      } else {
        await ref
            .read(selectedChildIdProvider.notifier)
            .selectChild(remaining.first.id);
      }

      if (!mounted) {
        return;
      }
      context.go('/parent/dashboard');
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete child profile. Please try again.',
            style: ParentText.body(ParentPalette.light),
          ),
        ),
      );
      setState(() => _isDeleting = false);
    }
  }
}

class _GoalStepper extends StatelessWidget {
  const _GoalStepper({
    required this.values,
    required this.selected,
    required this.onSelect,
  });

  final List<int> values;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return Column(
      children: [
        SizedBox(
          height: 34,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 0,
                right: 0,
                child: Container(height: 3, color: colors.border),
              ),
              Row(
                children: [
                  for (final value in values)
                    Expanded(
                      child: Center(
                        child: GestureDetector(
                          onTap: () => onSelect(value),
                          child: Container(
                            width: value == selected ? 20 : 16,
                            height: value == selected ? 20 : 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: value == selected
                                  ? colors.textPrimary
                                  : colors.surfaceMuted,
                              border: Border.all(
                                color: colors.border,
                                width: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: ParentSpacing.xs),
        Row(
          children: [
            for (final value in values)
              Expanded(
                child: Text(
                  '${value}m',
                  textAlign: TextAlign.center,
                  style: ParentText.micro(colors.textSecondary),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MissingControlState extends StatelessWidget {
  const _MissingControlState();

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ParentHeaderBar(
          title: 'Control',
          onBack: () => context.go('/parent/dashboard'),
        ),
        const SizedBox(height: ParentSpacing.xl),
        ParentPanel(
          child: Text(
            'Child profile could not be loaded.',
            style: ParentText.body(colors.textSecondary),
          ),
        ),
      ],
    );
  }
}
