import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ozzie/features/child/providers/child_providers.dart';
import 'package:ozzie/features/progress/models/child_progress_summary.dart';
import 'package:ozzie/features/progress/providers/progress_providers.dart';
import 'package:ozzie/features/progress/screens/child_recite_time_screen.dart';

void main() {
  testWidgets('ChildReciteTimeScreen renders non-empty recent sessions without layout exceptions', (tester) async {
    final startedAt = DateTime(2026, 2, 1, 12);
    final summary = SessionSummary(
      totalMinutes: 17,
      sessionCount: 2,
      lastSessionAt: startedAt.add(const Duration(minutes: 10)),
      entries: [
        SessionEntry(
          startedAt: startedAt,
          endedAt: startedAt.add(const Duration(minutes: 10)),
          counted: true,
        ),
        SessionEntry(
          startedAt: startedAt.subtract(const Duration(days: 1)),
          endedAt: startedAt.subtract(const Duration(days: 1)).add(const Duration(minutes: 6)),
          counted: true,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedChildProvider.overrideWithValue(null),
          childSessionSummaryProvider.overrideWith((ref, childId) async => summary),
        ],
        child: const MaterialApp(
          home: ChildReciteTimeScreen(childId: 'child1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Recent sessions'), findsOneWidget);
    expect(find.text('10 min'), findsOneWidget);
  });

  testWidgets('ChildReciteTimeScreen shows empty message when there are no recent sessions', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedChildProvider.overrideWithValue(null),
          childSessionSummaryProvider.overrideWith((ref, childId) async => SessionSummary.empty()),
        ],
        child: const MaterialApp(
          home: ChildReciteTimeScreen(childId: 'child1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('No sessions logged yet.'), findsOneWidget);
  });
}

