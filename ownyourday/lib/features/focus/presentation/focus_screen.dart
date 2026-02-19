import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownyourday/core/theme/app_colors.dart';
import 'package:ownyourday/features/tasks/domain/task.dart';
import 'package:ownyourday/state/providers.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  Timer? _timer;
  Duration _remaining = const Duration(minutes: 25);
  Task? _activeTask;
  bool _running = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start(Task task) {
    setState(() {
      _activeTask = task;
      _remaining = Duration(minutes: task.estimatedMinutes.clamp(10, 60));
      _running = true;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= const Duration(seconds: 1)) {
        timer.cancel();
        setState(() {
          _remaining = Duration.zero;
          _running = false;
        });
        return;
      }
      setState(() {
        _remaining -= const Duration(seconds: 1);
      });
    });
  }

  void _togglePause() {
    if (_timer == null || _activeTask == null) {
      return;
    }

    if (_running) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remaining <= const Duration(seconds: 1)) {
          timer.cancel();
          setState(() {
            _remaining = Duration.zero;
            _running = false;
          });
          return;
        }
        setState(() {
          _remaining -= const Duration(seconds: 1);
        });
      });
    }

    setState(() {
      _running = !_running;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final tasks = app.highPriorityOpenTasks;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Focus',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick one priority and stay in flow.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFF9C85FF), Color(0xFFFFB18B)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _activeTask?.title ?? 'No active focus session',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _clock(_remaining),
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    FilledButton.tonal(
                      onPressed: _activeTask == null ? null : _togglePause,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_running ? 'Pause' : 'Resume'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.tonal(
                      onPressed: () {
                        _timer?.cancel();
                        setState(() {
                          _activeTask = null;
                          _remaining = const Duration(minutes: 25);
                          _running = false;
                        });
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'High-priority queue',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: tasks.isEmpty
                ? _EmptyFocusCard(theme: theme)
                : ListView.separated(
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return ListTile(
                        tileColor: AppColors.lavenderSoft.withValues(
                          alpha: theme.brightness == Brightness.dark
                              ? 0.2
                              : 0.6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Text(task.title),
                        subtitle: Text(
                          '${task.estimatedMinutes}m focus window',
                        ),
                        trailing: IconButton(
                          onPressed: () => _start(task),
                          icon: const Icon(Icons.play_arrow_rounded),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _clock(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _EmptyFocusCard extends StatelessWidget {
  const _EmptyFocusCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Text(
        'No high-priority tasks yet. Add one in Capture or Today to start a guided focus session.',
        style: theme.textTheme.bodyLarge,
      ),
    );
  }
}
