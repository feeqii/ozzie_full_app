import 'package:flutter_test/flutter_test.dart';
import 'package:ozzie/core/flags/ui_overhaul_flags.dart';

void main() {
  test('defaults to V1-safe values when env map is empty', () {
    final flags = UiOverhaulFlags.fromMap(const {});

    expect(flags.themeV2, isFalse);
    expect(flags.childHomeV2, isFalse);
    expect(flags.mapV2, isFalse);
    expect(flags.journeyV2, isFalse);
    expect(flags.ayahV2, isFalse);
    expect(flags.reciteV2, isFalse);
    expect(flags.rewardV2, isFalse);
    expect(flags.progressV2, isFalse);
    expect(flags.authV2, isFalse);
    expect(flags.parentV2, isFalse);
  });

  test('parses truthy and falsy values across all supported values', () {
    final trueValues = ['true', 'TRUE', '1', 'yes', 'on'];
    final falseValues = ['false', 'FALSE', '0', 'no', 'off'];

    for (final value in trueValues) {
      final flags = UiOverhaulFlags.fromMap({'UI_THEME_V2': value});
      expect(flags.themeV2, isTrue, reason: 'Expected "$value" to parse true');
    }

    for (final value in falseValues) {
      final flags = UiOverhaulFlags.fromMap({'UI_THEME_V2': value});
      expect(
        flags.themeV2,
        isFalse,
        reason: 'Expected "$value" to parse false',
      );
    }
  });

  test('ignores unknown value and falls back to default', () {
    final flags = UiOverhaulFlags.fromMap({'UI_AUTH_V2': 'not-a-bool'});
    expect(flags.authV2, isFalse);
  });
}
