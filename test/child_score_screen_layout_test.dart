import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ozzie/features/child/providers/child_providers.dart';
import 'package:ozzie/features/progress/models/child_progress_summary.dart';
import 'package:ozzie/features/progress/providers/progress_providers.dart';
import 'package:ozzie/features/progress/screens/child_score_screen.dart';

void main() {
  testWidgets('ChildScoreScreen renders non-empty recent attempts without layout exceptions', (tester) async {
    final summary = ScoreSummary(
      averageScore: 75,
      latestScore: 91,
      attemptCount: 2,
      entries: [
        ScoreEntry(score: 90, createdAt: DateTime(2026, 2, 1), source: 'recitation'),
        ScoreEntry(score: 84, createdAt: DateTime(2026, 1, 28), source: 'recitation'),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedChildProvider.overrideWithValue(null),
          childScoreSummaryProvider.overrideWith((ref, childId) async => summary),
        ],
        child: const MaterialApp(
          home: ChildScoreScreen(childId: 'child1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Recent attempts'), findsOneWidget);
    expect(find.text('90%'), findsOneWidget);
  });

  testWidgets('ChildScoreScreen shows empty message when there are no recent attempts', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedChildProvider.overrideWithValue(null),
          childScoreSummaryProvider.overrideWith((ref, childId) async => ScoreSummary.empty()),
        ],
        child: const MaterialApp(
          home: ChildScoreScreen(childId: 'child1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('No attempts logged yet.'), findsOneWidget);
  });
}
