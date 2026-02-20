import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../child/providers/child_providers.dart';
import '../../rewards/models/reward_event.dart';
import '../models/quiz_models.dart';
import '../../../core/ui/quiz_option_card.dart';
import '../repo/quiz_repository.dart';
import 'quiz_providers.dart';

final quizControllerProvider =
    StateNotifierProvider.family<QuizController, QuizState, QuizParams>((
      ref,
      params,
    ) {
      final repo = ref.watch(quizRepositoryProvider);
      final childId =
          params.childId ?? ref.watch(selectedChildProvider)?.id ?? '';
      return QuizController(repo, params.copyWith(childId: childId));
    });

class QuizParams {
  const QuizParams({
    required this.surahId,
    required this.quizType,
    this.childId,
  });

  final String? childId;
  final int surahId;
  final QuizType quizType;

  QuizParams copyWith({String? childId, int? surahId, QuizType? quizType}) {
    return QuizParams(
      childId: childId ?? this.childId,
      surahId: surahId ?? this.surahId,
      quizType: quizType ?? this.quizType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is QuizParams &&
        other.childId == childId &&
        other.surahId == surahId &&
        other.quizType == quizType;
  }

  @override
  int get hashCode => Object.hash(childId, surahId, quizType);
}

class QuizController extends StateNotifier<QuizState> {
  QuizController(this._repo, QuizParams params)
    : super(
        QuizState(
          childId: params.childId ?? '',
          surahId: params.surahId,
          quizType: params.quizType,
          questions: _buildQuestions(params.surahId, params.quizType),
        ),
      );

  final QuizRepository _repo;
  final Random _random = Random();

  void selectOption(String questionId, String optionId) {
    state = state.copyWith(
      selections: {...state.selections, questionId: optionId},
      clearError: true,
    );
  }

  void nextQuestion() {
    if (state.currentIndex + 1 >= state.questions.length) {
      return;
    }
    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      showFeedback: false,
      clearWrongFeedbackStyle: true,
    );
  }

  void retryCurrentQuestion({bool clearSelection = false}) {
    if (state.questions.isEmpty) {
      return;
    }
    final question = state.questions[state.currentIndex];
    final nextSelections = Map<String, String>.from(state.selections);
    if (clearSelection) {
      nextSelections.remove(question.id);
    }
    state = state.copyWith(
      selections: nextSelections,
      showFeedback: false,
      clearWrongFeedbackStyle: true,
      clearError: true,
    );
  }

  void resetQuiz() {
    state = state.copyWith(
      currentIndex: 0,
      selections: {},
      showFeedback: false,
      isSubmitting: false,
      score: null,
      passed: null,
      clearAttemptsLeftToday: true,
      clearLockedUntil: true,
      nextStage: null,
      clearReward: true,
      clearWrongFeedbackStyle: true,
      clearError: true,
    );
  }

  bool get isLastQuestion => state.currentIndex >= state.questions.length - 1;

  bool isSelected(String questionId, String optionId) {
    return state.selections[questionId] == optionId;
  }

  bool isCorrectSelection(QuizQuestion question) {
    final selected = state.selections[question.id];
    if (selected == null) {
      return false;
    }
    if (question.correctOptionId == null) {
      return false;
    }
    return selected == question.correctOptionId;
  }

  QuizOptionState optionState(
    QuizQuestion question,
    QuizQuestionOption option,
  ) {
    final selected = state.selections[question.id];
    if (!state.showFeedback) {
      if (selected == null) {
        return QuizOptionState.normal;
      }
      return selected == option.id
          ? QuizOptionState.selected
          : QuizOptionState.disabled;
    }

    if (question.correctOptionId == null) {
      return QuizOptionState.normal;
    }

    if (option.id == question.correctOptionId) {
      return QuizOptionState.correct;
    }

    if (selected == option.id) {
      return QuizOptionState.wrong;
    }

    return QuizOptionState.disabled;
  }

  bool canSubmitCurrent() {
    final question = state.questions[state.currentIndex];
    if (!question.hasOptions) {
      return true;
    }
    return state.selections.containsKey(question.id);
  }

  Future<void> submitCurrentAnswer() async {
    final question = state.questions[state.currentIndex];
    if (question.hasOptions && !state.selections.containsKey(question.id)) {
      state = state.copyWith(errorMessage: 'Pick an answer to continue.');
      return;
    }
    final isCorrect = isCorrectSelection(question);
    final feedbackStyle = isCorrect
        ? null
        : (_random.nextBool()
              ? QuizWrongFeedbackStyle.detailed
              : QuizWrongFeedbackStyle.motivational);
    state = state.copyWith(
      showFeedback: true,
      wrongFeedbackStyle: feedbackStyle,
      clearWrongFeedbackStyle: feedbackStyle == null,
      clearError: true,
    );
  }

