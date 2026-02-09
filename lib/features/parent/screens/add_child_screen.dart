import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_extensions.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/ui/app_app_bar.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/atlas_background.dart';
import '../../../core/ui/app_snackbar.dart';
import '../../../core/ui/app_text_field.dart';
import '../../../core/ui/primary_button.dart';
import '../../child/providers/child_providers.dart';

class AddChildScreen extends ConsumerStatefulWidget {
  const AddChildScreen({super.key});

  @override
  ConsumerState<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends ConsumerState<AddChildScreen> {
  final _nameController = TextEditingController();
  String? _errorText;
  bool _isLoading = false;
  int? _selectedYear;
  String? _selectedGender;

  List<int> get _yearOptions {
    final now = DateTime.now().year;
    return List.generate(13, (index) => now - 3 - index);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorText = 'Enter your child\'s name.';
      });
      return;
    }

    if (_selectedYear == null) {
      AppSnackbar.show(context, message: 'Select your child\'s birth year.');
      return;
    }

    if (_selectedGender == null) {
      AppSnackbar.show(context, message: 'Select your child\'s gender.');
      return;
    }

    setState(() {
      _errorText = null;
      _isLoading = true;
    });

    try {
      final existingCount = ref.read(childrenProvider).asData?.value.length ?? 0;
      final repo = ref.read(childRepositoryProvider);
      final child = await repo.addChild(
        name: name,
        birthYear: _selectedYear,
        gender: _selectedGender,
      );
      await repo.ensureChildSettings(child.id);
      ref.invalidate(childrenProvider);

      if (!mounted) return;
      AppSnackbar.show(context, message: 'Child added successfully.');

      if (existingCount == 0) {
        await ref.read(selectedChildIdProvider.notifier).selectChild(child.id);
        if (!mounted) return;
        context.go('/child/home');
      } else {
        await ref.read(selectedChildIdProvider.notifier).clear();
        if (!mounted) return;
        context.go('/parent/child/select');
      }
    } catch (error) {
      AppSnackbar.show(context, message: 'Unable to add child. Try again.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showYearPicker() async {
    final years = _yearOptions;
    var initialIndex = 0;
    if (_selectedYear != null) {
      final existingIndex = years.indexOf(_selectedYear!);
      if (existingIndex >= 0) {
        initialIndex = existingIndex;
      }
    }

    var tempYear = years[initialIndex];

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final surfaces = context.surfaces;
        final scheme = Theme.of(context).colorScheme;

        return SafeArea(
          child: SizedBox(
            height: 320,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
              child: Container(
                decoration: BoxDecoration(
                  color: surfaces.sheet.withValues(alpha: 0.98),
                  border: Border.all(color: surfaces.outlineStrong.withValues(alpha: 0.14), width: 1.4),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select year',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.25,
                                ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() => _selectedYear = tempYear);
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: scheme.primary,
                            ),
                            child: Text(
                              'Done',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: surfaces.outlineStrong.withValues(alpha: 0.12),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: initialIndex,
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (index) {
                          tempYear = years[index];
                        },
                        children: years
                            .map(
                              (year) => Center(
                                child: Text(
                                  year.toString(),
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AppAppBar(title: 'Add Child'),
      background: const AtlasBackground(seed: 79, intensity: 0.7, showGrid: false),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scheme = Theme.of(context).colorScheme;
          final surfaces = context.surfaces;

          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Who will recite?', style: Theme.of(context).textTheme.displayLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Please add your child details.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.78),
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                      label: 'Child name',
                      controller: _nameController,
                      hintText: 'Your child name',
                      errorText: _errorText,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Child year of birth', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: AppSpacing.sm),
                    InkWell(
                      onTap: _isLoading ? null : _showYearPicker,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.lg,
                        ),
                        decoration: BoxDecoration(
                          color: surfaces.card,
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(
                            color: surfaces.outlineStrong.withValues(alpha: 0.16),
                            width: 1.4,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedYear?.toString() ?? 'Select year',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: _selectedYear == null
                                          ? scheme.onSurface.withValues(alpha: 0.55)
                                          : scheme.onSurface,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: scheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Child gender', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _GenderButton(
                            label: 'Girl',
                            isSelected: _selectedGender == 'girl',
                            onTap: () => setState(() => _selectedGender = 'girl'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _GenderButton(
                            label: 'Boy',
                            isSelected: _selectedGender == 'boy',
                            onTap: () => setState(() => _selectedGender = 'boy'),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    PrimaryButton(
                      label: 'Confirm',
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GenderButton extends StatelessWidget {
  const _GenderButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final scheme = Theme.of(context).colorScheme;
    final backgroundColor = isSelected ? scheme.primary : surfaces.card;
    final borderColor = isSelected ? scheme.primary : surfaces.outlineStrong.withValues(alpha: 0.16);
    final textColor = isSelected ? scheme.onPrimary : scheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: 1.4,
          ),
          color: backgroundColor,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: surfaces.shadow,
                    blurRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
        ),
      ),
    );
  }
}
