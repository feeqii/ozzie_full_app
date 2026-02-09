import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ozzie/core/theme/app_theme.dart';
import 'package:ozzie/features/child/child_home_screen.dart';
import 'package:ozzie/features/child/models/child_profile.dart';
import 'package:ozzie/features/child/providers/child_providers.dart';
import 'package:ozzie/features/child/screens/ayah_learn_screen.dart';
import 'package:ozzie/features/child/screens/surah_journey_screen.dart';
import 'package:ozzie/features/content/models/ayah_content.dart';
import 'package:ozzie/features/content/models/surah_content.dart';
import 'package:ozzie/features/content/providers/content_providers.dart';
import 'package:ozzie/features/journey/models/journey_models.dart';
import 'package:ozzie/features/journey/providers/journey_providers.dart';
import 'package:ozzie/features/map/models/map_models.dart';
import 'package:ozzie/features/map/providers/map_providers.dart';
import 'package:ozzie/features/map/repo/map_repository.dart';
import 'package:ozzie/features/map/screens/galaxy_map_screen.dart';
import 'package:ozzie/features/map/screens/planet_map_screen.dart';
import 'package:ozzie/features/progress/models/child_progress_summary.dart';
import 'package:ozzie/features/progress/providers/practice_session_providers.dart';
import 'package:ozzie/features/progress/providers/progress_providers.dart';
import 'package:ozzie/features/progress/repo/practice_session_repository.dart';
import 'package:ozzie/features/quiz/models/quiz_models.dart';
import 'package:ozzie/features/quiz/providers/quiz_providers.dart';
import 'package:ozzie/features/quiz/providers/quiz_recitation_controller.dart';
import 'package:ozzie/features/quiz/repo/quiz_recitation_repository.dart';
import 'package:ozzie/features/quiz/repo/quiz_repository.dart';
import 'package:ozzie/features/quiz/screens/quiz_screen.dart';
import 'package:ozzie/features/recitation/providers/recitation_controller.dart';
import 'package:ozzie/features/recitation/repo/recitation_repository.dart';
import 'package:ozzie/features/recitation/screens/recitation_practice_screen.dart';
import 'package:ozzie/features/rewards/models/reward_event.dart';
import 'package:ozzie/features/rewards/screens/reward_screen.dart';

class _FakeMapRepository implements MapRepository {
  @override
  Future<MapState> fetchMapState({required String childId}) async {
    throw UnimplementedError('fetchMapState not used in widget tests.');
  }

  @override
  Future<void> startSurah({required String childId, required int surahId}) async {}

  @override
  Future<void> completeLevel({required String childId, required String levelId}) async {}
}

class _FakePracticeSessionRepository implements PracticeSessionRepository {
  @override
  Future<String> startSession({required String childId}) async => 'test_session';

  @override
  Future<void> endSession({required String childId, required String sessionId}) async {}
}

class _FakeRecitationRepository implements RecitationRepository {
  @override
  String buildStoragePath({required int surahId, required int ayahId}) {
    return 'surah_$surahId/ayah_$ayahId/test.m4a';
  }

  @override
  Future<String> uploadRecitation({required String localPath, required String storagePath}) async {
    return storagePath;
  }

  @override
  Future<Map<String, dynamic>> submitRecitation({
    required String childId,
    required int surahId,
    required int ayahId,
    required String audioPath,
    Map<String, dynamic>? meta,
  }) async {
    return <String, dynamic>{
      'passed': true,
      'score': 100,
    };
  }
}

class _FakeQuizRepository implements QuizRepository {
  @override
  Future<SurahProgress?> fetchSurahProgress({required String childId, required int surahId}) async => null;

  @override
  Future<Map<String, dynamic>> submitQuiz({
    required String childId,
    required int surahId,
    required QuizType quizType,
    required List<QuizAnswerItem> answers,
  }) async {
    return <String, dynamic>{
      'score': 100,
      'passed': true,
    };
  }
}

class _FakeQuizRecitationRepository implements QuizRecitationRepository {
  @override
  String buildStoragePath({required int surahId, required QuizType quizType}) {
    return 'quiz/surah_$surahId/${quizType.apiValue}/test.m4a';
  }

