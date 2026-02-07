import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/progress/providers/practice_session_providers.dart';

final practiceSessionLifecycleProvider = Provider<PracticeSessionLifecycleObserver>((ref) {
  final observer = PracticeSessionLifecycleObserver(ref);
  WidgetsBinding.instance.addObserver(observer);
  ref.onDispose(() => WidgetsBinding.instance.removeObserver(observer));
  return observer;
});

class PracticeSessionLifecycleObserver extends WidgetsBindingObserver {
  PracticeSessionLifecycleObserver(this._ref);

  final Ref _ref;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = _ref.read(practiceSessionControllerProvider.notifier);

    switch (state) {
      case AppLifecycleState.resumed:
        notifier.onAppResumed();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        notifier.onAppBackgrounded();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // No-op: boundary widgets handle normal route transitions.
        break;
    }
  }
}

