import '../../rewards/models/reward_event.dart';

enum RecitationStage {
  idle,
  recording,
  review,
  uploading,
  feedbackSuccess,
  feedbackFail,
  interventionRequired,
  lockedOut,
  gateToQuiz,
}

class RecitationState {
  const RecitationState({
    required this.childId,
    required this.surahId,
    required this.ayahId,
    this.stage = RecitationStage.idle,
    this.localPath,
    this.durationLabel = '0:00',
    this.isBusy = false,
    this.errorMessage,
    this.showMicSettingsPrompt = false,
    this.score,
    this.passesRemaining,
    this.attemptsLeftToday,
    this.mustReplayLearnStep = false,
    this.showDetailedFeedback = false,
    this.shouldBlurVerse = false,
    this.nextGate,
    this.lockedUntil,
    this.lastResultMessage,
    this.rewardEvent,
  });

  final String childId;
  final int surahId;
  final int ayahId;
  final RecitationStage stage;
  final String? localPath;
  final String durationLabel;
  final bool isBusy;
  final String? errorMessage;
  final bool showMicSettingsPrompt;
  final int? score;
  final int? passesRemaining;
  final int? attemptsLeftToday;
  final bool mustReplayLearnStep;
  final bool showDetailedFeedback;
  final bool shouldBlurVerse;
  final String? nextGate;
  final DateTime? lockedUntil;
  final String? lastResultMessage;
  final RewardEvent? rewardEvent;

  RecitationState copyWith({
    RecitationStage? stage,
    String? localPath,
    String? durationLabel,
    bool? isBusy,
    String? errorMessage,
    bool clearError = false,
    bool? showMicSettingsPrompt,
    int? score,
    int? passesRemaining,
    int? attemptsLeftToday,
    bool? mustReplayLearnStep,
    bool? showDetailedFeedback,
    bool? shouldBlurVerse,
    String? nextGate,
    DateTime? lockedUntil,
    String? lastResultMessage,
    RewardEvent? rewardEvent,
    bool clearReward = false,
  }) {
    return RecitationState(
      childId: childId,
      surahId: surahId,
      ayahId: ayahId,
      stage: stage ?? this.stage,
      localPath: localPath ?? this.localPath,
      durationLabel: durationLabel ?? this.durationLabel,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      showMicSettingsPrompt: showMicSettingsPrompt ?? this.showMicSettingsPrompt,
      score: score ?? this.score,
      passesRemaining: passesRemaining ?? this.passesRemaining,
      attemptsLeftToday: attemptsLeftToday ?? this.attemptsLeftToday,
      mustReplayLearnStep: mustReplayLearnStep ?? this.mustReplayLearnStep,
      showDetailedFeedback: showDetailedFeedback ?? this.showDetailedFeedback,
      shouldBlurVerse: shouldBlurVerse ?? this.shouldBlurVerse,
      nextGate: nextGate ?? this.nextGate,
      lockedUntil: lockedUntil ?? this.lockedUntil,
      lastResultMessage: lastResultMessage ?? this.lastResultMessage,
      rewardEvent: clearReward ? null : rewardEvent ?? this.rewardEvent,
    );
  }

  String resultSummary() {
    if (lastResultMessage != null) {
      return lastResultMessage!;
    }
    if (passesRemaining != null) {
      final remaining = passesRemaining!;
      return remaining == 0 ? 'Ayah mastered!' : '$remaining passes to go.';
    }
    return 'Keep practicing!';
  }

  bool get isLocked => stage == RecitationStage.lockedOut;
  bool get isIntervention => stage == RecitationStage.interventionRequired;
  bool get isSuccess => stage == RecitationStage.feedbackSuccess;
}
