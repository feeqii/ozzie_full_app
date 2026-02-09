import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../child/models/child_profile.dart';
import '../../child/providers/child_providers.dart';
import '../providers/practice_session_controller.dart';
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
  ProviderSubscription<ChildProfile?>? _childSub;
  late final PracticeSessionController _controller;

  @override
  void initState() {
    super.initState();

    _controller = ref.read(practiceSessionControllerProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeEnter(ref.read(selectedChildProvider)?.id);
    });

    _childSub = ref.listenManual<ChildProfile?>(
      selectedChildProvider,
      (previous, next) {
        if (_entered) {
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _maybeEnter(next?.id);
        });
      },
    );
  }

  void _maybeEnter(String? childId) {
    if (_entered) {
      return;
    }
    if (childId == null || childId.isEmpty) {
      return;
    }
    _entered = true;
    _controller.enterPractice(childId: childId);
  }

  @override
  void dispose() {
    _childSub?.close();
    if (_entered) {
      _controller.leavePractice();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
