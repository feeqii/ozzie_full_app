import 'package:flutter_test/flutter_test.dart';
import 'package:ozzie/core/ui/quiz_option_card.dart';
import 'package:ozzie/features/quiz/models/quiz_models.dart';
import 'package:ozzie/features/quiz/providers/quiz_controller.dart';
import 'package:ozzie/features/quiz/repo/quiz_repository.dart';

class _FakeQuizRepository implements QuizRepository {
  @override
  Future<SurahProgress?> fetchSurahProgress({
    required String childId,
    required int surahId,
  }) async {
    return null;
  }

  @override
  Future<Map<String, dynamic>> submitQuiz({
    required String childId,
    required int surahId,
    required QuizType quizType,
    required List<QuizAnswerItem> answers,
  }) async {
    return <String, dynamic>{'score': 100, 'passed': true};
  }
}

void main() {
  QuizController buildController({
    int surahId = 1,
    QuizType quizType = QuizType.mini2,
  }) {
    return QuizController(
      _FakeQuizRepository(),
      QuizParams(childId: 'child-1', surahId: surahId, quizType: quizType),
    );
  }

  test('mini1 comprehension question stays within first two ayahs', () {
    final controller = buildController(quizType: QuizType.mini1);
    final question = controller.state.questions.firstWhere(
      (item) => item.id == 's1m1q3',
    );

    expect(
      question.prompt,
      'Who is praised in “Alhamdu lillahi Rabbil ʿālamīn”?',
    );
    expect(question.correctOptionId, 'a');
    expect(
      question.options.firstWhere((item) => item.id == 'a').label,
      'Allah, Lord of all worlds.',
    );
  });

  test('mini2 complete-verse question is Al-Fatihah aligned', () {
    final controller = buildController();
    final question = controller.state.questions.firstWhere(
      (item) => item.id == 's1m2q1',
    );

    expect(question.prompt, 'Māliki ____');
    expect(question.context, 'Al-Fatihah — Verse 4');
    expect(question.correctOptionId, 'a');
    expect(
      question.options.map((item) => item.label).toSet().length,
      question.options.length,
    );
  });

  test('mini2 reading question stays within first four ayahs', () {
    final controller = buildController();
    final question = controller.state.questions.firstWhere(
      (item) => item.id == 's1m2q3',
    );

    expect(
      question.prompt,
      'What does “Ar-Rahmanir Rahim” remind us about Allah?',
    );
    expect(question.correctOptionId, 'a');
    expect(
      question.options.firstWhere((item) => item.id == 'a').label,
      'Allah is Most Gracious and Most Merciful.',
    );
  });

  test('non-selected options stay selectable before feedback', () {
    final controller = buildController();
    controller.nextQuestion();
    final question = controller.state.questions.firstWhere(
      (item) => item.id == 's1m2q1',
    );

    controller.selectOption(question.id, 'a');

    final selected = question.options.firstWhere((item) => item.id == 'a');
    final alternative = question.options.firstWhere((item) => item.id == 'b');

    expect(
      controller.optionState(question, selected),
      QuizOptionState.selected,
    );
    expect(
      controller.optionState(question, alternative),
      QuizOptionState.normal,
    );
  });

  test('retry clears current selection when requested', () async {
    final controller = buildController();
    controller.nextQuestion();
    final question = controller.state.questions[controller.state.currentIndex];

    controller.selectOption(question.id, 'b');
    await controller.submitCurrentAnswer();
    controller.retryCurrentQuestion(clearSelection: true);

    expect(controller.state.showFeedback, isFalse);
    expect(controller.state.selections.containsKey(question.id), isFalse);
  });

  test('wrong answer feedback is motivational only', () async {
    final controller = buildController();
    controller.nextQuestion();
    final question = controller.state.questions[controller.state.currentIndex];

    controller.selectOption(question.id, 'b');
    await controller.submitCurrentAnswer();

    expect(controller.state.showFeedback, isTrue);
    expect(
      controller.state.wrongFeedbackStyle,
      QuizWrongFeedbackStyle.motivational,
    );
  });
}
