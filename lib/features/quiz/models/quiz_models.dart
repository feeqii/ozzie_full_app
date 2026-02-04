import '../../rewards/models/reward_event.dart';

enum QuizType {
  mini1,
  mini2,
  finalExam,
}

enum QuizQuestionType {
  recitePrompt,
  completeVerse,
  wordOrdering,
  comprehension,
}

class QuizQuestionOption {
  const QuizQuestionOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.type,
    required this.title,
    required this.prompt,
    this.context,
    this.options = const [],
    this.correctOptionId,
    this.hasAudio = false,
  });

  final String id;
  final QuizQuestionType type;
  final String title;
  final String prompt;
  final String? context;
  final List<QuizQuestionOption> options;
  final String? correctOptionId;
  final bool hasAudio;

  bool get hasOptions => options.isNotEmpty;
}

class QuizAnswerItem {
  const QuizAnswerItem({
    required this.questionId,
    required this.selectedOptionId,
    required this.isCorrect,
  });

  final String questionId;
  final String? selectedOptionId;
  final bool isCorrect;

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'selected_option_id': selectedOptionId,
      'correct': isCorrect,
    };
  }
}

class SurahProgress {
  const SurahProgress({
    required this.childId,
    required this.surahId,
    required this.stage,
    required this.unlockedAyahMax,
  });

  final String childId;
  final int surahId;
  final String stage;
  final int unlockedAyahMax;

  factory SurahProgress.fromJson(Map<String, dynamic> json) {
    return SurahProgress(
      childId: json['child_id'] as String,
      surahId: json['surah_id'] as int,
      stage: json['stage'] as String? ?? 'LEARN_1_2',
      unlockedAyahMax: json['unlocked_ayah_max'] as int? ?? 1,
    );
  }
}

class QuizState {
  const QuizState({
    required this.childId,
    required this.surahId,
    required this.quizType,
    required this.questions,
    this.currentIndex = 0,
    this.selections = const {},
    this.showFeedback = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.score,
    this.passed,
    this.nextStage,
    this.rewardEvent,
  });

  final String childId;
  final int surahId;
  final QuizType quizType;
  final List<QuizQuestion> questions;
  final int currentIndex;
  final Map<String, String> selections;
  final bool showFeedback;
  final bool isSubmitting;
  final String? errorMessage;
  final int? score;
  final bool? passed;
  final String? nextStage;
  final RewardEvent? rewardEvent;

  QuizState copyWith({
    int? currentIndex,
    Map<String, String>? selections,
    bool? showFeedback,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    int? score,
    bool? passed,
    String? nextStage,
    RewardEvent? rewardEvent,
    bool clearReward = false,
  }) {
    return QuizState(
      childId: childId,
      surahId: surahId,
      quizType: quizType,
      questions: questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selections: selections ?? this.selections,
      showFeedback: showFeedback ?? this.showFeedback,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      score: score ?? this.score,
      passed: passed ?? this.passed,
      nextStage: nextStage ?? this.nextStage,
      rewardEvent: clearReward ? null : rewardEvent ?? this.rewardEvent,
    );
  }
}

extension QuizTypeX on QuizType {
  String get apiValue {
    switch (this) {
      case QuizType.mini1:
        return 'mini_1';
      case QuizType.mini2:
        return 'mini_2';
      case QuizType.finalExam:
        return 'final';
    }
  }

  String get label {
    switch (this) {
      case QuizType.mini1:
        return 'Mini Quiz 1';
      case QuizType.mini2:
        return 'Mini Quiz 2';
      case QuizType.finalExam:
        return 'Final Exam';
    }
  }
}

QuizType? quizTypeFromGate(String? gate) {
  switch (gate) {
    case 'MINI_QUIZ_1':
      return QuizType.mini1;
    case 'MINI_QUIZ_2':
      return QuizType.mini2;
    case 'FINAL_EXAM':
      return QuizType.finalExam;
    default:
      return null;
  }
}

QuizType? quizTypeFromRoute(String? raw) {
  switch (raw) {
    case 'mini_1':
    case 'mini1':
    case 'mini-1':
      return QuizType.mini1;
    case 'mini_2':
    case 'mini2':
    case 'mini-2':
      return QuizType.mini2;
    case 'final':
    case 'final_exam':
    case 'final-exam':
      return QuizType.finalExam;
    default:
      return null;
  }
}
