import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final supabaseUrl = const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://ymxgbycnbjwfmsfgvcms.supabase.co',
    ).trim();
    final anonKey = const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlteGdieWNuYmp3Zm1zZmd2Y21zIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAwMzU0NjcsImV4cCI6MjA4NTYxMTQ2N30.vwaCDI56Js3OatRwL9PN2QwJJmKY1n9chSSE8Fb2TF4',
    ).trim();

    if (supabaseUrl.isEmpty || anonKey.isEmpty) {
      setState(() {
        _state = AppStartupState.error(
          'Supabase config missing. Set SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define.',
        );
      });
      return;
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: anonKey,
        httpClient: _LoggingHttpClient(
          http.Client(),
          () => Supabase.instance.client.auth.currentSession?.accessToken,
        ),
      );
      _syncFunctionsAuth(anonKey);
      setState(() {
        _state = const AppStartupState.ready();
      });
    } catch (error) {
      setState(() {
        _state = AppStartupState.error('Supabase init failed: $error');
      });
    }
  }

  void _syncFunctionsAuth(String anonKey) {
    final client = Supabase.instance.client;
    client.functions.setAuth(anonKey);

    _authStateSubscription?.cancel();
    _authStateSubscription = client.auth.onAuthStateChange.listen((_) {
      // Keep edge-layer auth set to anon for verify_jwt checks.
      client.functions.setAuth(anonKey);
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBootstrapScope(state: _state, child: widget.child);
  }
}

class AppBootstrapScope extends InheritedWidget {
  const AppBootstrapScope({
    super.key,
    required this.state,
    required super.child,
  });

  final AppStartupState state;

  static AppBootstrapScope of(BuildContext context) {
    final AppBootstrapScope? scope = context
        .dependOnInheritedWidgetOfExactType<AppBootstrapScope>();
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

class _LoggingHttpClient extends http.BaseClient {
  _LoggingHttpClient(this._inner, this._getAccessToken);

  static const bool _functionsHttpLoggingEnabled = bool.fromEnvironment(
    'LOG_FUNCTIONS_HTTP',
    defaultValue: false,
  );

  final http.Client _inner;
  final String? Function() _getAccessToken;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final isFunctionCall = request.url.path.contains('/functions/v1/');
    if (isFunctionCall && _functionsHttpLoggingEnabled) {
      final authHeader =
          request.headers['Authorization'] ?? request.headers['authorization'];
      final hasBearer = authHeader != null && authHeader.startsWith('Bearer ');
      final token = hasBearer ? authHeader.substring('Bearer '.length) : null;
      final sessionToken = _getAccessToken();
      final matchesSession =
          token != null && sessionToken != null && token == sessionToken;
      debugPrint(
        '[FunctionsHTTP] ${request.method} ${request.url} '
        'auth=${hasBearer
            ? 'bearer'
            : authHeader == null
            ? 'missing'
            : 'present'} '
        'matchesSession=$matchesSession apikey=${request.headers.containsKey('apikey')}',
      );
    }
    return _inner.send(request);
  }
}
