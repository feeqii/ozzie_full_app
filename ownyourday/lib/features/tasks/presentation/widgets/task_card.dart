import 'package:flutter/material.dart';
import 'package:ownyourday/core/theme/app_colors.dart';
import 'package:ownyourday/core/utils/date_formatters.dart';
import 'package:ownyourday/features/tasks/domain/task.dart';
import 'package:ownyourday/features/tasks/domain/task_priority.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    this.isCompact = false,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _priorityColors(task.priority, theme.brightness);

    return Dismissible(
      key: ValueKey<String>('task-${task.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.red.shade400,
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(isCompact ? 16 : 18),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 6,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    task.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      decoration: task.isDone
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: isCompact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onToggle,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task.isDone
                          ? theme.colorScheme.onSurface
                          : Colors.transparent,
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                        width: 1.6,
                      ),
                    ),
                    child: task.isDone
                        ? Icon(
                            Icons.check,
                            size: 20,
                            color: theme.colorScheme.surface,
                          )
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                _MetaPill(
                  text: task.priority.shortLabel,
                  icon: Icons.flag_rounded,
                ),
                _MetaPill(
                  text: '${task.estimatedMinutes}m',
                  icon: Icons.timelapse,
                ),
                if (task.dueAt != null)
                  _MetaPill(
                    text:
                        '${DateFormatters.formatRelativeDate(task.dueAt!)} ${DateFormatters.time.format(task.dueAt!)}',
                    icon: Icons.calendar_month_outlined,
                  ),
                if (task.remindAt != null)
                  _MetaPill(
                    text: 'Nudge ${DateFormatters.time.format(task.remindAt!)}',
                    icon: Icons.notifications_active_outlined,
                  ),
              ],
            ),
            if (task.notes.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                task.notes,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  _PriorityColors _priorityColors(
    TaskPriority priority,
    Brightness brightness,
  ) {
    final dark = brightness == Brightness.dark;
    return switch (priority) {
      TaskPriority.high => _PriorityColors(
        surface: dark
            ? AppColors.highPriority.withValues(alpha: 0.28)
            : AppColors.highPriority.withValues(alpha: 0.18),
        accent: AppColors.highPriority,
      ),
      TaskPriority.medium => _PriorityColors(
        surface: dark
            ? AppColors.mediumPriority.withValues(alpha: 0.28)
            : AppColors.mediumPriority.withValues(alpha: 0.18),
        accent: AppColors.mediumPriority,
      ),
      TaskPriority.low => _PriorityColors(
        surface: dark
            ? AppColors.lowPriority.withValues(alpha: 0.28)
            : AppColors.lowPriority.withValues(alpha: 0.18),
        accent: AppColors.lowPriority,
      ),
    };
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: theme.colorScheme.surface.withValues(alpha: 0.65),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityColors {
  const _PriorityColors({required this.surface, required this.accent});

  final Color surface;
  final Color accent;
}