  @override
  Future<String> uploadRecitation({required String localPath, required String storagePath}) async => storagePath;

  @override
  Future<Map<String, dynamic>> submitLevelRecitation({
    required String childId,
    required int surahId,
    required QuizType quizType,
    required String audioPath,
    Map<String, dynamic>? meta,
  }) async {
    return <String, dynamic>{
      'score': 100,
      'passed': true,
    };
  }
}

Widget _wrapApp(
  Widget child, {
  required List<Override> overrides,
  double? textScale,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      builder: (context, widget) {
        final base = widget ?? const SizedBox.shrink();
        if (textScale == null) {
          return base;
        }
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(textScale)),
          child: base,
        );
      },
      home: child,
    ),
  );
}

void main() {
  const permissionChannel = MethodChannel('flutter.baseflow.com/permissions/methods');
  const recordChannel = MethodChannel('com.llfbandit.record/messages');

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      permissionChannel,
      (call) async {
        switch (call.method) {
          case 'checkPermissionStatus':
            return 1; // granted
          case 'requestPermissions':
            final args = call.arguments;
            if (args is List) {
              return <int, int>{for (final p in args) p as int: 1};
            }
            return <int, int>{};
          case 'checkServiceStatus':
            return 1; // enabled
          case 'shouldShowRequestPermissionRationale':
            return false;
          case 'openAppSettings':
            return true;
          default:
            return null;
        }
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      recordChannel,
      (call) async {
        switch (call.method) {
          case 'create':
          case 'dispose':
          case 'cancel':
          case 'start':
          case 'pause':
          case 'resume':
            return null;
          case 'stop':
            return null;
          case 'hasPermission':
            return true;
          case 'isPaused':
          case 'isRecording':
            return false;
          case 'getAmplitude':
            return <String, dynamic>{'current': 0.0, 'max': 0.0};
          case 'isEncoderSupported':
            return true;
          case 'listInputDevices':
            return <dynamic>[];
          default:
            return null;
        }
      },
    );
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(permissionChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(recordChannel, null);
  });

  final child = ChildProfile(
    id: 'child1',
    parentId: 'parent1',
    name: 'Amina',
  );

  final mapState = MapState(
    childId: child.id,
    activeCount: 1,
    slotsRemaining: 2,
    galaxies: [
      GalaxyNode(
        id: 1,
        nameEn: 'Entry',
        nameAr: 'مدخل',
        orderIndex: 1,
        unlocked: true,
        completed: false,
        surahs: const [
          SurahNode(
            id: 1,
            orderIndex: 1,
            name: 'Al-Fatihah',
            translation: 'The Opening',
            ayahCount: 7,
            status: SurahStatus.active,
            activeSlot: 1,
            locked: false,
            lockReason: null,
            playable: true,
          ),
          SurahNode(
            id: 112,
            orderIndex: 2,
            name: 'Al-Ikhlas',
            translation: 'Sincerity',
            ayahCount: 4,
            status: SurahStatus.completed,
            activeSlot: null,
            locked: false,
            lockReason: null,
            playable: true,
          ),
          SurahNode(
            id: 113,
            orderIndex: 3,
            name: 'Al-Falaq',
            translation: 'Daybreak',
            ayahCount: 5,
            status: SurahStatus.notStarted,
            activeSlot: null,
            locked: true,
            lockReason: 'NO_SLOTS',
            playable: true,
          ),
        ],
      ),
      const GalaxyNode(
        id: 2,
        nameEn: 'Beginner',
        nameAr: 'مبتدئ',
        orderIndex: 2,
        unlocked: false,
        completed: false,
        surahs: [],
      ),
    ],
  );

  final summary = ChildProgressSummary(
    streak: const ChildStreak(currentStreak: 3, bestStreak: 5),
    sessions: const SessionSummary(
      totalMinutes: 12,
      sessionCount: 1,
      lastSessionAt: null,
      entries: [],
    ),
    score: const ScoreSummary(
      averageScore: 88,
      latestScore: 92,
      attemptCount: 4,
      entries: [],
    ),
  );

  final surahContent = SurahContent(
    id: 1,
    name: 'Al-Fatihah',
    translation: 'The Opening',
    ayahs: const [
      AyahContent(
        id: 1,
        arabic: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        transliteration: 'Bismillahi r-rahmani r-rahim',
        translation: 'In the name of Allah, the Most Gracious, the Most Merciful.',
        meaning: 'We begin by remembering Allah with mercy and care.',
      ),
      AyahContent(
        id: 2,
        arabic: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
        transliteration: 'Alhamdu lillahi rabbil alamin',
        translation: 'All praise is for Allah, Lord of all worlds.',
        meaning: 'We thank Allah for everything we have.',
      ),
    ],
  );

  testWidgets('ChildHomeScreen renders mission control with resume + stamps', (tester) async {
    await tester.pumpWidget(
      _wrapApp(
        const ChildHomeScreen(),
        overrides: [
          selectedChildProvider.overrideWithValue(child),
          mapStateProvider.overrideWith((ref) async => mapState),
          childProgressSummaryProvider.overrideWith((ref, childId) async => summary),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Mission Control'), findsOneWidget);
    expect(find.textContaining('Welcome, '), findsOneWidget);
    expect(find.text('Continue mission'), findsOneWidget);
    expect(find.text('Explore the map'), findsOneWidget);
  });

  testWidgets('ChildHomeScreen handles large text scale without layout exceptions', (tester) async {
    await tester.pumpWidget(
      _wrapApp(
        const ChildHomeScreen(),
        overrides: [
          selectedChildProvider.overrideWithValue(child),
          mapStateProvider.overrideWith((ref) async => mapState),
          childProgressSummaryProvider.overrideWith((ref, childId) async => summary),
        ],
        textScale: 2.0,
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('GalaxyMapScreen renders galaxies and slot indicator', (tester) async {
    await tester.pumpWidget(
      _wrapApp(
        const GalaxyMapScreen(),
        overrides: [
          mapStateProvider.overrideWith((ref) async => mapState),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('slots left'), findsOneWidget);
    expect(find.text('Enter galaxy'), findsOneWidget);
  });

  testWidgets('GalaxyMapScreen handles large text scale without layout exceptions', (tester) async {
    await tester.pumpWidget(
      _wrapApp(
        const GalaxyMapScreen(),
        overrides: [
          mapStateProvider.overrideWith((ref) async => mapState),
        ],
        textScale: 2.0,
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('PlanetMapScreen renders orbit nodes for a galaxy', (tester) async {
    await tester.pumpWidget(
      _wrapApp(
        const PlanetMapScreen(galaxyId: 1),
        overrides: [
          selectedChildProvider.overrideWithValue(child),
          mapRepositoryProvider.overrideWithValue(_FakeMapRepository()),
          mapStateProvider.overrideWith((ref) async => mapState),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Galaxy'), findsWidgets);
    expect(find.text('Al-Fatihah'), findsOneWidget);
  });

  testWidgets('SurahJourneyScreen renders constellation path and nodes', (tester) async {
    final steps = [
      JourneyStep(
        level: const JourneyLevel(
          id: 'l1',
          surahId: 1,
          type: JourneyLevelType.surahIntro,
          orderIndex: 1,
        ),
        progress: const JourneyProgress(
          levelId: 'l1',
          status: JourneyLevelStatus.unlocked,
        ),
      ),
      JourneyStep(
        level: const JourneyLevel(
          id: 'l2',
          surahId: 1,
          type: JourneyLevelType.verseLesson,
          orderIndex: 2,
          ayahId: 1,
        ),
        progress: const JourneyProgress(
          levelId: 'l2',
          status: JourneyLevelStatus.inProgress,
        ),
      ),
      JourneyStep(
        level: const JourneyLevel(
          id: 'l3',
          surahId: 1,
          type: JourneyLevelType.checkpoint,
          orderIndex: 3,
          quizType: 'mini_1',
        ),
        progress: const JourneyProgress(
          levelId: 'l3',
          status: JourneyLevelStatus.locked,
        ),
      ),
    ];

    await tester.pumpWidget(
      _wrapApp(
        const SurahJourneyScreen(surahId: 1),
        overrides: [
          selectedChildProvider.overrideWithValue(child),
          mapRepositoryProvider.overrideWithValue(_FakeMapRepository()),
          mapStateProvider.overrideWith((ref) async => mapState),
          surahJourneyStepsProvider(1).overrideWith((ref) async => steps),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Journey'), findsOneWidget);
    expect(find.text('INTRO'), findsOneWidget);
    expect(find.textContaining('Follow the constellation'), findsOneWidget);
  });

  testWidgets('RewardScreen renders collectible reward details', (tester) async {
    final args = RewardScreenArgs(
      event: const RewardEvent(
        type: RewardType.badge,
        title: 'Stamped!',
        message: 'You earned a new badge for your practice.',
        score: 95,
      ),
      primaryLabel: 'Continue',
      primaryRoute: '/child/home',
      secondaryLabel: 'Back to map',
      secondaryRoute: '/child/map',
    );

    await tester.pumpWidget(
      _wrapApp(
        RewardScreen(args: args),
        overrides: const [],
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Rewards'), findsOneWidget);
    expect(find.text('Stamped!'), findsWidgets);
    expect(find.text('95%'), findsOneWidget);
  });

  testWidgets('AyahLearnScreen renders illustration-first lesson layout', (tester) async {
    await tester.pumpWidget(
      _wrapApp(
        const AyahLearnScreen(surahId: 1, ayahId: 1),
        overrides: [
          selectedChildProvider.overrideWithValue(child),
          practiceSessionRepositoryProvider.overrideWithValue(_FakePracticeSessionRepository()),
          surahContentProvider(1).overrideWith((ref) async => surahContent),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('AYAH'), findsOneWidget);
    expect(find.textContaining('Practice recitation'), findsOneWidget);
  });

  testWidgets('RecitationPracticeScreen renders without plugin exceptions', (tester) async {
    await tester.pumpWidget(
      _wrapApp(
        const RecitationPracticeScreen(surahId: 1, ayahId: 1),
        overrides: [
          selectedChildProvider.overrideWithValue(child),
          practiceSessionRepositoryProvider.overrideWithValue(_FakePracticeSessionRepository()),
          recitationRepositoryProvider.overrideWithValue(_FakeRecitationRepository()),
          surahContentProvider(1).overrideWith((ref) async => surahContent),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Practice'), findsOneWidget);
    expect(find.textContaining('Back to learn'), findsOneWidget);
  });

  testWidgets('QuizScreen renders mission card + options without plugin exceptions', (tester) async {
    await tester.pumpWidget(
      _wrapApp(
        const QuizScreen(surahId: 1, quizType: QuizType.mini1),
        overrides: [
          selectedChildProvider.overrideWithValue(child),
          practiceSessionRepositoryProvider.overrideWithValue(_FakePracticeSessionRepository()),
          quizRepositoryProvider.overrideWithValue(_FakeQuizRepository()),
          quizRecitationRepositoryProvider.overrideWithValue(_FakeQuizRecitationRepository()),
          surahContentProvider(1).overrideWith((ref) async => surahContent),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(QuizType.mini1.label), findsOneWidget);
    expect(find.text('MEMORIZATION'), findsOneWidget);
    expect(find.textContaining('Recite the two verses'), findsOneWidget);
  });

  testWidgets('QuizScreen handles large text scale without layout exceptions', (tester) async {
    await tester.pumpWidget(
      _wrapApp(
        const QuizScreen(surahId: 1, quizType: QuizType.mini1),
        overrides: [
          selectedChildProvider.overrideWithValue(child),
          practiceSessionRepositoryProvider.overrideWithValue(_FakePracticeSessionRepository()),
          quizRepositoryProvider.overrideWithValue(_FakeQuizRepository()),
          quizRecitationRepositoryProvider.overrideWithValue(_FakeQuizRecitationRepository()),
          surahContentProvider(1).overrideWith((ref) async => surahContent),
        ],
        textScale: 2.0,
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
