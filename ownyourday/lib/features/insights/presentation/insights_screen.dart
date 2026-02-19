import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ownyourday/state/providers.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final theme = Theme.of(context);

    final high = app.openTasks
        .where((task) => task.priority.name == 'high')
        .length;
    final medium = app.openTasks
        .where((task) => task.priority.name == 'medium')
        .length;
    final low = app.openTasks
        .where((task) => task.priority.name == 'low')
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Insights',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Learning-ready analytics from local task + nudge events.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _StatCard(
                  title: 'Completion',
                  value: '${(app.completionRate * 100).toStringAsFixed(0)}%',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(title: 'Streak', value: '${app.streakDays}d'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _PriorityMixCard(high: high, medium: medium, low: low),
          const SizedBox(height: 16),
          Text(
            'Recent reminder events',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: app.notificationEvents.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.15,
                        ),
                      ),
                    ),
                    child: const Text(
                      'No notification events yet. Enable nudges in onboarding/profile and create tasks.',
                    ),
                  )
                : ListView.separated(
                    itemCount: app.notificationEvents.length.clamp(0, 18),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final event = app.notificationEvents[index];
                      final subtitle = event.scheduledFor == null
                          ? DateFormat('MMM d, h:mm a').format(event.createdAt)
                          : 'for ${DateFormat('MMM d, h:mm a').format(event.scheduledFor!)}';

                      return ListTile(
                        tileColor: theme.colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        title: Text(event.kind.replaceAll('_', ' ')),
                        subtitle: Text(subtitle),
                        trailing: const Icon(Icons.chevron_right_rounded),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityMixCard extends StatelessWidget {
  const _PriorityMixCard({
    required this.high,
    required this.medium,
    required this.low,
  });

  final int high;
  final int medium;
  final int low;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Priority mix',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _MixRow(label: 'High', value: high),
          _MixRow(label: 'Medium', value: medium),
          _MixRow(label: 'Low', value: low),
        ],
      ),
    );
  }
}

class _MixRow extends StatelessWidget {
  const _MixRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Text(label),
          const Spacer(),
          Text(
            value.toString(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
