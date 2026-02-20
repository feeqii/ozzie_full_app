import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../auth/providers/auth_session_provider.dart';
import '../../child/providers/child_providers.dart';
import '../ui/parent_scaffold.dart';
import '../ui/parent_tokens.dart';
import '../ui/parent_widgets.dart';

class ParentSettingsScreen extends ConsumerWidget {
  const ParentSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).asData?.value;
    final email = session?.user.email ?? 'No email available';

    return ParentScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ParentHeaderBar(title: 'Settings', onBack: () => context.pop()),
          const SizedBox(height: ParentSpacing.xl),
          const ParentSectionTitle('Account'),
          const SizedBox(height: ParentSpacing.sm),
          ParentPanel(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    email,
                    style: ParentText.body(
                      ParentColors.resolve(
                        Theme.of(context).brightness,
                      ).textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.edit_outlined,
                  color: ParentColors.resolve(
                    Theme.of(context).brightness,
                  ).textSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: ParentSpacing.sm),
          ParentActionTile(
            label: 'PIN',
            icon: Icons.pin_outlined,
            onTap: () {
              final uri = Uri(
                path: '/parent/pin/setup',
                queryParameters: {'next': '/parent/settings'},
              );
              context.push(uri.toString());
            },
          ),
          const SizedBox(height: ParentSpacing.xl),
          const ParentSectionTitle('Manage Account'),
          const SizedBox(height: ParentSpacing.sm),
          ParentActionTile(
            label: 'Sign Out',
            icon: Icons.logout_rounded,
            onTap: () async {
              final confirmed = await _confirmAction(
                context: context,
                title: 'Sign out now?',
                message: 'You will return to the account entry screen.',
                actionLabel: 'Sign out',
              );
              if (confirmed != true) {
                return;
              }

              await ref.read(authControllerProvider.notifier).signOut();
              await ref.read(selectedChildIdProvider.notifier).clear();
              if (!context.mounted) {
                return;
              }
              context.go('/auth/entry');
            },
          ),
          const SizedBox(height: ParentSpacing.sm),
          ParentActionTile(
            label: 'Support and Feedback',
            icon: Icons.support_agent_outlined,
            onTap: () {
              // TODO(parent-settings): connect support + feedback endpoint.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Support and feedback is coming soon.'),
                ),
              );
            },
          ),
          const SizedBox(height: ParentSpacing.sm),
          ParentActionTile(
            label: 'Terms and Privacy',
            icon: Icons.privacy_tip_outlined,
            onTap: () {
              // TODO(parent-settings): wire terms/privacy URL.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Terms and privacy links are not wired yet.'),
                ),
              );
            },
          ),
          const SizedBox(height: ParentSpacing.sm),
          ParentActionTile(
            label: 'Delete Account',
            icon: Icons.delete_outline,
            onTap: () async {
              final confirmed = await _confirmAction(
                context: context,
                title: 'Delete account?',
                message:
                    'This action is destructive and cannot be undone once backend deletion is enabled.',
                actionLabel: 'Continue',
              );
              if (confirmed != true || !context.mounted) {
                return;
              }

              // TODO(parent-settings): connect secure account deletion endpoint.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delete account flow is not available yet.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static Future<bool?> _confirmAction({
    required BuildContext context,
    required String title,
    required String message,
    required String actionLabel,
  }) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(title, style: ParentText.title(colors.textPrimary)),
          content: Text(message, style: ParentText.body(colors.textSecondary)),
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
              child: Text(
                actionLabel,
                style: ParentText.label(colors.textPrimary),
              ),
            ),
          ],
        );
      },
    );
  }
}
