import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/ui/app_app_bar.dart';
import '../../../core/ui/app_scaffold.dart';
import '../../../core/ui/app_snackbar.dart';
import '../../../core/ui/app_text_field.dart';
import '../../../core/ui/primary_button.dart';
import '../../child/providers/child_providers.dart';
import '../../child/repo/child_repository.dart';

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
        if (context.mounted) {
          context.go('/child/home');
        }
      } else {
        await ref.read(selectedChildIdProvider.notifier).clear();
        if (context.mounted) {
          context.go('/parent/child/select');
        }
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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AppAppBar(title: 'Add Child'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Who will recite?', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          Text('Please add your child details.', style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: 'Child name',
            controller: _nameController,
            hintText: 'Your child name',
            errorText: _errorText,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Child year of birth', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<int>(
            value: _selectedYear,
            items: _yearOptions
                .map(
                  (year) => DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedYear = value),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Child gender', style: AppTextStyles.caption),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.textNavy : AppColors.progressTrack,
            width: 1.2,
          ),
          color: AppColors.white,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textNavy,
          ),
        ),
      ),
    );
  }
}
