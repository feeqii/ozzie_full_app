import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/parent_scaffold.dart';
import '../ui/parent_tokens.dart';
import '../ui/parent_widgets.dart';

class ParentNotificationsScreen extends StatefulWidget {
  const ParentNotificationsScreen({super.key});

  @override
  State<ParentNotificationsScreen> createState() =>
      _ParentNotificationsScreenState();
}

class _ParentNotificationsScreenState extends State<ParentNotificationsScreen> {
  bool _recitationReminder = true;
  bool _surahFinish = true;
  bool _sessionEnd = true;

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return ParentScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ParentHeaderBar(title: 'Notifications', onBack: () => context.pop()),
          const SizedBox(height: ParentSpacing.xl),
          _TogglePanel(
            label: 'Recitation Reminder',
            value: _recitationReminder,
            onChanged: (value) {
              setState(() => _recitationReminder = value);
              // TODO(parent-notifications): persist notification preference when backend fields are available.
            },
          ),
          const SizedBox(height: ParentSpacing.md),
          _TogglePanel(
            label: 'Surah Finish',
            value: _surahFinish,
            onChanged: (value) {
              setState(() => _surahFinish = value);
              // TODO(parent-notifications): persist notification preference when backend fields are available.
            },
          ),
          const SizedBox(height: ParentSpacing.md),
          _TogglePanel(
            label: 'Session End',
            value: _sessionEnd,
            onChanged: (value) {
              setState(() => _sessionEnd = value);
              // TODO(parent-notifications): persist notification preference when backend fields are available.
            },
          ),
          const Spacer(),
          Text(
            'Notification delivery wiring will be connected in a backend follow-up.',
            textAlign: TextAlign.center,
            style: ParentText.micro(colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _TogglePanel extends StatelessWidget {
  const _TogglePanel({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = ParentColors.resolve(Theme.of(context).brightness);

    return ParentPanel(
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: ParentText.label(colors.textPrimary),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: colors.success,
            activeTrackColor: colors.success.withValues(alpha: 0.45),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
