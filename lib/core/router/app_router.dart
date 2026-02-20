import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_session_provider.dart';
import '../../features/auth/screens/auth_entry_screen.dart';
import '../../features/auth/screens/auth_forgot_password_screen.dart';
import '../../features/auth/screens/auth_onboarding_screen.dart';
import '../../features/auth/screens/auth_sign_in_screen.dart';
import '../../features/auth/screens/auth_sign_up_screen.dart';
import '../../features/child/child_home_screen.dart';
import '../../features/child/providers/child_providers.dart';
import '../../features/child/screens/ayah_learn_screen.dart';
import '../../features/child/screens/surah_intro_screen.dart';
import '../../features/child/screens/surah_journey_screen.dart';
import '../../features/gallery/design_system_gallery_screen.dart';
import '../../features/map/screens/galaxy_map_screen.dart';
import '../../features/map/screens/planet_map_screen.dart';
import '../../features/parent/screens/parent_dashboard_screen.dart';
import '../../features/parent/providers/parent_profile_provider.dart';
import '../../features/parent/screens/add_child_screen.dart';
import '../../features/parent/screens/enter_pin_screen.dart';
import '../../features/parent/screens/select_child_screen.dart';
import '../../features/parent/screens/set_pin_screen.dart';
import '../../features/progress/screens/child_progress_home_screen.dart';
import '../../features/progress/screens/child_recite_time_screen.dart';
import '../../features/progress/screens/child_score_screen.dart';
import '../../features/progress/screens/child_streak_screen.dart';
import '../../features/quiz/models/quiz_models.dart';
import '../../features/quiz/screens/quiz_screen.dart';
import '../../features/recitation/screens/recitation_practice_screen.dart';
import '../../features/rewards/models/reward_event.dart';
import '../../features/rewards/screens/reward_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/auth/onboarding',
    refreshListenable: GoRouterRefreshStream(
      // ignore: deprecated_member_use
      ref.watch(authSessionProvider.stream),
    ),
    redirect: (context, state) {
      final sessionAsync = ref.read(authSessionProvider);
      final isLoading = sessionAsync.isLoading;
      final session = sessionAsync.asData?.value;

      final inAuthFlow = state.uri.path.startsWith('/auth');
      final inDesignFlow = state.uri.path == '/';
      final inParentFlow = state.uri.path.startsWith('/parent');
      final inParentPinFlow = state.uri.path.startsWith('/parent/pin/');
      final inChildFlow = state.uri.path.startsWith('/child');
      final isAllowedParentRoute =
          state.uri.path == '/parent/dashboard' ||
          state.uri.path.startsWith('/parent/child') ||
          state.uri.path.startsWith('/parent/pin/');

      final profileAsync = ref.read(parentProfileProvider);
      final childrenAsync = ref.read(childrenProvider);
      final selectedChildIdAsync = ref.read(selectedChildIdProvider);

      if (isLoading) {
        return null;
      }

      if (session == null) {
        if (!inAuthFlow) {
          return '/auth/onboarding';
        }
        return null;
      }

      if (profileAsync.isLoading ||
          childrenAsync.isLoading ||
          selectedChildIdAsync.isLoading) {
        return null;
      }

      if (profileAsync.hasError ||
          childrenAsync.hasError ||
          selectedChildIdAsync.hasError) {
        return null;
      }

      final children = childrenAsync.asData?.value ?? const [];
      if (children.isEmpty) {
        if (inParentPinFlow) {
          return null;
        }
        if (state.uri.path != '/parent/child/add') {
          return '/parent/child/add';
        }
        return null;
      }

      final selectedId = selectedChildIdAsync.asData?.value;
      final hasSelected =
          selectedId != null && children.any((child) => child.id == selectedId);
      if (!hasSelected) {
        if (state.uri.path == '/parent/child/select') {
          return null;
        }
        if (inParentFlow && isAllowedParentRoute) {
          return null;
        }
        return '/parent/child/select';
      }

      if (inAuthFlow || inDesignFlow) {
        return '/child/home';
      }

      if (inParentFlow) {
        return isAllowedParentRoute ? null : '/child/home';
      }

      if (!inChildFlow) {
        return '/child/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DesignSystemGalleryScreen(),
      ),
      GoRoute(
        path: '/auth/onboarding',
        builder: (context, state) => const AuthOnboardingScreen(),
      ),
      GoRoute(
        path: '/auth/entry',
        builder: (context, state) => const AuthEntryScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (context, state) => const AuthSignUpScreen(),
      ),
      GoRoute(
        path: '/auth/signin',
        builder: (context, state) => const AuthSignInScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const AuthForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/parent/pin/setup',
        builder: (context, state) => const SetPinScreen(),
      ),
      GoRoute(
        path: '/parent/pin/verify',
        builder: (context, state) => const EnterPinScreen(),
      ),
      GoRoute(
        path: '/parent/dashboard',
        builder: (context, state) => const ParentDashboardScreen(),
      ),
      GoRoute(
        path: '/parent/child/select',
        builder: (context, state) => const SelectChildScreen(),
      ),
      GoRoute(
        path: '/parent/child/add',
        builder: (context, state) => const AddChildScreen(),
      ),
      GoRoute(
        path: '/parent/child/:childId/progress',
        builder: (context, state) {
          final childId = state.pathParameters['childId'];
          if (childId == null || childId.isEmpty) {
            return const ParentDashboardScreen();
          }
          return ChildProgressHomeScreen(childId: childId);
        },
      ),
      GoRoute(
        path: '/parent/child/:childId/progress/streak',
        builder: (context, state) {
          final childId = state.pathParameters['childId'];
          if (childId == null || childId.isEmpty) {
            return const ParentDashboardScreen();
          }
          return ChildStreakScreen(childId: childId);
        },
      ),
      GoRoute(
        path: '/parent/child/:childId/progress/time',
        builder: (context, state) {
          final childId = state.pathParameters['childId'];
          if (childId == null || childId.isEmpty) {
            return const ParentDashboardScreen();
          }
          return ChildReciteTimeScreen(childId: childId);
        },
      ),
      GoRoute(
        path: '/parent/child/:childId/progress/score',
        builder: (context, state) {
          final childId = state.pathParameters['childId'];
          if (childId == null || childId.isEmpty) {
            return const ParentDashboardScreen();
          }
          return ChildScoreScreen(childId: childId);
        },
      ),
      GoRoute(
        path: '/child/home',
        builder: (context, state) => const ChildHomeScreen(),
      ),
      GoRoute(
        path: '/child/map',
        builder: (context, state) => const GalaxyMapScreen(),
      ),
      GoRoute(
        path: '/child/map/galaxy/:galaxyId',
        builder: (context, state) {
          final galaxyId = int.tryParse(state.pathParameters['galaxyId'] ?? '');
          if (galaxyId == null) {
            return const GalaxyMapScreen();
          }
          return PlanetMapScreen(galaxyId: galaxyId);
        },
      ),
      GoRoute(
        path: '/child/progress',
        builder: (context, state) => const ChildProgressHomeScreen(),
      ),
      GoRoute(
        path: '/child/progress/streak',
        builder: (context, state) => const ChildStreakScreen(),
      ),
      GoRoute(
        path: '/child/progress/time',
        builder: (context, state) => const ChildReciteTimeScreen(),
      ),
      GoRoute(
        path: '/child/progress/score',
        builder: (context, state) => const ChildScoreScreen(),
      ),
      GoRoute(
        path: '/child/reward',
        builder: (context, state) {
          final args = state.extra as RewardScreenArgs?;
          if (args == null) {
            return const ChildHomeScreen();
          }
          return RewardScreen(args: args);
        },
      ),
      GoRoute(
        path: '/child/surah/:surahId',
        builder: (context, state) {
          final surahId = int.tryParse(state.pathParameters['surahId'] ?? '');
          if (surahId == null) {
            return const ChildHomeScreen();
          }
          return SurahJourneyScreen(surahId: surahId);
        },
      ),
      GoRoute(
        path: '/child/surah/:surahId/intro/:levelId',
        builder: (context, state) {
          final surahId = int.tryParse(state.pathParameters['surahId'] ?? '');
          final levelId = state.pathParameters['levelId'];
          if (surahId == null || levelId == null || levelId.isEmpty) {
            return const ChildHomeScreen();
          }
          return SurahIntroScreen(surahId: surahId, levelId: levelId);
        },
      ),
      GoRoute(
        path: '/child/surah/:surahId/ayah/:ayahId',
        builder: (context, state) {
          final surahId = int.tryParse(state.pathParameters['surahId'] ?? '');
          final ayahId = int.tryParse(state.pathParameters['ayahId'] ?? '');
          if (surahId == null || ayahId == null) {
            return const ChildHomeScreen();
          }
          return AyahLearnScreen(surahId: surahId, ayahId: ayahId);
        },
      ),
      GoRoute(
        path: '/child/surah/:surahId/ayah/:ayahId/recite',
        builder: (context, state) {
          final surahId = int.tryParse(state.pathParameters['surahId'] ?? '');
          final ayahId = int.tryParse(state.pathParameters['ayahId'] ?? '');
          if (surahId == null || ayahId == null) {
            return const ChildHomeScreen();
          }
          return RecitationPracticeScreen(surahId: surahId, ayahId: ayahId);
        },
      ),
      GoRoute(
        path: '/child/surah/:surahId/quiz/:quizType',
        builder: (context, state) {
          final surahId = int.tryParse(state.pathParameters['surahId'] ?? '');
          final quizType = quizTypeFromRoute(state.pathParameters['quizType']);
          if (surahId == null || quizType == null) {
            return const ChildHomeScreen();
          }
          return QuizScreen(surahId: surahId, quizType: quizType);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri.path}')),
    ),
  );
});

class AppRouter {
  AppRouter._();
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<Object?> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
