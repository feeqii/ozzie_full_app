import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/ui/app_app_bar.dart';
import '../../core/ui/app_scaffold.dart';
import '../../core/ui/atlas_background.dart';
import '../../core/ui/pin_input.dart';
import '../../core/ui/primary_button.dart';
import '../auth/controllers/auth_controller.dart';

class ParentPlaceholderScreen extends ConsumerWidget {
  const ParentPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      appBar: const AppAppBar(title: 'Parent PIN', showBack: false),
      background: const AtlasBackground(seed: 71, intensity: 0.75, showGrid: false),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scheme = Theme.of(context).colorScheme;
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Enter PIN', style: Theme.of(context).textTheme.displayLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Parent gate placeholder for milestone 1.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.78),
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const PinInput(length: 4),
                    const Spacer(),
                    PrimaryButton(
                      label: 'Continue',
                      onPressed: () {},
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PrimaryButton(
                      label: 'Log out',
                      variant: PrimaryButtonVariant.danger,
                      onPressed: () async {
                        await ref.read(authControllerProvider.notifier).signOut();
                        if (context.mounted) {
                          context.go('/auth/entry');
                        }
                      },
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
