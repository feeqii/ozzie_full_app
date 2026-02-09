import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repo/practice_session_repository.dart';
import 'progress_refresh.dart';

class PracticeSessionState {
  static const Object _unset = Object();

  const PracticeSessionState({
    this.practiceDepth = 0,
    this.activeChildId,
    this.activeSessionId,
  });

  final int practiceDepth;
  final String? activeChildId;
  final String? activeSessionId;

  PracticeSessionState copyWith({
    int? practiceDepth,
    String? activeChildId,
    Object? activeSessionId = _unset,
  }) {
    return PracticeSessionState(
      practiceDepth: practiceDepth ?? this.practiceDepth,
      activeChildId: activeChildId ?? this.activeChildId,
      activeSessionId: identical(activeSessionId, _unset)
          ? this.activeSessionId
          : activeSessionId as String?,
    );
  }
}

class PracticeSessionController extends StateNotifier<PracticeSessionState> {
  PracticeSessionController(this._ref, this._repo) : super(const PracticeSessionState());

  final Ref _ref;
  final PracticeSessionRepository _repo;

  static const String _logTag = '[PracticeSession]';
  bool _starting = false;
  bool _ending = false;

  Future<void> enterPractice({required String childId}) async {
    if (childId.isEmpty) {
      return;
    }

    final nextDepth = state.practiceDepth + 1;
    final activeChildId = state.activeChildId ?? childId;
    state = state.copyWith(
      practiceDepth: nextDepth,
      activeChildId: activeChildId,
      activeSessionId: state.activeSessionId,
    );

    // Best-effort start: if we don't have an active session yet, start one.
    if (state.activeSessionId != null || _starting) {
      return;
    }

    _starting = true;
    try {
      final sessionId = await _repo.startSession(childId: activeChildId);
      if (!mounted) return;
      state = state.copyWith(
        practiceDepth: state.practiceDepth,
        activeChildId: activeChildId,
        activeSessionId: sessionId,
      );
      debugPrint('$_logTag started session child=$activeChildId session=$sessionId depth=${state.practiceDepth}');
    } catch (error) {
      debugPrint('$_logTag start failed child=$activeChildId error=$error');
    } finally {
      _starting = false;
    }
  }

  Future<void> leavePractice() async {
    if (state.practiceDepth <= 0) {
      return;
    }

    final nextDepth = state.practiceDepth - 1;
    state = state.copyWith(
      practiceDepth: nextDepth,
      activeChildId: state.activeChildId,
      activeSessionId: state.activeSessionId,
    );

    if (nextDepth > 0) {
      return;
    }

    final childId = state.activeChildId;
    final sessionId = state.activeSessionId;
    if (childId == null || childId.isEmpty || sessionId == null || sessionId.isEmpty) {
      state = const PracticeSessionState(practiceDepth: 0);
      return;
    }

    await _endSession(childId: childId, sessionId: sessionId, clearChild: true);
  }

  Future<void> onAppBackgrounded() async {
    final childId = state.activeChildId;
    final sessionId = state.activeSessionId;
    if (state.practiceDepth <= 0 || childId == null || sessionId == null) {
      return;
    }

    await _endSession(childId: childId, sessionId: sessionId, clearChild: false);
  }

  Future<void> onAppResumed() async {
    final childId = state.activeChildId;
    if (state.practiceDepth <= 0 || childId == null || childId.isEmpty) {
      return;
    }

    if (state.activeSessionId != null || _starting) {
      return;
    }

    _starting = true;
    try {
      final sessionId = await _repo.startSession(childId: childId);
      if (!mounted) return;
      state = state.copyWith(
        practiceDepth: state.practiceDepth,
        activeChildId: childId,
        activeSessionId: sessionId,
      );
      debugPrint('$_logTag resumed -> started session child=$childId session=$sessionId depth=${state.practiceDepth}');
    } catch (error) {
      debugPrint('$_logTag resume start failed child=$childId error=$error');
    } finally {
      _starting = false;
    }
  }

  Future<void> _endSession({
    required String childId,
    required String sessionId,
    required bool clearChild,
  }) async {
    if (_ending) {
      return;
    }
    _ending = true;
    try {
      await _repo.endSession(childId: childId, sessionId: sessionId);
      debugPrint('$_logTag ended session child=$childId session=$sessionId');
    } catch (error) {
      debugPrint('$_logTag end failed child=$childId session=$sessionId error=$error');
    } finally {
      _ending = false;
    }

    if (!mounted) return;

    // Clear session id so a new one can start on resume / next enter.
    state = PracticeSessionState(
      practiceDepth: state.practiceDepth,
      activeChildId: clearChild ? null : childId,
      activeSessionId: null,
    );

    refreshChildProgress(_ref.invalidate, childId);
  }
}
