import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase_client_provider.dart';
import '../../child/providers/child_providers.dart';
import '../models/child_progress_summary.dart';
import '../repo/progress_repository.dart';

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ProgressRepository(client);
});

final childStreakProvider = FutureProvider.family<ChildStreak, String>((ref, childId) async {
  final repo = ref.watch(progressRepositoryProvider);
  return repo.fetchStreak(childId);
});

final childSessionSummaryProvider = FutureProvider.family<SessionSummary, String>((ref, childId) async {
  final repo = ref.watch(progressRepositoryProvider);
  return repo.fetchSessionSummary(childId);
});

final childScoreSummaryProvider = FutureProvider.family<ScoreSummary, String>((ref, childId) async {
  final repo = ref.watch(progressRepositoryProvider);
  return repo.fetchScoreSummary(childId);
});

final childProgressSummaryProvider = FutureProvider.family<ChildProgressSummary, String>((ref, childId) async {
  final repo = ref.watch(progressRepositoryProvider);
  return repo.fetchChildSummary(childId);
});

final selectedChildProgressSummaryProvider = FutureProvider<ChildProgressSummary?>((ref) async {
  final child = ref.watch(selectedChildProvider);
  if (child == null) {
    return null;
  }
  final repo = ref.watch(progressRepositoryProvider);
  return repo.fetchChildSummary(child.id);
});
