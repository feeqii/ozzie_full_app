enum AyahLessonQuestionType { readingComprehension, fillInBlank }

class AyahLessonOption {
  const AyahLessonOption({
    required this.id,
    required this.label,
    this.subtitle,
  });

  final String id;
  final String label;
  final String? subtitle;
}

class AyahLessonQuestion {
  const AyahLessonQuestion({
    required this.id,
    required this.type,
    required this.title,
    required this.prompt,
    required this.options,
    required this.correctOptionId,
    this.context,
  });

  final String id;
  final AyahLessonQuestionType type;
  final String title;
  final String prompt;
  final String? context;
  final List<AyahLessonOption> options;
  final String correctOptionId;
}

List<AyahLessonQuestion> lessonQuestionsForAyah({
  required int surahId,
  required int ayahId,
}) {
  final key = '$surahId:$ayahId';
  return _ayahLessonQuestionBank[key] ?? const [];
}

final Map<String, List<AyahLessonQuestion>> _ayahLessonQuestionBank = {
  '1:1': const [
    AyahLessonQuestion(
      id: 's1a1q1',
      type: AyahLessonQuestionType.readingComprehension,
      title: 'Reading comprehension',
      prompt: 'What phrase opens this ayah?',
      options: [
        AyahLessonOption(id: 'a', label: 'In the name of Allah.'),
        AyahLessonOption(id: 'b', label: 'Guide us to the straight path.'),
        AyahLessonOption(id: 'c', label: 'Master of the Day of Judgment.'),
        AyahLessonOption(
          id: 'd',
          label: 'You alone we worship and ask for help.',
        ),
      ],
      correctOptionId: 'a',
    ),
    AyahLessonQuestion(
      id: 's1a1q2',
      type: AyahLessonQuestionType.fillInBlank,
      title: 'Fill in the blank',
      prompt: 'Bismillahir-rahmanir ____',
      context: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
      options: [
        AyahLessonOption(id: 'a', label: 'rahim', subtitle: 'الرَّحِيمِ'),
        AyahLessonOption(id: 'b', label: 'din', subtitle: 'الدِّينِ'),
        AyahLessonOption(
          id: 'c',
          label: 'mustaqim',
          subtitle: 'الْمُسْتَقِيمَ',
        ),
        AyahLessonOption(id: 'd', label: 'alamin', subtitle: 'الْعَالَمِينَ'),
      ],
      correctOptionId: 'a',
    ),
  ],
  '1:2': const [
    AyahLessonQuestion(
      id: 's1a2q1',
      type: AyahLessonQuestionType.readingComprehension,
      title: 'Reading comprehension',
      prompt: 'Who is praised in this ayah?',
      options: [
        AyahLessonOption(id: 'a', label: 'Allah, Lord of all worlds.'),
        AyahLessonOption(id: 'b', label: 'Only the angels.'),
        AyahLessonOption(id: 'c', label: 'Only the prophets.'),
        AyahLessonOption(id: 'd', label: 'Only believers.'),
      ],
      correctOptionId: 'a',
    ),
    AyahLessonQuestion(
      id: 's1a2q2',
      type: AyahLessonQuestionType.fillInBlank,
      title: 'Fill in the blank',
      prompt: 'Rabbil ____',
      context: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
      options: [
        AyahLessonOption(id: 'a', label: 'alamin', subtitle: 'الْعَالَمِينَ'),
        AyahLessonOption(id: 'b', label: 'rahim', subtitle: 'الرَّحِيمِ'),
        AyahLessonOption(id: 'c', label: 'ahad', subtitle: 'أَحَدٌ'),
        AyahLessonOption(id: 'd', label: 'samad', subtitle: 'الصَّمَدُ'),
      ],
      correctOptionId: 'a',
    ),
  ],
  '1:3': const [
    AyahLessonQuestion(
      id: 's1a3q1',
      type: AyahLessonQuestionType.readingComprehension,
      title: 'Reading comprehension',
      prompt: 'What does Ar-Rahmanir-Rahim remind us about Allah?',
      options: [
        AyahLessonOption(
          id: 'a',
          label: 'Allah is Most Gracious and Most Merciful.',
        ),
        AyahLessonOption(id: 'b', label: 'Allah is in need of helpers.'),
        AyahLessonOption(id: 'c', label: 'Allah is only for one group.'),
        AyahLessonOption(id: 'd', label: 'Allah changes with time.'),
      ],
      correctOptionId: 'a',
    ),
    AyahLessonQuestion(
      id: 's1a3q2',
      type: AyahLessonQuestionType.fillInBlank,
      title: 'Fill in the blank',
      prompt: 'Ar-Rahmani ____',
      context: 'الرَّحْمَٰنِ الرَّحِيمِ',
      options: [
        AyahLessonOption(id: 'a', label: 'rahim', subtitle: 'الرَّحِيمِ'),
        AyahLessonOption(
          id: 'b',
          label: 'yawmid-din',
          subtitle: 'يَوْمِ الدِّينِ',
        ),
        AyahLessonOption(id: 'c', label: 'nasta in', subtitle: 'نَسْتَعِينُ'),
        AyahLessonOption(
          id: 'd',
          label: 'mustaqim',
          subtitle: 'الْمُسْتَقِيمَ',
        ),
      ],
      correctOptionId: 'a',
    ),
  ],
  '1:4': const [
    AyahLessonQuestion(
      id: 's1a4q1',
      type: AyahLessonQuestionType.readingComprehension,
      title: 'Reading comprehension',
      prompt: 'What does "Maliki yawmid-din" mean?',
      options: [
        AyahLessonOption(id: 'a', label: 'Master of the Day of Judgment.'),
        AyahLessonOption(id: 'b', label: 'Guide us to the straight path.'),
        AyahLessonOption(id: 'c', label: 'Lord of all worlds.'),
        AyahLessonOption(id: 'd', label: 'Most Merciful.'),
      ],
      correctOptionId: 'a',
    ),
    AyahLessonQuestion(
      id: 's1a4q2',
      type: AyahLessonQuestionType.fillInBlank,
      title: 'Fill in the blank',
      prompt: 'Maliki yawmid ____',
      context: 'مَالِكِ يَوْمِ الدِّينِ',
      options: [
        AyahLessonOption(id: 'a', label: 'din', subtitle: 'الدِّينِ'),
        AyahLessonOption(id: 'b', label: 'rahim', subtitle: 'الرَّحِيمِ'),
        AyahLessonOption(id: 'c', label: 'alamin', subtitle: 'الْعَالَمِينَ'),
        AyahLessonOption(id: 'd', label: 'samad', subtitle: 'الصَّمَدُ'),
      ],
      correctOptionId: 'a',
    ),
  ],
  '1:5': const [
    AyahLessonQuestion(
      id: 's1a5q1',
      type: AyahLessonQuestionType.readingComprehension,
      title: 'Reading comprehension',
      prompt: 'In this ayah, who do we worship and ask for help?',
      options: [
        AyahLessonOption(id: 'a', label: 'Allah alone.'),
        AyahLessonOption(id: 'b', label: 'The prophets.'),
        AyahLessonOption(id: 'c', label: 'The angels.'),
        AyahLessonOption(id: 'd', label: 'Everyone around us.'),
      ],
      correctOptionId: 'a',
    ),
    AyahLessonQuestion(
      id: 's1a5q2',
      type: AyahLessonQuestionType.fillInBlank,
      title: 'Fill in the blank',
      prompt: 'Iyyaka na budu wa iyyaka ____',
      context: 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
      options: [
        AyahLessonOption(id: 'a', label: 'nasta in', subtitle: 'نَسْتَعِينُ'),
        AyahLessonOption(id: 'b', label: 'rahim', subtitle: 'الرَّحِيمِ'),
        AyahLessonOption(
          id: 'c',
          label: 'mustaqim',
          subtitle: 'الْمُسْتَقِيمَ',
        ),
        AyahLessonOption(id: 'd', label: 'din', subtitle: 'الدِّينِ'),
      ],
      correctOptionId: 'a',
    ),
  ],
  '1:6': const [
    AyahLessonQuestion(
      id: 's1a6q1',
      type: AyahLessonQuestionType.readingComprehension,
      title: 'Reading comprehension',
      prompt: 'What are we asking Allah for in this ayah?',
      options: [
        AyahLessonOption(id: 'a', label: 'Guidance to the straight path.'),
        AyahLessonOption(id: 'b', label: 'More wealth.'),
        AyahLessonOption(id: 'c', label: 'Long life.'),
        AyahLessonOption(id: 'd', label: 'Fame and power.'),
      ],
      correctOptionId: 'a',
    ),
    AyahLessonQuestion(
      id: 's1a6q2',
      type: AyahLessonQuestionType.fillInBlank,
      title: 'Fill in the blank',
      prompt: 'Ihdinas-siratal ____',
      context: 'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ',
      options: [
        AyahLessonOption(
          id: 'a',
          label: 'mustaqim',
          subtitle: 'الْمُسْتَقِيمَ',
        ),
        AyahLessonOption(id: 'b', label: 'rahim', subtitle: 'الرَّحِيمِ'),
        AyahLessonOption(id: 'c', label: 'yulad', subtitle: 'يُولَدْ'),
        AyahLessonOption(id: 'd', label: 'ahad', subtitle: 'أَحَدٌ'),
      ],
      correctOptionId: 'a',
    ),
  ],
  '1:7': const [
    AyahLessonQuestion(
      id: 's1a7q1',
      type: AyahLessonQuestionType.readingComprehension,
      title: 'Reading comprehension',
      prompt: 'Which path do we ask to follow?',
      options: [
        AyahLessonOption(id: 'a', label: 'The path of those Allah favored.'),
        AyahLessonOption(id: 'b', label: 'The path of people who went astray.'),
        AyahLessonOption(id: 'c', label: 'Any path as long as it is easy.'),
        AyahLessonOption(id: 'd', label: 'Only the path of wealth.'),
      ],
      correctOptionId: 'a',
    ),
    AyahLessonQuestion(
      id: 's1a7q2',
      type: AyahLessonQuestionType.fillInBlank,
      title: 'Fill in the blank',
      prompt: 'Ghayril-maghdubi alayhim wa lad-____',
      context: 'غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ',
      options: [
        AyahLessonOption(id: 'a', label: 'dallin', subtitle: 'الضَّالِّينَ'),
        AyahLessonOption(id: 'b', label: 'rahim', subtitle: 'الرَّحِيمِ'),
        AyahLessonOption(id: 'c', label: 'samad', subtitle: 'الصَّمَدُ'),
        AyahLessonOption(id: 'd', label: 'alamin', subtitle: 'الْعَالَمِينَ'),
      ],
      correctOptionId: 'a',
    ),
  ],
  '112:1': const [
    AyahLessonQuestion(
      id: 's112a1q1',
      type: AyahLessonQuestionType.readingComprehension,
      title: 'Reading comprehension',
      prompt: 'What does this ayah declare about Allah?',
      options: [
        AyahLessonOption(id: 'a', label: 'Allah is One.'),
        AyahLessonOption(id: 'b', label: 'Allah has partners.'),
        AyahLessonOption(id: 'c', label: 'Allah changes with time.'),
        AyahLessonOption(id: 'd', label: 'Allah needs support.'),
      ],
      correctOptionId: 'a',
    ),
    AyahLessonQuestion(
      id: 's112a1q2',
      type: AyahLessonQuestionType.fillInBlank,
      title: 'Fill in the blank',
      prompt: 'Qul huwa Allahu ____',
      context: 'قُلْ هُوَ اللَّهُ أَحَدٌ',
      options: [
        AyahLessonOption(id: 'a', label: 'ahad', subtitle: 'أَحَدٌ'),
        AyahLessonOption(id: 'b', label: 'samad', subtitle: 'الصَّمَدُ'),
        AyahLessonOption(id: 'c', label: 'yulad', subtitle: 'يُولَدْ'),
        AyahLessonOption(id: 'd', label: 'kufuwan', subtitle: 'كُفُوًا'),
      ],
      correctOptionId: 'a',
    ),
  ],
  '112:2': const [
    AyahLessonQuestion(
      id: 's112a2q1',
      type: AyahLessonQuestionType.readingComprehension,
      title: 'Reading comprehension',
      prompt: 'What does "As-Samad" mean?',
      options: [
        AyahLessonOption(id: 'a', label: 'The Eternal Refuge.'),
        AyahLessonOption(id: 'b', label: 'The Most Forgiving only.'),
        AyahLessonOption(id: 'c', label: 'The One who was born.'),
        AyahLessonOption(id: 'd', label: 'The One with equals.'),
      ],
      correctOptionId: 'a',
    ),
    AyahLessonQuestion(
      id: 's112a2q2',
      type: AyahLessonQuestionType.fillInBlank,
      title: 'Fill in the blank',
      prompt: 'Allahu ____',
      context: 'اللَّهُ الصَّمَدُ',
      options: [
        AyahLessonOption(id: 'a', label: 'as-samad', subtitle: 'الصَّمَدُ'),
        AyahLessonOption(id: 'b', label: 'ahad', subtitle: 'أَحَدٌ'),
        AyahLessonOption(id: 'c', label: 'yulad', subtitle: 'يُولَدْ'),
        AyahLessonOption(id: 'd', label: 'rahim', subtitle: 'الرَّحِيمِ'),
      ],
      correctOptionId: 'a',
    ),
  ],
  '112:3': const [
    AyahLessonQuestion(
      id: 's112a3q1',
      type: AyahLessonQuestionType.readingComprehension,
      title: 'Reading comprehension',
      prompt: 'What does this ayah teach?',
      options: [
        AyahLessonOption(id: 'a', label: 'Allah neither begets nor is born.'),
        AyahLessonOption(id: 'b', label: 'Allah has many children.'),
        AyahLessonOption(id: 'c', label: 'Allah needs helpers.'),
        AyahLessonOption(id: 'd', label: 'Allah is only for some people.'),
      ],
      correctOptionId: 'a',
    ),
    AyahLessonQuestion(
      id: 's112a3q2',
      type: AyahLessonQuestionType.fillInBlank,
      title: 'Fill in the blank',
      prompt: 'Lam yalid wa lam ____',
      context: 'لَمْ يَلِدْ وَلَمْ يُولَدْ',
      options: [
        AyahLessonOption(id: 'a', label: 'yulad', subtitle: 'يُولَدْ'),
        AyahLessonOption(id: 'b', label: 'yakun', subtitle: 'يَكُن'),
        AyahLessonOption(id: 'c', label: 'ahad', subtitle: 'أَحَدٌ'),
        AyahLessonOption(id: 'd', label: 'samad', subtitle: 'الصَّمَدُ'),
      ],
      correctOptionId: 'a',
    ),
  ],
  '112:4': const [
    AyahLessonQuestion(
      id: 's112a4q1',
      type: AyahLessonQuestionType.readingComprehension,
      title: 'Reading comprehension',
      prompt: 'What is the meaning of this ayah?',
      options: [
        AyahLessonOption(id: 'a', label: 'Nothing is comparable to Allah.'),
        AyahLessonOption(id: 'b', label: 'Allah has equals.'),
        AyahLessonOption(id: 'c', label: 'Allah depends on creation.'),
        AyahLessonOption(id: 'd', label: 'Allah is limited by time.'),
      ],
      correctOptionId: 'a',
    ),
    AyahLessonQuestion(
      id: 's112a4q2',
      type: AyahLessonQuestionType.fillInBlank,
      title: 'Fill in the blank',
      prompt: 'Wa lam yakun lahu ____ ahad',
      context: 'وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ',
      options: [
        AyahLessonOption(id: 'a', label: 'kufuwan', subtitle: 'كُفُوًا'),
        AyahLessonOption(id: 'b', label: 'samad', subtitle: 'الصَّمَدُ'),
        AyahLessonOption(id: 'c', label: 'rahim', subtitle: 'الرَّحِيمِ'),
        AyahLessonOption(id: 'd', label: 'alamin', subtitle: 'الْعَالَمِينَ'),
      ],
      correctOptionId: 'a',
    ),
  ],
};
