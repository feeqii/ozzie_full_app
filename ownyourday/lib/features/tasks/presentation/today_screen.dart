import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ownyourday/core/theme/app_colors.dart';
import 'package:ownyourday/core/utils/date_formatters.dart';
import 'package:ownyourday/features/tasks/domain/task.dart';
import 'package:ownyourday/features/tasks/domain/task_source.dart';
import 'package:ownyourday/features/tasks/presentation/widgets/quick_add_bar.dart';
import 'package:ownyourday/features/tasks/presentation/widgets/task_card.dart';
import 'package:ownyourday/features/tasks/presentation/widgets/task_composer_sheet.dart';
import 'package:ownyourday/features/tasks/presentation/widgets/week_strip.dart';
import 'package:ownyourday/state/providers.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  Future<void> _openComposer() async {
    final app = ref.read(appControllerProvider);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      showDragHandle: true,
      builder: (_) => TaskComposerSheet(
        defaultDuration: app.settings.preferredQuickAddDuration,
        onSubmit: (draft) => app.addTaskFromDraft(draft),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final theme = Theme.of(context);
    final planned = app.plannedTasks;
    final anytime = app.todayAnytimeTasks;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
                      child: Row(
                        children: <Widget>[
                          _ChipButton(
                            icon: Icons.access_time_rounded,
                            text: 'Today',
                            onTap: () => app.setSelectedDate(DateTime.now()),
                          ),
                          const SizedBox(width: 8),
                          _IconChip(
                            icon: Icons.calendar_today_rounded,
                            onTap: () {},
                          ),
                          const Spacer(),
                          _IconChip(
                            icon: Icons.person_outline_rounded,
                            onTap: widget.onOpenSettings,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const SizedBox(height: 6),
                          Text(
                            DateFormatters.dayName.format(app.selectedDate),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat.yMMMMd().format(app.selectedDate),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.48,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          WeekStrip(
                            selectedDate: app.selectedDate,
                            weekStartsOnMonday: app.settings.weekStartsOnMonday,
                            onSelect: app.setSelectedDate,
                          ),
                          const SizedBox(height: 14),
                          SegmentedButton<bool>(
                            showSelectedIcon: false,
                            segments: const <ButtonSegment<bool>>[
                              ButtonSegment<bool>(
                                value: true,
                                icon: Icon(Icons.timeline_rounded),
                                label: Text('Timeline'),
                              ),
                              ButtonSegment<bool>(
                                value: false,
                                icon: Icon(Icons.list_alt_rounded),
                                label: Text('List'),
                              ),
                            ],
                            selected: <bool>{app.showTimelineView},
                            onSelectionChanged: (selected) {
                              app.setTodayView(selected.first);
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        'Get started',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 192,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                        scrollDirection: Axis.horizontal,
                        children: const <Widget>[
                          _GuideCard(
                            title: 'Add smart widgets',
                            description:
                                'Stay focused with a glance at upcoming tasks.',
                            minutes: '2 min',
                            icon: Icons.widgets_outlined,
                            tint: Color(0xFFDCD4FF),
                          ),
                          SizedBox(width: 12),
                          _GuideCard(
                            title: 'Morning check-in',
                            description:
                                'Set a calm planning window before your day ramps up.',
                            minutes: '3 min',
                            icon: Icons.wb_sunny_outlined,
                            tint: Color(0xFFFFD8C5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 22, 18, 6),
                      child: _SectionTitle(
                        title: 'To do anytime',
                        count: anytime.length,
                      ),
                    ),
                  ),
                  if (anytime.isEmpty)
                    const SliverToBoxAdapter(
                      child: _EmptyListHint(
                        text:
                            'Nothing in anytime yet. Quick-add below to start.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
                      sliver: SliverList.builder(
                        itemCount: anytime.length,
                        itemBuilder: (context, index) {
                          final task = anytime[index];
                          return TaskCard(
                            task: task,
                            isCompact: !app.showTimelineView,
                            onToggle: () => app.toggleTaskStatus(task.id),
                            onDelete: () => app.removeTask(task.id),
                          );
                        },
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
                      child: _SectionTitle(
                        title: 'Planned',
                        count: planned.length,
                      ),
                    ),
                  ),
                  if (planned.isEmpty)
                    const SliverToBoxAdapter(
                      child: _EmptyListHint(
                        text:
                            'No planned items yet. Add due date/time in full composer.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 140),
                      sliver: SliverList.builder(
                        itemCount: planned.length,
                        itemBuilder: (context, index) {
                          final task = planned[index];
                          return TaskCard(
                            task: task,
                            isCompact: !app.showTimelineView,
                            onToggle: () => app.toggleTaskStatus(task.id),
                            onDelete: () => app.removeTask(task.id),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            QuickAddBar(
              onOpenComposer: _openComposer,
              onSubmit: (text) {
                return app.addTaskFromDraft(
                  TaskDraft(
                    title: text,
                    source: TaskSource.manual,
                    estimatedMinutes: app.settings.preferredQuickAddDuration,
                    importance: 3,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openComposer,
        backgroundColor: AppColors.lavender,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
          ),
        ),
        child: Icon(icon, size: 22),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.title,
    required this.description,
    required this.minutes,
    required this.icon,
    required this.tint,
  });

  final String title;
  final String description;
  final String minutes;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 286,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: tint.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.17 : 0.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 34),
          const Spacer(),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(description, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Text(
                minutes.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              CircleAvatar(
                backgroundColor: AppColors.lavender.withValues(alpha: 0.85),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          '$count',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EmptyListHint extends StatelessWidget {
  const _EmptyListHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.16),
          ),
        ),
        child: Text(text),
      ),
    );
  }
}
