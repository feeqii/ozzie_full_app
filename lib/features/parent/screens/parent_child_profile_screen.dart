import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../child/providers/child_providers.dart';
import '../../progress/models/child_progress_summary.dart';
import '../../progress/providers/progress_providers.dart';
import '../utils/parent_child_lookup.dart';
import '../ui/parent_scaffold.dart';
import '../ui/parent_tokens.dart';
import '../ui/parent_widgets.dart';

class ParentChildProfileScreen extends ConsumerStatefulWidget {
  const ParentChildProfileScreen({super.key, required this.childId});

  final String childId;

  @override
  ConsumerState<ParentChildProfileScreen> createState() =>
      _ParentChildProfileScreenState();
}

class _ParentChildProfileScreenState
    extends ConsumerState<ParentChildProfileScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  bool _editing = false;
  bool _saving = false;
  String? _error;
  String? _syncedChildId;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _syncFromChild(String childId, String name, int? birthYear) {
    if (_syncedChildId == childId) {
      return;
    }
    _nameController.text = name;
    _ageController.text = _ageFromBirthYear(birthYear)?.toString() ?? '';
    _syncedChildId = childId;
  }

  Future<void> _saveChild() async {
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim());

    if (name.isEmpty) {
      setState(() => _error = 'Child name is required.');
      return;
    }
    if (age == null || age < 2 || age > 18) {
      setState(() => _error = 'Age must be between 2 and 18.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final birthYear = DateTime.now().year - age;
      await ref
          .read(childRepositoryProvider)
          .updateChild(
            childId: widget.childId,
            name: name,
            birthYear: birthYear,
          );
      ref.invalidate(childrenProvider);
      if (!mounted) {
        return;
      }
      setState(() {
        _editing = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _error = 'Unable to save child profile right now.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(childrenProvider);

    return ParentScaffold(
      child: childrenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _ProfileMissingState(),
        data: (children) {
          final child = findChildById(children, widget.childId);
          if (child == null) {
            return const _ProfileMissingState();
          }

          _syncFromChild(child.id, child.name, child.birthYear);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ParentHeaderBar(
                title: 'Child Profile',
                onBack: () => context.pop(),
                trailing: ParentIconButton(
                  icon: _editing ? Icons.close_rounded : Icons.edit_outlined,
                  onPressed: () {
                    setState(() {
                      _editing = !_editing;
                      _error = null;
                    });
                  },
                  semanticLabel: _editing
                      ? 'Cancel edit'
                      : 'Edit child profile',
                ),
              ),
              const SizedBox(height: ParentSpacing.lg),
              Expanded(
                child: _editing
                    ? _EditProfileBody(
                        nameController: _nameController,
                        ageController: _ageController,
                        isSaving: _saving,
                        error: _error,
                        onSave: _saveChild,
                      )
                    : _ProfileOverview(
                        childName: child.name,
                        age: _ageFromBirthYear(child.birthYear),
                        statsAsync: ref.watch(
                          childProgressSummaryProvider(widget.childId),
                        ),
                        onOpenControl: () => context.push(
                          '/parent/child/${widget.childId}/control',
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  int? _ageFromBirthYear(int? year) {
    if (year == null) {
      return null;
    }
    return math.max(0, DateTime.now().year - year);
  }
}

class _ProfileOverview extends StatelessWidget {
  const _ProfileOverview({
    required this.childName,
    required this.age,
    required this.statsAsync,
    required this.onOpenControl,
  });

  final String childName;
  final int? age;
  final AsyncValue<ChildProgressSummary> statsAsync;
  final VoidCallback onOpenControl;

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: ParentSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricPanel(
                  title: 'Child\'s Name',
                  value: childName.toUpperCase(),
                ),
              ),
              const SizedBox(width: ParentSpacing.sm),
              Expanded(
                child: _MetricPanel(
                  title: 'Child\'s Age',
                  value: age?.toString() ?? '--',
                ),
              ),
            ],
          ),
          const SizedBox(height: ParentSpacing.sm),
          ParentPanel(
            child: Row(
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surfaceMuted,
                    border: Border.all(color: colors.border),
                  ),
                  child: Icon(
                    Icons.image_outlined,
                    color: colors.textSecondary,
                    size: 34,
                  ),
                ),
                const SizedBox(width: ParentSpacing.md),
                Expanded(
                  child: Text(
                    'Child\'s Avatar',
                    style: ParentText.label(colors.textPrimary),
                  ),
                ),
                Icon(Icons.edit_outlined, color: colors.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: ParentSpacing.md),
          statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => ParentPanel(
              child: Text(
                'Stats are unavailable right now.',
                style: ParentText.body(colors.textSecondary),
              ),
            ),
            data: (summary) {
              final maxScore = summary.score.entries.isEmpty
                  ? summary.score.latestScore
                  : summary.score.entries
                        .map((entry) => entry.score)
                        .reduce(math.max);
              final hasanat = summary.score.entries.fold<int>(
                0,
                (sum, entry) => sum + entry.score,
              );
              final badges = math.max(
                0,
                (summary.streak.bestStreak / 3).floor(),
              );
              final verseMaster = summary.score.entries
                  .where((entry) => entry.score >= 80)
                  .length;
              final chapterCount = summary.score.entries
                  .map((entry) => entry.surahId)
                  .whereType<int>()
                  .toSet()
                  .length;

              return Wrap(
                spacing: ParentSpacing.sm,
                runSpacing: ParentSpacing.sm,
                children: [
                  _StatCard(
                    icon: Icons.nights_stay_outlined,
                    value: '$hasanat',
                    label: 'Hasanat',
                  ),
                  _StatCard(
                    icon: Icons.local_fire_department_outlined,
                    value: '${summary.streak.bestStreak}',
                    label: 'Longest Streak',
                  ),
                  _StatCard(
                    icon: Icons.gps_fixed,
                    value: '$maxScore%',
                    label: 'Highest Score',
                  ),
                  _StatCard(
                    icon: Icons.workspace_premium_outlined,
                    value: '$badges',
                    label: 'Badges',
                  ),
                  _StatCard(
                    icon: Icons.emoji_events_outlined,
                    value: '$verseMaster',
                    label: 'Verse Master',
                  ),
                  _StatCard(
                    icon: Icons.menu_book_outlined,
                    value: '$chapterCount',
                    label: 'Chapter',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: ParentSpacing.lg),
          ParentPrimaryButton(
            label: 'Parent Control',
            onPressed: onOpenControl,
          ),
        ],
      ),
    );
  }
}

class _EditProfileBody extends StatelessWidget {
  const _EditProfileBody({
    required this.nameController,
    required this.ageController,
    required this.isSaving,
    required this.error,
    required this.onSave,
  });

  final TextEditingController nameController;
  final TextEditingController ageController;
  final bool isSaving;
  final String? error;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: ParentSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EditFieldCard(
            title: 'Child\'s Name',
            child: TextField(
              controller: nameController,
              style: ParentText.title(colors.textPrimary),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: ParentSpacing.sm),
          _EditFieldCard(
            title: 'Child\'s Age',
            child: TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              style: ParentText.title(colors.textPrimary),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: ParentSpacing.sm),
          _EditFieldCard(
            title: 'Child\'s Avatar',
            child: Row(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surfaceMuted,
                    border: Border.all(color: colors.border),
                  ),
                  child: Icon(
                    Icons.image_outlined,
                    color: colors.textSecondary,
                    size: 36,
                  ),
                ),
                const SizedBox(width: ParentSpacing.md),
                Expanded(
                  child: Text(
                    'Avatar upload is coming in a follow-up iteration.',
                    style: ParentText.body(colors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          // TODO(parent-profile): connect avatar upload + media picker.
          if (error != null) ...[
            const SizedBox(height: ParentSpacing.md),
            Text(error!, style: ParentText.label(colors.danger)),
          ],
          const SizedBox(height: ParentSpacing.lg),
          ParentPrimaryButton(
            label: isSaving ? 'Saving...' : 'Save Changes',
            onPressed: isSaving ? null : onSave,
          ),
        ],
      ),
    );
  }
}

class _EditFieldCard extends StatelessWidget {
  const _EditFieldCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return ParentPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: ParentText.label(colors.textSecondary),
          ),
          const SizedBox(height: ParentSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _MetricPanel extends StatelessWidget {
  const _MetricPanel({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return ParentPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: ParentText.label(colors.textSecondary),
          ),
          const SizedBox(height: ParentSpacing.sm),
          Center(
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: ParentText.title(
                colors.textPrimary,
              ).copyWith(fontSize: 34),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return SizedBox(
      width:
          (MediaQuery.sizeOf(context).width -
              ParentSpacing.md * 2 -
              ParentSpacing.sm * 2) /
          3,
      child: ParentPanel(
        child: Column(
          children: [
            Icon(icon, color: colors.textPrimary),
            const SizedBox(height: ParentSpacing.xs),
            Text(value, style: ParentText.title(colors.textPrimary)),
            const SizedBox(height: ParentSpacing.xs),
            Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: ParentText.micro(colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMissingState extends StatelessWidget {
  const _ProfileMissingState();

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ParentHeaderBar(
          title: 'Child Profile',
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
