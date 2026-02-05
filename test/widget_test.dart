import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ozzie/core/app_bootstrap.dart';
import 'package:ozzie/core/app_startup_screen.dart';
import 'package:ozzie/core/app_startup_state.dart';

void main() {
  testWidgets('AppStartupScreen shows error details when bootstrap fails', (tester) async {
    const errorMessage = 'Supabase env missing.';

    await tester.pumpWidget(
      const MaterialApp(
        home: AppBootstrapScope(
          state: AppStartupState.error(errorMessage),
          child: AppStartupScreen(),
        ),
      ),
    );

    expect(find.text('App startup failed'), findsOneWidget);
    expect(find.text(errorMessage), findsOneWidget);
  });

  testWidgets('AppStartupScreen shows loading state when initializing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppBootstrapScope(
          state: AppStartupState.initial(),
          child: AppStartupScreen(),
        ),
      ),
    );

    expect(find.text('Starting...'), findsOneWidget);
  });
}
