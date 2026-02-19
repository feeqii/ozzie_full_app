import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownyourday/state/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _apiController;

  @override
  void initState() {
    super.initState();
    final app = ref.read(appControllerProvider);
    _apiController = TextEditingController(text: app.settings.openAiApiKey);
  }

  @override
  void dispose() {
    _apiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
        children: <Widget>[
          Text(
            'MVP Controls',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Local-first setup for sprint one. Swap to secure backend key handling in production.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _apiController,
            decoration: const InputDecoration(
              labelText: 'OpenAI API key',
              hintText: 'sk-...',
            ),
            onChanged: (value) {
              ref.read(appControllerProvider).updateOpenAiApiKey(value);
            },
          ),
          const SizedBox(height: 8),
          Text(
            'MVP note: key is stored locally in shared preferences (insecure by design for this sprint).',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          SwitchListTile.adaptive(
            value: app.settings.notificationsEnabled,
            onChanged: (value) {
              ref.read(appControllerProvider).setNotificationsEnabled(value);
            },
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable gentle nudges'),
            subtitle: const Text('Primary reminder + one follow-up only'),
          ),
          const SizedBox(height: 8),
          Text(
            'Theme',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const <ButtonSegment<ThemeMode>>[
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                label: Text('System'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                label: Text('Light'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                label: Text('Dark'),
              ),
            ],
            selected: <ThemeMode>{app.settings.themeMode},
            onSelectionChanged: (value) {
              ref.read(appControllerProvider).updateThemeMode(value.first);
            },
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Architecture status',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('• Local storage persistence active'),
                const Text('• AI parsing via gpt-5-mini active'),
                const Text('• Smart notification scheduler active'),
                const Text('• Audio capture intentionally deferred (wired)'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
