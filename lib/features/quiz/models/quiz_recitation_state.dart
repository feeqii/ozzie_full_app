import 'quiz_models.dart';

enum QuizRecitationStage {
  idle,
  recording,
  review,
  submitting,
  success,
  fail,
  lockedOut,
}

class QuizRecitationState {
  const QuizRecitationState({
    required this.childId,
    required this.surahId,
    required this.quizType,
    this.stage = QuizRecitationStage.idle,
    this.localPath,
    this.durationLabel = '0:00',
    this.isBusy = false,
    this.errorMessage,
    this.showMicSettingsPrompt = false,
    this.score,
    this.passed,
    this.attemptsLeftToday,
    this.lockedUntil,
    this.transcript,
  });

  final String childId;
  final int surahId;
  final QuizType quizType;
  final QuizRecitationStage stage;
  final String? localPath;
  final String durationLabel;
  final bool isBusy;
  final String? errorMessage;
  final bool showMicSettingsPrompt;
  final int? score;
  final bool? passed;
  final int? attemptsLeftToday;
  final DateTime? lockedUntil;
  final String? transcript;

  QuizRecitationState copyWith({
    QuizRecitationStage? stage,
    String? localPath,
    String? durationLabel,
    bool? isBusy,
    String? errorMessage,
    bool clearError = false,
    bool? showMicSettingsPrompt,
    int? score,
    bool? passed,
    int? attemptsLeftToday,
    bool clearAttemptsLeftToday = false,
    DateTime? lockedUntil,
    bool clearLockedUntil = false,
    String? transcript,
    bool clearTranscript = false,
  }) {
    return QuizRecitationState(
      childId: childId,
      surahId: surahId,
      quizType: quizType,
      stage: stage ?? this.stage,
      localPath: localPath ?? this.localPath,
      durationLabel: durationLabel ?? this.durationLabel,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      showMicSettingsPrompt:
          showMicSettingsPrompt ?? this.showMicSettingsPrompt,
      score: score ?? this.score,
      passed: passed ?? this.passed,
      attemptsLeftToday: clearAttemptsLeftToday
          ? null
          : attemptsLeftToday ?? this.attemptsLeftToday,
      lockedUntil: clearLockedUntil ? null : lockedUntil ?? this.lockedUntil,
      transcript: clearTranscript ? null : transcript ?? this.transcript,
    );
  }

  String resultSummary() {
    if (stage == QuizRecitationStage.lockedOut) {
      return 'Try again tomorrow.';
    }
    if (passed == true && score != null) {
      return 'Passed (${score}%)';
    }
    if (stage == QuizRecitationStage.fail && score != null) {
      return 'Try again (${score}%)';
    }
    return 'Record and submit to continue.';
  }
}
