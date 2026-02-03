import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_startup_state.dart';

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key, required this.child});

  final Widget child;

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  AppStartupState _state = const AppStartupState.initial();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (error) {
      setState(() {
        _state = AppStartupState.error('Missing .env file. Add SUPABASE_URL and SUPABASE_ANON_KEY.');
      });
      return;
    }

    final supabaseUrl = dotenv.env['SUPABASE_URL']?.trim();
    final anonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim();

    if (supabaseUrl == null || supabaseUrl.isEmpty || anonKey == null || anonKey.isEmpty) {
      setState(() {
        _state = AppStartupState.error('Supabase env missing. Set SUPABASE_URL and SUPABASE_ANON_KEY.');
      });
      return;
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: anonKey,
      );
      setState(() {
        _state = const AppStartupState.ready();
      });
    } catch (error) {
      setState(() {
        _state = AppStartupState.error('Supabase init failed: $error');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBootstrapScope(state: _state, child: widget.child);
  }
}

class AppBootstrapScope extends InheritedWidget {
  const AppBootstrapScope({super.key, required this.state, required super.child});

  final AppStartupState state;

  static AppBootstrapScope of(BuildContext context) {
    final AppBootstrapScope? scope =
        context.dependOnInheritedWidgetOfExactType<AppBootstrapScope>();
    assert(scope != null, 'AppBootstrapScope not found in widget tree');
    return scope!;
  }

  bool get isReady => state.status == AppStartupStatus.ready;
  bool get hasError => state.status == AppStartupStatus.error;
  String? get errorMessage => state.message;

  @override
  bool updateShouldNotify(covariant AppBootstrapScope oldWidget) {
    return state != oldWidget.state;
  }
}
