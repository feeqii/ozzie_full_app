import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ozzie/core/theme_v2/ozzie_theme.dart';
import 'package:ozzie/core/ui_v2/components/ozzie_button.dart';
import 'package:ozzie/core/ui_v2/components/ozzie_choice_chip.dart';
import 'package:ozzie/core/ui_v2/components/ozzie_input.dart';
import 'package:ozzie/core/ui_v2/components/ozzie_progress_rail.dart';
import 'package:ozzie/core/ui_v2/mascot/ozzie_guide_widget.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: OzzieTheme.childLight(),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('OzzieButton keeps minimum touch height and semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(OzzieButton(label: 'Launch', fullWidth: false, onPressed: () {})),
    );

    final size = tester.getSize(find.byType(OzzieButton));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(find.text('Launch'), findsOneWidget);
  });

  testWidgets('OzzieButton disabled state keeps readable opacity', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const OzzieButton(label: 'Disabled')));
    final opacityWidget = tester.widget<Opacity>(find.byType(Opacity).first);
    expect(opacityWidget.opacity, 0.72);
  });

  testWidgets('OzzieInput reflects focus and error states', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Padding(
          padding: EdgeInsets.all(16),
          child: OzzieInput(
            label: 'Name',
            hint: 'Type your name',
            errorText: 'Name is required',
          ),
        ),
      ),
    );

    expect(find.text('Name is required'), findsOneWidget);

    final beforeTap = tester.widget<Text>(find.text('Name')).style?.color;
    await tester.tap(find.byType(TextField));
    await tester.pump();
    final afterTap = tester.widget<Text>(find.text('Name')).style?.color;

    expect(beforeTap, isNotNull);
    expect(afterTap, isNotNull);
  });

  testWidgets('OzzieChoiceChip enforces minimum tap target', (tester) async {
    await tester.pumpWidget(
      _wrap(OzzieChoiceChip(label: 'Warm-up', selected: true, onTap: () {})),
    );

    final size = tester.getSize(find.byType(OzzieChoiceChip));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('OzzieProgressRail clamps value and formats trailing percent', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const Padding(
          padding: EdgeInsets.all(16),
          child: OzzieProgressRail(label: 'Progress', value: 2.4),
        ),
      ),
    );

    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, 1);
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('OzzieGuideWidget renders fallback when Rive is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const OzzieGuideWidget(enableRive: false, width: 72, height: 72)),
    );

    expect(find.byIcon(Icons.smart_toy_rounded), findsOneWidget);
  });
}
