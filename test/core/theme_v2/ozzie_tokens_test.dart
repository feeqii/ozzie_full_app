import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozzie/core/theme_v2/ozzie_theme.dart';
import 'package:ozzie/core/theme_v2/ozzie_tokens.dart';

void main() {
  test('child and parent type tokens are distinct', () {
    expect(
      OzzieTokensV2.childLight.type.displayXL.fontFamily,
      isNot(OzzieTokensV2.parentLight.type.displayXL.fontFamily),
    );
  });

  test('text styles include fallback families for web resilience', () {
    final child = OzzieTokensV2.childLight.type;
    expect(child.body.fontFamilyFallback, isNotEmpty);
    expect(child.displayXL.fontFamilyFallback, isNotEmpty);
    expect(child.arabicBody.fontFamilyFallback, isNotEmpty);
  });

  test('child and parent themes remain light-only in Phase 0', () {
    expect(OzzieTheme.childLight().brightness, Brightness.light);
    expect(OzzieTheme.parentLight().brightness, Brightness.light);
  });

  test('theme color scheme maps semantic primary token', () {
    final theme = OzzieTheme.childLight();
    expect(theme.colorScheme.primary, OzzieTokensV2.childLight.colors.primary);
  });
}
