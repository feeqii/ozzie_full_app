import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../child/providers/child_providers.dart';
import '../../onboarding/theme/onboarding_tokens.dart';
import '../../onboarding/ui/onboarding_button.dart';
import '../../onboarding/ui/onboarding_scaffold.dart';
import '../../onboarding/ui/onboarding_surface_card.dart';
import '../../onboarding/ui/onboarding_text_field.dart';
import '../../onboarding/ui/onboarding_theme_toggle.dart';

class AddChildScreen extends ConsumerStatefulWidget {
  const AddChildScreen({super.key});

  @override
  ConsumerState<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends ConsumerState<AddChildScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  int? _selectedYear;
  String? _selectedGender;

  List<int> get _yearOptions {
    final current = DateTime.now().year;
    return List.generate(13, (index) => current - 3 - index);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Please enter your child\'s name.');
      return;
    }

    if (_selectedYear == null) {
      setState(() => _error = 'Please select birth year.');
      return;
    }

    if (_selectedGender == null) {
      setState(() => _error = 'Please select gender.');
      return;
    }

    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      final repo = ref.read(childRepositoryProvider);
      final child = await repo.addChild(
        name: name,
        birthYear: _selectedYear,
        gender: _selectedGender,
      );
      await repo.ensureChildSettings(child.id);

      ref.invalidate(childrenProvider);
      await ref.read(selectedChildIdProvider.notifier).clear();

      if (!mounted) {
        return;
      }
      context.go('/parent/child/select');
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not add child. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showYearPicker() async {
    final years = _yearOptions;
    var initialIndex = 0;
    if (_selectedYear != null) {
      final selectedIndex = years.indexOf(_selectedYear!);
      if (selectedIndex >= 0) {
        initialIndex = selectedIndex;
      }
    }

    var temporaryYear = years[initialIndex];

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colors = OnboardingColors.resolve(Theme.of(context).brightness);

        return SafeArea(
          child: Container(
            height: 320,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(OnboardingRadii.lg),
              ),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: OnboardingSpacing.md,
                    vertical: OnboardingSpacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select birth year',
                        style: OnboardingTypography.title(colors.textPrimary),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _selectedYear = temporaryYear);
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Done',
                          style: OnboardingTypography.label(colors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: colors.border),
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 42,
                    scrollController: FixedExtentScrollController(
                      initialItem: initialIndex,
                    ),
                    onSelectedItemChanged: (index) {
                      temporaryYear = years[index];
                    },
                    children: years.map((year) {
                      return Center(
                        child: Text(
                          '$year',
                          style: OnboardingTypography.bodyStrong(
                            colors.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = OnboardingColors.resolve(Theme.of(context).brightness);

    return OnboardingScaffold(
      showBack: true,
      onBack: () => context.pop(),
      trailing: const OnboardingThemeToggle(),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tell us about your child',
              style: OnboardingTypography.headline(colors.textPrimary),
            ),
            const SizedBox(height: OnboardingSpacing.sm),
            Text(
              'This helps us personalize their recitation path.',
              style: OnboardingTypography.body(colors.textSecondary),
            ),
            const SizedBox(height: OnboardingSpacing.lg),
            OnboardingTextField(
              label: 'Child name',
              hint: 'Amina',
              controller: _nameController,
              errorText: _error,
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: OnboardingSpacing.md),
            Text(
              'Birth year',
              style: OnboardingTypography.label(colors.textPrimary),
            ),
            const SizedBox(height: OnboardingSpacing.sm),
            _PickerTile(
              value: _selectedYear == null
                  ? 'Select year'
                  : _selectedYear.toString(),
              onTap: _isLoading ? null : _showYearPicker,
            ),
            const SizedBox(height: OnboardingSpacing.md),
            Text(
              'Gender',
              style: OnboardingTypography.label(colors.textPrimary),
            ),
            const SizedBox(height: OnboardingSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _GenderChoice(
                    label: 'Girl',
                    selected: _selectedGender == 'girl',
                    onTap: () => setState(() => _selectedGender = 'girl'),
                  ),
                ),
                const SizedBox(width: OnboardingSpacing.sm),
                Expanded(
                  child: _GenderChoice(
                    label: 'Boy',
                    selected: _selectedGender == 'boy',
                    onTap: () => setState(() => _selectedGender = 'boy'),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: OnboardingSpacing.md),
              Text(
                _error!,
                style: OnboardingTypography.label(OnboardingPalette.danger),
              ),
            ],
            const SizedBox(height: OnboardingSpacing.xl),
            const OnboardingSurfaceCard(child: _WarmNote()),
            const SizedBox(height: OnboardingSpacing.xl),
            OnboardingButton(
              label: 'Save child profile',
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({required this.value, this.onTap});

  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = OnboardingColors.resolve(Theme.of(context).brightness);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(OnboardingRadii.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(OnboardingRadii.sm),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: OnboardingSpacing.md,
            vertical: OnboardingSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(OnboardingRadii.sm),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: OnboardingTypography.body(
                    value == 'Select year'
                        ? colors.textSecondary
                        : colors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderChoice extends StatelessWidget {
  const _GenderChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = OnboardingColors.resolve(Theme.of(context).brightness);

    return Material(
      color: selected ? colors.primary : colors.surface,
      borderRadius: BorderRadius.circular(OnboardingRadii.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(OnboardingRadii.sm),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: OnboardingSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(OnboardingRadii.sm),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: OnboardingTypography.bodyStrong(
                selected ? colors.onPrimary : colors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WarmNote extends StatelessWidget {
  const _WarmNote();

  @override
  Widget build(BuildContext context) {
    final colors = OnboardingColors.resolve(Theme.of(context).brightness);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: OnboardingPalette.green.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(OnboardingRadii.sm),
          ),
          child: const Icon(
            Icons.favorite_border_rounded,
            color: OnboardingPalette.green,
          ),
        ),
        const SizedBox(width: OnboardingSpacing.sm),
        Expanded(
          child: Text(
            'You can add more children anytime from the parent area.',
            style: OnboardingTypography.body(colors.textPrimary),
          ),
        ),
      ],
    );
  }
}
