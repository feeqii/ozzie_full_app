import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_session_provider.dart';
import '../../features/auth/screens/auth_entry_screen.dart';
import '../../features/auth/screens/auth_otp_screen.dart';
import '../../features/auth/screens/auth_sign_in_screen.dart';
import '../../features/auth/screens/auth_sign_up_screen.dart';
import '../../features/auth/screens/auth_success_screen.dart';
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
    initialLocation: '/auth/entry',
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
      final inChildFlow = state.uri.path.startsWith('/child');
      final isAllowedParentRoute =
          state.uri.path == '/parent/dashboard' || state.uri.path.startsWith('/parent/child');

      final profileAsync = ref.read(parentProfileProvider);
      final pinVerified = ref.read(pinVerifiedProvider);
      final childrenAsync = ref.read(childrenProvider);
      final selectedChildIdAsync = ref.read(selectedChildIdProvider);

      if (isLoading) {
        return null;
      }

      if (session == null) {
        if (!inAuthFlow) {
          return '/auth/entry';
        }
        return null;
      }

      if (profileAsync.isLoading || childrenAsync.isLoading || selectedChildIdAsync.isLoading) {
        return null;
      }

      if (profileAsync.hasError || childrenAsync.hasError || selectedChildIdAsync.hasError) {
        return null;
      }

      final profile = profileAsync.asData?.value;
      if (profile == null) {
        if (inAuthFlow && state.uri.path == '/auth/success') {
          return null;
        }
        return '/auth/success';
      }

      final pinHash = profile.pinHash;
      if (pinHash == null || pinHash.isEmpty) {
        if (state.uri.path != '/parent/pin/setup') {
          return '/parent/pin/setup';
        }
        return null;
      }

      if (!pinVerified) {
        if (state.uri.path != '/parent/pin/verify') {
          return '/parent/pin/verify';
        }
        return null;
      }

      final children = childrenAsync.asData?.value ?? const [];
      if (children.isEmpty) {
        if (state.uri.path != '/parent/child/add') {
          return '/parent/child/add';
        }
        return null;
      }

      if (children.length == 1) {
        final onlyChild = children.first;
        final selectedId = selectedChildIdAsync.asData?.value;
        if (selectedId != onlyChild.id) {
          ref.read(selectedChildIdProvider.notifier).selectChild(onlyChild.id);
        }
        if (inParentFlow && isAllowedParentRoute) {
          return null;
        }
        if (inChildFlow) {
          return null;
        }
        return '/child/home';
      }

      final selectedId = selectedChildIdAsync.asData?.value;
      final hasSelected = selectedId != null && children.any((child) => child.id == selectedId);
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
        path: '/auth/otp',
        builder: (context, state) => const AuthOtpScreen(),
      ),
      GoRoute(
        path: '/auth/success',
        builder: (context, state) => const AuthSuccessScreen(),
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
      body: Center(
        child: Text('Route not found: ${state.uri.path}'),
      ),
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
