import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_placeholder_screen.dart';
import '../../features/child/child_placeholder_screen.dart';
import '../../features/gallery/design_system_gallery_screen.dart';
import '../../features/parent/parent_placeholder_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DesignSystemGalleryScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthPlaceholderScreen(),
      ),
      GoRoute(
        path: '/parent',
        builder: (context, state) => const ParentPlaceholderScreen(),
      ),
      GoRoute(
        path: '/child',
        builder: (context, state) => const ChildPlaceholderScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri.path}'),
      ),
    ),
  );
}
