import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozzie/core/flags/ui_overhaul_flags.dart';
import 'package:ozzie/core/theme_v2/ozzie_theme.dart';
import 'package:ozzie/main.dart';

UiOverhaulFlags _flags({required bool themeV2}) {
  return UiOverhaulFlags(
    themeV2: themeV2,
    childHomeV2: false,
    mapV2: false,
    journeyV2: false,
    ayahV2: false,
    reciteV2: false,
    rewardV2: false,
    progressV2: false,
    authV2: false,
    parentV2: false,
  );
}

void main() {
  test('resolveAppThemeConfig keeps V1 mode when theme flag is off', () {
    final config = resolveAppThemeConfig(_flags(themeV2: false));
    expect(config.themeMode, ThemeMode.system);
    expect(config.theme.extension<OzzieTokensTheme>(), isNull);
  });

  test('resolveAppThemeConfig forces V2 light mode when theme flag is on', () {
    final config = resolveAppThemeConfig(_flags(themeV2: true));
    expect(config.themeMode, ThemeMode.light);
    expect(config.theme.extension<OzzieTokensTheme>(), isNotNull);
    expect(config.darkTheme.extension<OzzieTokensTheme>(), isNotNull);
  });
}
