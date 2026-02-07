enum JourneyLevelType {
  surahIntro,
  verseLesson,
  checkpoint,
  finalExam,
}

JourneyLevelType levelTypeFromApi(String? raw) {
  switch (raw) {
    case 'SURAH_INTRO':
      return JourneyLevelType.surahIntro;
    case 'VERSE_LESSON':
      return JourneyLevelType.verseLesson;
    case 'CHECKPOINT':
      return JourneyLevelType.checkpoint;
    case 'FINAL_EXAM':
      return JourneyLevelType.finalExam;
    default:
      return JourneyLevelType.verseLesson;
  }
}

enum JourneyLevelStatus {
  locked,
  unlocked,
  inProgress,
  completed,
}

JourneyLevelStatus levelStatusFromApi(String? raw) {
  switch (raw) {
    case 'UNLOCKED':
      return JourneyLevelStatus.unlocked;
    case 'IN_PROGRESS':
      return JourneyLevelStatus.inProgress;
    case 'COMPLETED':
      return JourneyLevelStatus.completed;
    case 'LOCKED':
    default:
      return JourneyLevelStatus.locked;
  }
}

class JourneyLevel {
  const JourneyLevel({
    required this.id,
    required this.surahId,
    required this.type,
    required this.orderIndex,
    this.ayahId,
    this.checkpointIndex,
    this.quizType,
  });

  final String id;
  final int surahId;
  final JourneyLevelType type;
  final int orderIndex;
  final int? ayahId;
  final int? checkpointIndex;
  final String? quizType;

  factory JourneyLevel.fromJson(Map<String, dynamic> json) {
    final config = json['config'] as Map<String, dynamic>?;
    return JourneyLevel(
      id: json['id'] as String? ?? '',
      surahId: (json['surah_id'] as num?)?.toInt() ?? 0,
      type: levelTypeFromApi(json['type'] as String?),
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      ayahId: (json['ayah_id'] as num?)?.toInt(),
      checkpointIndex: (json['checkpoint_index'] as num?)?.toInt(),
      quizType: config?['quiz_type'] as String?,
    );
  }
}

class JourneyProgress {
  const JourneyProgress({
    required this.levelId,
    required this.status,
    this.lockedUntil,
    this.attemptsToday,
    this.passCountTotal,
    this.lastScore,
    this.completedAt,
  });

  final String levelId;
  final JourneyLevelStatus status;
  final DateTime? lockedUntil;
  final int? attemptsToday;
  final int? passCountTotal;
  final int? lastScore;
  final DateTime? completedAt;

  factory JourneyProgress.fromJson(Map<String, dynamic> json) {
    return JourneyProgress(
      levelId: json['level_id'] as String? ?? '',
      status: levelStatusFromApi(json['status'] as String?),
      lockedUntil: DateTime.tryParse(json['locked_until'] as String? ?? ''),
      attemptsToday: (json['attempts_today'] as num?)?.toInt(),
      passCountTotal: (json['pass_count_total'] as num?)?.toInt(),
      lastScore: (json['last_score'] as num?)?.toInt(),
      completedAt: DateTime.tryParse(json['completed_at'] as String? ?? ''),
    );
  }
}

class JourneyStep {
  const JourneyStep({
    required this.level,
    required this.progress,
  });

  final JourneyLevel level;
  final JourneyProgress progress;

  bool get isLocked => progress.status == JourneyLevelStatus.locked;
  bool get isCompleted => progress.status == JourneyLevelStatus.completed;
  bool get isUnlocked => progress.status == JourneyLevelStatus.unlocked || progress.status == JourneyLevelStatus.inProgress;
}

