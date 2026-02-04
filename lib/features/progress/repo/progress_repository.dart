import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/child_progress_summary.dart';

class ProgressRepository {
  ProgressRepository(this._client);

  final SupabaseClient _client;

  Future<ChildStreak> fetchStreak(String childId) async {
    final response = await _client
        .from('streaks')
        .select('current_streak, best_streak, last_practice_date')
        .eq('child_id', childId)
        .maybeSingle();

    if (response == null) {
      return ChildStreak.empty();
    }

    return ChildStreak.fromJson(response);
  }

  Future<SessionSummary> fetchSessionSummary(String childId, {DateTime? since}) async {
    final start = since ?? DateTime.now().subtract(const Duration(days: 7));
    final response = await _client
        .from('sessions')
        .select('started_at, ended_at, counted')
        .eq('child_id', childId)
        .gte('started_at', start.toIso8601String())
        .order('started_at', ascending: false);

    final rows = (response as List).cast<Map<String, dynamic>>();
    final entries = rows.map(SessionEntry.fromJson).toList();
    final countedEntries = entries.where((entry) => entry.counted && entry.duration != null).toList();

    final totalSeconds = countedEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.duration!.inSeconds,
    );

    final totalMinutes = (totalSeconds / 60).round();
    final lastSessionAt = countedEntries.isNotEmpty
        ? (countedEntries.first.endedAt ?? countedEntries.first.startedAt)
        : null;

    return SessionSummary(
      totalMinutes: totalMinutes,
      sessionCount: countedEntries.length,
      lastSessionAt: lastSessionAt,
      entries: entries,
    );
  }

  Future<ScoreSummary> fetchScoreSummary(String childId, {DateTime? since}) async {
    final start = since ?? DateTime.now().subtract(const Duration(days: 7));
    final response = await _client
        .from('recitation_attempts')
        .select('score, created_at')
        .eq('child_id', childId)
        .gte('created_at', start.toIso8601String())
        .order('created_at', ascending: false)
        .limit(50);

    final rows = (response as List).cast<Map<String, dynamic>>();
    final entries = rows.map(ScoreEntry.fromJson).toList();
    if (entries.isEmpty) {
      return ScoreSummary.empty();
    }

    final totalScore = entries.fold<int>(0, (sum, entry) => sum + entry.score);
    final averageScore = (totalScore / entries.length).round();

    return ScoreSummary(
      averageScore: averageScore,
      latestScore: entries.first.score,
      attemptCount: entries.length,
      entries: entries,
    );
  }

  Future<ChildProgressSummary> fetchChildSummary(String childId) async {
    final streak = await fetchStreak(childId);
    final sessions = await fetchSessionSummary(childId);
    final score = await fetchScoreSummary(childId);

    return ChildProgressSummary(
      streak: streak,
      sessions: sessions,
      score: score,
    );
  }
}
