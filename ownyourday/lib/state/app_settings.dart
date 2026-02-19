import 'dart:convert';

import 'package:flutter/material.dart';

class AppSettings {
  AppSettings({
    this.hasCompletedOnboarding = false,
    this.hasMockLoggedIn = false,
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = false,
    this.openAiApiKey = '',
    this.weekStartsOnMonday = false,
    this.preferredQuickAddDuration = 30,
  });

  final bool hasCompletedOnboarding;
  final bool hasMockLoggedIn;
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final String openAiApiKey;
  final bool weekStartsOnMonday;
  final int preferredQuickAddDuration;

  AppSettings copyWith({
    bool? hasCompletedOnboarding,
    bool? hasMockLoggedIn,
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    String? openAiApiKey,
    bool? weekStartsOnMonday,
    int? preferredQuickAddDuration,
  }) {
    return AppSettings(
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      hasMockLoggedIn: hasMockLoggedIn ?? this.hasMockLoggedIn,
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      openAiApiKey: openAiApiKey ?? this.openAiApiKey,
      weekStartsOnMonday: weekStartsOnMonday ?? this.weekStartsOnMonday,
      preferredQuickAddDuration:
          preferredQuickAddDuration ?? this.preferredQuickAddDuration,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'hasMockLoggedIn': hasMockLoggedIn,
      'themeMode': themeMode.name,
      'notificationsEnabled': notificationsEnabled,
      'openAiApiKey': openAiApiKey,
      'weekStartsOnMonday': weekStartsOnMonday,
      'preferredQuickAddDuration': preferredQuickAddDuration,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      hasCompletedOnboarding: map['hasCompletedOnboarding'] as bool? ?? false,
      hasMockLoggedIn: map['hasMockLoggedIn'] as bool? ?? false,
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == map['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? false,
      openAiApiKey: map['openAiApiKey'] as String? ?? '',
      weekStartsOnMonday: map['weekStartsOnMonday'] as bool? ?? false,
      preferredQuickAddDuration: map['preferredQuickAddDuration'] as int? ?? 30,
    );
  }

  String toJson() => json.encode(toMap());

  factory AppSettings.fromJson(String source) =>
      AppSettings.fromMap(json.decode(source) as Map<String, dynamic>);
}
