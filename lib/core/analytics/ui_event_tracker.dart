import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UiEventNames {
  const UiEventNames._();

  static const String homeView = 'home_view';
  static const String missionCtaTap = 'mission_cta_tap';
  static const String mapNodeTap = 'map_node_tap';
  static const String journeyStepComplete = 'journey_step_complete';
  static const String reciteSubmit = 'recite_submit';
  static const String rewardSeen = 'reward_seen';
  static const String sessionEnd = 'session_end';
}

abstract class UiEventTracker {
  void trackScreenView(
    String screen, {
    Map<String, Object?> attributes = const {},
  });

  void trackTap(String action, {Map<String, Object?> attributes = const {}});

  void trackFlowStep(
    String flow,
    String step, {
    Map<String, Object?> attributes = const {},
  });

  void trackCompletion(
    String flow, {
    Map<String, Object?> attributes = const {},
  });

  void trackDropoff(
    String flow,
    String reason, {
    Map<String, Object?> attributes = const {},
  });
}

class DebugUiEventTracker implements UiEventTracker {
  const DebugUiEventTracker();

  void _log(String event, Map<String, Object?> payload) {
    final body = payload.isEmpty ? '' : ' ${jsonEncode(payload)}';
    debugPrint('[UI_EVENT] $event$body');
  }

  @override
  void trackScreenView(
    String screen, {
    Map<String, Object?> attributes = const {},
  }) {
    _log('screen_view:$screen', attributes);
  }

  @override
  void trackTap(String action, {Map<String, Object?> attributes = const {}}) {
    _log('tap:$action', attributes);
  }

  @override
  void trackFlowStep(
    String flow,
    String step, {
    Map<String, Object?> attributes = const {},
  }) {
    _log('flow_step:$flow/$step', attributes);
  }

  @override
  void trackCompletion(
    String flow, {
    Map<String, Object?> attributes = const {},
  }) {
    _log('flow_complete:$flow', attributes);
  }

  @override
  void trackDropoff(
    String flow,
    String reason, {
    Map<String, Object?> attributes = const {},
  }) {
    _log('flow_dropoff:$flow/$reason', attributes);
  }
}

final uiEventTrackerProvider = Provider<UiEventTracker>((ref) {
  return const DebugUiEventTracker();
});
