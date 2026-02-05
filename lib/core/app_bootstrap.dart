import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
    final session = client.auth.currentSession;
    final token = session?.accessToken;
    if (token != null && token.isNotEmpty) {
      client.functions.setAuth(token);
    } else {
      client.functions.setAuth(anonKey);
    }

    _authStateSubscription?.cancel();
    _authStateSubscription = client.auth.onAuthStateChange.listen((data) {
      final nextToken = data.session?.accessToken;
      if (nextToken != null && nextToken.isNotEmpty) {
        client.functions.setAuth(nextToken);
      } else {
        client.functions.setAuth(anonKey);
      }
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

class _LoggingHttpClient extends http.BaseClient {
  _LoggingHttpClient(this._inner, this._getAccessToken);

  final http.Client _inner;
  final String? Function() _getAccessToken;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final isFunctionCall = request.url.path.contains('/functions/v1/');
    if (isFunctionCall) {
      final authHeader = request.headers['Authorization'] ?? request.headers['authorization'];
      final hasBearer = authHeader != null && authHeader.startsWith('Bearer ');
      final token = hasBearer ? authHeader.substring('Bearer '.length) : null;
      final sessionToken = _getAccessToken();
      final matchesSession = token != null && sessionToken != null && token == sessionToken;
      debugPrint(
        '[FunctionsHTTP] ${request.method} ${request.url} '
        'auth=${hasBearer ? 'bearer' : authHeader == null ? 'missing' : 'present'} '
        'matchesSession=$matchesSession apikey=${request.headers.containsKey('apikey')}',
      );
    }
    return _inner.send(request);
  }
}
