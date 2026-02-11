import 'package:flutter/foundation.dart';

@immutable
class UiOverhaulFlags {
  const UiOverhaulFlags({
    required this.themeV2,
    required this.childHomeV2,
    required this.mapV2,
    required this.journeyV2,
    required this.ayahV2,
    required this.reciteV2,
    required this.rewardV2,
    required this.progressV2,
    required this.authV2,
    required this.parentV2,
  });

  final bool themeV2;
  final bool childHomeV2;
  final bool mapV2;
  final bool journeyV2;
  final bool ayahV2;
  final bool reciteV2;
  final bool rewardV2;
  final bool progressV2;
  final bool authV2;
  final bool parentV2;

  static bool _readBoolFromMap(
    Map<String, String> env,
    String key,
    bool fallback,
  ) {
    const truthy = <String>{'true', '1', 'yes', 'on'};
    const falsy = <String>{'false', '0', 'no', 'off'};

    final raw = (env[key] ?? '').trim();
    if (raw.isEmpty) {
      return fallback;
    }

    final normalized = raw.toLowerCase();
    if (truthy.contains(normalized)) {
      return true;
    }
    if (falsy.contains(normalized)) {
      return false;
    }
    return fallback;
  }

  factory UiOverhaulFlags.fromMap(Map<String, String> env) {
    return UiOverhaulFlags(
      themeV2: _readBoolFromMap(env, 'UI_THEME_V2', false),
      childHomeV2: _readBoolFromMap(env, 'UI_CHILD_HOME_V2', false),
      mapV2: _readBoolFromMap(env, 'UI_MAP_V2', false),
      journeyV2: _readBoolFromMap(env, 'UI_JOURNEY_V2', false),
      ayahV2: _readBoolFromMap(env, 'UI_AYAH_V2', false),
      reciteV2: _readBoolFromMap(env, 'UI_RECITE_V2', false),
      rewardV2: _readBoolFromMap(env, 'UI_REWARD_V2', false),
      progressV2: _readBoolFromMap(env, 'UI_PROGRESS_V2', false),
      authV2: _readBoolFromMap(env, 'UI_AUTH_V2', false),
      parentV2: _readBoolFromMap(env, 'UI_PARENT_V2', false),
    );
  }

  factory UiOverhaulFlags.fromEnvironment() {
    return UiOverhaulFlags.fromMap({
      'UI_THEME_V2': const String.fromEnvironment(
        'UI_THEME_V2',
        defaultValue: '',
      ),
      'UI_CHILD_HOME_V2': const String.fromEnvironment(
        'UI_CHILD_HOME_V2',
        defaultValue: '',
      ),
      'UI_MAP_V2': const String.fromEnvironment('UI_MAP_V2', defaultValue: ''),
      'UI_JOURNEY_V2': const String.fromEnvironment(
        'UI_JOURNEY_V2',
        defaultValue: '',
      ),
      'UI_AYAH_V2': const String.fromEnvironment(
        'UI_AYAH_V2',
        defaultValue: '',
      ),
      'UI_RECITE_V2': const String.fromEnvironment(
        'UI_RECITE_V2',
        defaultValue: '',
      ),
      'UI_REWARD_V2': const String.fromEnvironment(
        'UI_REWARD_V2',
        defaultValue: '',
      ),
      'UI_PROGRESS_V2': const String.fromEnvironment(
        'UI_PROGRESS_V2',
        defaultValue: '',
      ),
      'UI_AUTH_V2': const String.fromEnvironment(
        'UI_AUTH_V2',
        defaultValue: '',
      ),
      'UI_PARENT_V2': const String.fromEnvironment(
        'UI_PARENT_V2',
        defaultValue: '',
      ),
    });
  }
}
