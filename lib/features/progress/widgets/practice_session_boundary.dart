import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../child/providers/child_providers.dart';
import '../providers/practice_session_providers.dart';

class PracticeSessionBoundary extends ConsumerStatefulWidget {
  const PracticeSessionBoundary({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<PracticeSessionBoundary> createState() => _PracticeSessionBoundaryState();
}

class _PracticeSessionBoundaryState extends ConsumerState<PracticeSessionBoundary> {
  bool _entered = false;

  @override
  void initState() {
    super.initState();

    _maybeEnter(ref.read(selectedChildProvider)?.id);

    ref.listen(selectedChildProvider, (previous, next) {
      if (_entered) {
        return;
      }
      _maybeEnter(next?.id);
    });
  }

  void _maybeEnter(String? childId) {
    if (_entered) {
      return;
    }
    if (childId == null || childId.isEmpty) {
      return;
    }
    _entered = true;
    ref.read(practiceSessionControllerProvider.notifier).enterPractice(childId: childId);
  }

  @override
  void dispose() {
    if (_entered) {
      ref.read(practiceSessionControllerProvider.notifier).leavePractice();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

