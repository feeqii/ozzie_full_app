class ChildStreak {
  const ChildStreak({
    required this.currentStreak,
    required this.bestStreak,
    this.lastPracticeDate,
  });

  final int currentStreak;
  final int bestStreak;
  final DateTime? lastPracticeDate;

  factory ChildStreak.empty() => const ChildStreak(currentStreak: 0, bestStreak: 0);

  factory ChildStreak.fromJson(Map<String, dynamic> json) {
    return ChildStreak(
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      bestStreak: (json['best_streak'] as num?)?.toInt() ?? 0,
      lastPracticeDate: _parseDate(json['last_practice_date']),
    );
  }
}

class SessionEntry {
  const SessionEntry({
    required this.startedAt,
    required this.endedAt,
    required this.counted,
  });

  final DateTime startedAt;
  final DateTime? endedAt;
  final bool counted;

  factory SessionEntry.fromJson(Map<String, dynamic> json) {
    return SessionEntry(
      startedAt: _parseDate(json['started_at']) ?? DateTime.now(),
      endedAt: _parseDate(json['ended_at']),
      counted: json['counted'] == true,
    );
  }

  Duration? get duration => endedAt?.difference(startedAt);
}

class SessionSummary {
  const SessionSummary({
    required this.totalMinutes,
    required this.sessionCount,
    required this.lastSessionAt,
    required this.entries,
  });

  final int totalMinutes;
  final int sessionCount;
  final DateTime? lastSessionAt;
  final List<SessionEntry> entries;

  factory SessionSummary.empty() => const SessionSummary(
        totalMinutes: 0,
        sessionCount: 0,
        lastSessionAt: null,
        entries: [],
      );
}

class ScoreEntry {
  const ScoreEntry({
    required this.score,
    required this.createdAt,
    required this.source,
    this.surahId,
    this.ayahId,
    this.quizType,
  });

  final int score;
  final DateTime createdAt;
  final String source;
  final int? surahId;
  final int? ayahId;
  final String? quizType;

  factory ScoreEntry.fromRecitationJson(Map<String, dynamic> json) {
    return ScoreEntry(
      score: (json['score'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      source: 'recitation',
      surahId: (json['surah_id'] as num?)?.toInt(),
      ayahId: (json['ayah_id'] as num?)?.toInt(),
    );
  }

  factory ScoreEntry.fromQuizJson(Map<String, dynamic> json) {
    final quizType = json['quiz_type'] as String?;
    return ScoreEntry(
      score: (json['score'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      source: quizType == null || quizType.isEmpty ? 'quiz' : 'quiz:$quizType',
      surahId: (json['surah_id'] as num?)?.toInt(),
      quizType: quizType,
    );
  }
}

class ScoreSummary {
  const ScoreSummary({
    required this.averageScore,
    required this.latestScore,
    required this.attemptCount,
    required this.entries,
  });

  final int averageScore;
  final int latestScore;
  final int attemptCount;
  final List<ScoreEntry> entries;

  factory ScoreSummary.empty() => const ScoreSummary(
        averageScore: 0,
        latestScore: 0,
        attemptCount: 0,
        entries: [],
      );
}

class ChildProgressSummary {
  const ChildProgressSummary({
    required this.streak,
    required this.sessions,
    required this.score,
  });

  final ChildStreak streak;
  final SessionSummary sessions;
  final ScoreSummary score;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  return DateTime.tryParse(value.toString());
}
