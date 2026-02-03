import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/models/auth_flow_args.dart';
import '../../features/auth/providers/auth_session_provider.dart';
import '../../features/auth/screens/auth_entry_screen.dart';
import '../../features/auth/screens/auth_otp_screen.dart';
import '../../features/auth/screens/auth_sign_in_screen.dart';
import '../../features/auth/screens/auth_sign_up_screen.dart';
import '../../features/auth/screens/auth_success_screen.dart';
import '../../features/child/child_home_screen.dart';
import '../../features/child/providers/child_providers.dart';
import '../../features/gallery/design_system_gallery_screen.dart';
import '../../features/parent/providers/parent_profile_provider.dart';
import '../../features/parent/screens/add_child_screen.dart';
import '../../features/parent/screens/enter_pin_screen.dart';
import '../../features/parent/screens/select_child_screen.dart';
import '../../features/parent/screens/set_pin_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/auth/entry',
    refreshListenable: GoRouterRefreshStream(
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
        if (state.uri.path != '/child/home') {
          return '/child/home';
        }
        return null;
      }

      final selectedId = selectedChildIdAsync.asData?.value;
      final hasSelected = selectedId != null && children.any((child) => child.id == selectedId);
      if (!hasSelected) {
        if (state.uri.path != '/parent/child/select') {
          return '/parent/child/select';
        }
        return null;
      }

      if (inAuthFlow || inDesignFlow) {
        return '/child/home';
      }

      if (inParentFlow && state.uri.path != '/parent/child/select') {
        return '/child/home';
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
        builder: (context, state) {
          final args = state.extra as AuthFlowArgs?;
          if (args == null) {
            return const AuthEntryScreen();
          }
          return AuthOtpScreen(args: args);
        },
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
        path: '/parent/child/select',
        builder: (context, state) => const SelectChildScreen(),
      ),
      GoRoute(
        path: '/parent/child/add',
        builder: (context, state) => const AddChildScreen(),
      ),
      GoRoute(
        path: '/child/home',
        builder: (context, state) => const ChildHomeScreen(),
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
