import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ownyourday/core/services/openai_task_parser.dart';
import 'package:ownyourday/features/tasks/domain/task.dart';
import 'package:ownyourday/features/tasks/domain/task_priority.dart';
import 'package:ownyourday/features/tasks/domain/task_source.dart';
import 'package:ownyourday/state/providers.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final TextEditingController _controller = TextEditingController();
  AiTaskSuggestion? _suggestion;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _parse() async {
    final app = ref.read(appControllerProvider);
    final suggestion = await app.parseCaptureText(_controller.text);
    if (!mounted) {
      return;
    }
    setState(() => _suggestion = suggestion);
  }

  Future<void> _createTask() async {
    final app = ref.read(appControllerProvider);
    final text = _controller.text.trim();
    if (text.isEmpty || _saving) {
      return;
    }

    setState(() => _saving = true);

    if (_suggestion != null) {
      final draft = TaskDraft(
        title: _suggestion!.title,
        notes: _suggestion!.notes,
        dueAt: _suggestion!.dueAt,
        remindAt: _suggestion!.remindAt,
        priority: _suggestion!.priority,
        importance: _suggestion!.importance,
        estimatedMinutes: _suggestion!.estimatedMinutes,
        source: TaskSource.ai,
      );
      await app.addTaskFromDraft(draft);
    } else {
      await app.addTaskFromDraft(TaskDraft(title: text));
    }

    if (mounted) {
      _controller.clear();
      setState(() {
        _saving = false;
        _suggestion = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task captured.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? const <Color>[Color(0xFF07080D), Color(0xFF0D101B)]
              : const <Color>[Color(0xFFF8F7F4), Color(0xFFEDE8FF)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    'Capture',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Audio capture (coming soon)',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Audio capture wiring is ready; implementation comes next sprint.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.mic_none_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Type messy thoughts. AI will convert them into structured tasks.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF121521) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextField(
                      controller: _controller,
                      minLines: 4,
                      maxLines: 7,
                      textCapitalization: TextCapitalization.sentences,
                      style: theme.textTheme.headlineSmall,
                      decoration: const InputDecoration(
                        hintText: "What's next?",
                        border: InputBorder.none,
                        filled: false,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const <Widget>[
                        _ComposerPill(icon: Icons.schedule, text: 'Anytime'),
                        _ComposerPill(
                          icon: Icons.repeat_rounded,
                          text: 'No repeat',
                        ),
                        _ComposerPill(
                          icon: Icons.timelapse_rounded,
                          text: '30m',
                        ),
                        _ComposerPill(
                          icon: Icons.graphic_eq,
                          text: 'Audio (wired)',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: app.isAiBusy ? null : _parse,
                            icon: app.isAiBusy
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.auto_awesome_outlined),
                            label: const Text('AI parse'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: _saving ? null : _createTask,
                          style: FilledButton.styleFrom(
                            shape: const CircleBorder(),
                            minimumSize: const Size(50, 50),
                            padding: EdgeInsets.zero,
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.arrow_upward_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (app.lastError != null) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  app.lastError!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.redAccent,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (_suggestion != null)
                _SuggestionPreview(suggestion: _suggestion!)
              else
                Expanded(child: _CaptureGuideCard(dark: dark)),
              if (_suggestion != null) const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionPreview extends StatelessWidget {
  const _SuggestionPreview({required this.suggestion});

  final AiTaskSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: theme.colorScheme.surface,
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'AI suggestion',
              style: theme.textTheme.labelLarge?.copyWith(
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              suggestion.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (suggestion.notes.isNotEmpty) ...<Widget>[
              Text(suggestion.notes, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _ComposerPill(
                  icon: Icons.flag_rounded,
                  text: suggestion.priority.label,
                ),
                _ComposerPill(
                  icon: Icons.timelapse,
                  text: '${suggestion.estimatedMinutes}m',
                ),
                _ComposerPill(
                  icon: Icons.star_outline,
                  text: 'Importance ${suggestion.importance}/5',
                ),
                if (suggestion.dueAt != null)
                  _ComposerPill(
                    icon: Icons.calendar_month,
                    text: DateFormat('MMM d, h:mm a').format(suggestion.dueAt!),
                  ),
                if (suggestion.remindAt != null)
                  _ComposerPill(
                    icon: Icons.notifications_active,
                    text:
                        'Nudge ${DateFormat('h:mm a').format(suggestion.remindAt!)}',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureGuideCard extends StatelessWidget {
  const _CaptureGuideCard({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Capture tips',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Use natural language like “Send proposal by tomorrow 2 PM, high priority, takes 45m.”',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            'Audio capture status',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Input channel and UI affordance are wired. Speech-to-text implementation is intentionally deferred in this MVP.',
            style: theme.textTheme.bodyMedium,
          ),
          const Spacer(),
          Row(
            children: <Widget>[
              Icon(dark ? Icons.nights_stay : Icons.sunny),
              const SizedBox(width: 8),
              Text(
                dark ? 'Dark mode active' : 'Light mode active',
                style: theme.textTheme.labelLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComposerPill extends StatelessWidget {
  const _ComposerPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
