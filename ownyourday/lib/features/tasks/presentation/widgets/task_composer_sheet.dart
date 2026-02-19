import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ownyourday/features/tasks/domain/task.dart';
import 'package:ownyourday/features/tasks/domain/task_priority.dart';

class TaskComposerSheet extends StatefulWidget {
  const TaskComposerSheet({
    super.key,
    required this.onSubmit,
    required this.defaultDuration,
  });

  final Future<void> Function(TaskDraft draft) onSubmit;
  final int defaultDuration;

  @override
  State<TaskComposerSheet> createState() => _TaskComposerSheetState();
}

class _TaskComposerSheetState extends State<TaskComposerSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  TaskPriority? _priority;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  int _importance = 3;
  late int _durationMinutes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _durationMinutes = widget.defaultDuration;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 3650)),
      initialDate: _dueDate ?? now,
    );

    if (selected != null) {
      setState(() {
        _dueDate = selected;
      });
    }
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );

    if (selected != null) {
      setState(() {
        _dueTime = selected;
      });
    }
  }

  DateTime? _resolvedDueDate() {
    if (_dueDate == null) {
      return null;
    }

    final time = _dueTime ?? const TimeOfDay(hour: 17, minute: 0);
    return DateTime(
      _dueDate!.year,
      _dueDate!.month,
      _dueDate!.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty || _saving) {
      return;
    }

    setState(() => _saving = true);

    final draft = TaskDraft(
      title: _titleController.text.trim(),
      notes: _notesController.text.trim(),
      dueAt: _resolvedDueDate(),
      priority: _priority,
      importance: _importance,
      estimatedMinutes: _durationMinutes,
    );

    await widget.onSubmit(draft);

    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final due = _resolvedDueDate();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Create task',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Task title',
                  hintText: 'Finish investor update',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Optional context for future-you',
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Priority',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ChoiceChip(
                    label: const Text('Auto'),
                    selected: _priority == null,
                    onSelected: (_) => setState(() => _priority = null),
                  ),
                  ...TaskPriority.values.map(
                    (priority) => ChoiceChip(
                      label: Text(priority.label),
                      selected: _priority == priority,
                      onSelected: (_) => setState(() => _priority = priority),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(
                        _dueDate == null
                            ? 'Add due date'
                            : DateFormat('EEE, MMM d').format(_dueDate!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.schedule_outlined),
                      label: Text(
                        _dueTime == null
                            ? 'Add time'
                            : _dueTime!.format(context),
                      ),
                    ),
                  ),
                ],
              ),
              if (due != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  'Due ${DateFormat('EEEE, MMM d • h:mm a').format(due)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 14),
              Text(
                'Importance: $_importance / 5',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Slider(
                value: _importance.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                onChanged: (value) =>
                    setState(() => _importance = value.round()),
              ),
              Text(
                'Estimated duration: ${_durationMinutes}m',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Slider(
                value: _durationMinutes.toDouble(),
                min: 5,
                max: 180,
                divisions: 35,
                onChanged: (value) =>
                    setState(() => _durationMinutes = value.round()),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
