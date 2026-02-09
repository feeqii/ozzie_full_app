import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'progress_providers.dart';

typedef ProviderInvalidator = void Function(ProviderOrFamily provider);

void refreshChildProgress(ProviderInvalidator invalidate, String childId) {
  invalidate(childProgressSummaryProvider(childId));
  invalidate(childStreakProvider(childId));
  invalidate(childScoreSummaryProvider(childId));
  invalidate(childSessionSummaryProvider(childId));
  // Keep the selected-child summary (if used) in sync too.
  invalidate(selectedChildProgressSummaryProvider);
}
