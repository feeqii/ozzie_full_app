import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'progress_providers.dart';

void refreshChildProgress(Ref ref, String childId) {
  ref.invalidate(childProgressSummaryProvider(childId));
  ref.invalidate(childStreakProvider(childId));
  ref.invalidate(childScoreSummaryProvider(childId));
  ref.invalidate(childSessionSummaryProvider(childId));
  // Keep the selected-child summary (if used) in sync too.
  ref.invalidate(selectedChildProgressSummaryProvider);
}