  Future<void> submitQuiz() async {
    if (state.childId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Select a child profile to continue.',
      );
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final answers = state.questions.map((question) {
        final selected = state.selections[question.id];
        final isCorrect =
            question.correctOptionId != null &&
            selected == question.correctOptionId;
        return QuizAnswerItem(
          questionId: question.id,
          selectedOptionId: selected,
          isCorrect: isCorrect,
        );
      }).toList();

      final payload = await _repo.submitQuiz(
        childId: state.childId,
        surahId: state.surahId,
        quizType: state.quizType,
        answers: answers,
      );

      final rewardEvent = _buildRewardEvent(payload);

      final lockedUntilRaw = payload['locked_until'];
      final lockedUntilParsed =
          lockedUntilRaw is String && lockedUntilRaw.isNotEmpty
          ? DateTime.tryParse(lockedUntilRaw)
          : null;
      final hasLockedUntilKey = payload.containsKey('locked_until');

      final attemptsLeftRaw = payload['attemptsLeftToday'];
      final attemptsLeftParsed = (attemptsLeftRaw as num?)?.toInt();
      final hasAttemptsLeftKey = payload.containsKey('attemptsLeftToday');

      state = state.copyWith(
        isSubmitting: false,
        score: (payload['score'] as num?)?.toInt(),
        passed: payload['passed'] == true,
        attemptsLeftToday: attemptsLeftParsed,
        clearAttemptsLeftToday:
            hasAttemptsLeftKey && attemptsLeftParsed == null,
        lockedUntil: lockedUntilParsed,
        clearLockedUntil: hasLockedUntilKey && lockedUntilParsed == null,
        nextStage: payload['nextStage'] as String?,
        rewardEvent: rewardEvent,
      );
    } on FunctionException catch (error) {
      final details = error.details;
      String? message;
      if (details is Map) {
        final code = details['code'];
        final errMsg = details['error'];
        if (code == 'RECITATION_REQUIRED') {
          message =
              'Recitation required. Record and submit your recitation to continue.';
        } else if (errMsg is String && errMsg.isNotEmpty) {
          message = errMsg;
        }
      }
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: message ?? error.toString(),
      );
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: error.toString(),
      );
    }
  }

  static List<QuizQuestion> _buildQuestions(int surahId, QuizType quizType) {
    // TODO(reading-comprehension-contract): move question generation to a backend
    // question bank once schema + APIs are finalized.
    if (surahId == 1 && quizType == QuizType.mini1) {
      return const [
        QuizQuestion(
          id: 's1m1q1',
          type: QuizQuestionType.recitePrompt,
          title: 'Memorization',
          prompt: 'Recite the two verses we learned so far in Al-Fatihah.',
          hasAudio: true,
        ),
        QuizQuestion(
          id: 's1m1q2',
          type: QuizQuestionType.readingComprehension,
          title: 'Answer the following question',
          prompt: 'What do we say in the opening of Al-Fatihah?',
          options: [
            QuizQuestionOption(
              id: 'a',
              label:
                  'In the name of Allah, the Most Gracious, the Most Merciful.',
            ),
            QuizQuestionOption(
              id: 'b',
              label: 'Guide us to the straight path.',
            ),
            QuizQuestionOption(
              id: 'c',
              label: 'Master of the Day of Judgment.',
            ),
            QuizQuestionOption(
              id: 'd',
              label: 'You alone we worship, and You alone we ask for help.',
            ),
          ],
          correctOptionId: 'a',
        ),
        QuizQuestion(
          id: 's1m1q3',
          type: QuizQuestionType.comprehension,
          title: 'Choose the meaning',
          prompt: 'Which line asks Allah for guidance?',
          context: 'Keep practicing comprehension while memorizing.',
          options: [
            QuizQuestionOption(
              id: 'a',
              label: 'Guide us to the straight path.',
            ),
            QuizQuestionOption(
              id: 'b',
              label: 'Master of the Day of Judgment.',
            ),
            QuizQuestionOption(
              id: 'c',
              label: 'In the name of Allah, the Most Merciful.',
            ),
            QuizQuestionOption(
              id: 'd',
              label: 'You alone we worship and ask for help.',
            ),
          ],
          correctOptionId: 'a',
        ),
      ];
    }

    if (surahId == 1 && quizType == QuizType.mini2) {
      return const [
        QuizQuestion(
          id: 's1m2q0',
          type: QuizQuestionType.recitePrompt,
          title: 'Memorization',
          prompt: 'Recite the four verses we learned so far in Al-Fatihah.',
          hasAudio: true,
        ),
        QuizQuestion(
          id: 's1m2q1',
          type: QuizQuestionType.completeVerse,
          title: 'Complete the verse',
          prompt: 'Yawma yaqūmu wal-malāʼikatu ṣaffan',
          context: 'Al-Fatihah — Verse 4',
          hasAudio: true,
          options: [
            QuizQuestionOption(
              id: 'a',
              label: 'ar-rūḥu',
              subtitle: 'الرُّوحُ',
              audioRef: 's1m2q1_a',
            ),
            QuizQuestionOption(
              id: 'b',
              label: 'Yawma yaqūmu',
              subtitle: 'يَوْمَ يَقُومُ',
              audioRef: 's1m2q1_b',
            ),
            QuizQuestionOption(
              id: 'c',
              label: 'Yawma yaqūmu',
              subtitle: 'يَوْمَ يَقُومُ',
              audioRef: 's1m2q1_c',
            ),
            QuizQuestionOption(
              id: 'd',
              label: 'Yawma yaqūmu',
              subtitle: 'يَوْمَ يَقُومُ',
              audioRef: 's1m2q1_d',
            ),
          ],
          correctOptionId: 'a',
        ),
        QuizQuestion(
          id: 's1m2q2',
          type: QuizQuestionType.wordOrdering,
          title: 'Word ordering',
          prompt: 'Arrange the words to complete the verse meaning.',
          context: 'You alone we worship, and You alone we ask for help.',
          options: [
            QuizQuestionOption(id: 'a', label: 'You alone we worship'),
            QuizQuestionOption(id: 'b', label: 'and You alone we ask for help'),
            QuizQuestionOption(id: 'c', label: 'Guide us to the straight path'),
            QuizQuestionOption(id: 'd', label: 'Master of the Day of Judgment'),
          ],
          correctOptionId: 'b',
        ),
        QuizQuestion(
          id: 's1m2q3',
          type: QuizQuestionType.readingComprehension,
          title: 'Answer the following question',
          prompt: 'Who will be judged on the Day of Judgment?',
          hasAudio: true,
          options: [
            QuizQuestionOption(
              id: 'a',
              label: 'All people will be judged for their deeds.',
              audioRef: 's1m2q3_a',
            ),
            QuizQuestionOption(
              id: 'b',
              label: 'Only the angels will be judged.',
              audioRef: 's1m2q3_b',
            ),
            QuizQuestionOption(
              id: 'c',
              label: 'Only the believers will be judged.',
              audioRef: 's1m2q3_c',
            ),
            QuizQuestionOption(
              id: 'd',
              label: 'The animals will be judged.',
              audioRef: 's1m2q3_d',
            ),
          ],
          correctOptionId: 'c',
        ),
      ];
    }

    if (surahId == 1 && quizType == QuizType.finalExam) {
      return const [
        QuizQuestion(
          id: 's1fq1',
          type: QuizQuestionType.recitePrompt,
          title: 'Final exam',
          prompt: 'Recite Surah Al-Fatihah from memory.',
          hasAudio: true,
        ),
        QuizQuestion(
          id: 's1fq2',
          type: QuizQuestionType.readingComprehension,
          title: 'Answer the following question',
          prompt: 'What do we ask Allah for in Al-Fatihah?',
          options: [
            QuizQuestionOption(
              id: 'a',
              label: 'Guidance to the straight path.',
            ),
            QuizQuestionOption(id: 'b', label: 'A long life and riches.'),
            QuizQuestionOption(
              id: 'c',
              label: 'Forgiveness for every mistake.',
            ),
            QuizQuestionOption(id: 'd', label: 'Strength to overcome fear.'),
          ],
          correctOptionId: 'a',
        ),
        QuizQuestion(
          id: 's1fq3',
          type: QuizQuestionType.completeVerse,
          title: 'Complete the verse',
          prompt: 'Iyyāka naʿbudu wa iyyāka ____',
          context: 'Final check before surah completion.',
          options: [
            QuizQuestionOption(
              id: 'a',
              label: 'nastaʿīn',
              subtitle: 'نَسْتَعِينُ',
            ),
            QuizQuestionOption(
              id: 'b',
              label: 'al-ʿālamīn',
              subtitle: 'الْعَالَمِينَ',
            ),
            QuizQuestionOption(
              id: 'c',
              label: 'ar-raḥīm',
              subtitle: 'الرَّحِيمِ',
            ),
            QuizQuestionOption(id: 'd', label: 'mālik', subtitle: 'مَالِكِ'),
          ],
          correctOptionId: 'a',
        ),
      ];
    }

    if (surahId == 112 && quizType == QuizType.mini1) {
      return const [
        QuizQuestion(
          id: 's112m1q1',
          type: QuizQuestionType.recitePrompt,
          title: 'Memorization',
          prompt: 'Recite the first two verses of Al-Ikhlas.',
          hasAudio: true,
        ),
        QuizQuestion(
          id: 's112m1q2',
          type: QuizQuestionType.readingComprehension,
          title: 'Answer the following question',
          prompt: 'What does Al-Ikhlas teach about Allah?',
          options: [
            QuizQuestionOption(id: 'a', label: 'Allah is One and Eternal.'),
            QuizQuestionOption(id: 'b', label: 'Allah needs helpers.'),
            QuizQuestionOption(id: 'c', label: 'Allah has a family.'),
            QuizQuestionOption(id: 'd', label: 'Allah changes with time.'),
          ],
          correctOptionId: 'a',
        ),
      ];
    }

    if (surahId == 112 && quizType == QuizType.mini2) {
      return const [
        QuizQuestion(
          id: 's112m2q0',
          type: QuizQuestionType.recitePrompt,
          title: 'Memorization',
          prompt: 'Recite Surah Al-Ikhlas from the beginning up to verse 4.',
          hasAudio: true,
        ),
        QuizQuestion(
          id: 's112m2q1',
          type: QuizQuestionType.completeVerse,
          title: 'Complete the verse',
          prompt: 'Lam yalid wa ____',
          context: 'Al-Ikhlas — Verse 3',
          hasAudio: true,
          options: [
            QuizQuestionOption(id: 'a', label: 'lam yulad'),
            QuizQuestionOption(id: 'b', label: 'lam yakun'),
            QuizQuestionOption(id: 'c', label: 'ahad'),
            QuizQuestionOption(id: 'd', label: 'as-samad'),
          ],
          correctOptionId: 'a',
        ),
        QuizQuestion(
          id: 's112m2q2',
          type: QuizQuestionType.wordOrdering,
          title: 'Word ordering',
          prompt: 'Pick the phrase that completes the verse meaning.',
          context: 'Nor is there to Him any equivalent.',
          options: [
            QuizQuestionOption(id: 'a', label: 'Nothing compares to Allah.'),
            QuizQuestionOption(id: 'b', label: 'Allah is the Eternal Refuge.'),
            QuizQuestionOption(id: 'c', label: 'Say, He is Allah, the One.'),
            QuizQuestionOption(
              id: 'd',
              label: 'He neither begets nor is born.',
            ),
          ],
          correctOptionId: 'a',
        ),
      ];
    }

    if (surahId == 112 && quizType == QuizType.finalExam) {
      return const [
        QuizQuestion(
          id: 's112fq1',
          type: QuizQuestionType.recitePrompt,
          title: 'Final exam',
          prompt: 'Recite Surah Al-Ikhlas from memory.',
          hasAudio: true,
        ),
        QuizQuestion(
          id: 's112fq2',
          type: QuizQuestionType.readingComprehension,
          title: 'Answer the following question',
          prompt: 'What does “As-Samad” mean?',
          options: [
            QuizQuestionOption(id: 'a', label: 'The Eternal Refuge.'),
            QuizQuestionOption(id: 'b', label: 'The Forgiving.'),
            QuizQuestionOption(id: 'c', label: 'The Provider.'),
            QuizQuestionOption(id: 'd', label: 'The Creator.'),
          ],
          correctOptionId: 'a',
        ),
      ];
    }

    return const [];
  }

  RewardEvent? _buildRewardEvent(Map<String, dynamic> payload) {
    final passed = payload['passed'] == true;
    if (!passed) {
      return null;
    }
    final nextStage = payload['nextStage'] as String?;
    if (nextStage == 'COMPLETED') {
      return RewardEvent(
        type: RewardType.trophy,
        title: 'Surah completed!',
        message: 'You passed the final exam. Amazing work!',
        score: (payload['score'] as num?)?.toInt(),
      );
    }
    return RewardEvent(
      type: RewardType.badge,
      title: 'Quiz passed!',
      message: 'New badge unlocked for this quiz.',
      score: (payload['score'] as num?)?.toInt(),
    );
  }

  void clearReward() {
    state = state.copyWith(clearReward: true);
  }
}
