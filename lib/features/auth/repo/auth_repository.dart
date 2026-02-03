import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/simulated_auth_password.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> sendOtp({
    required String email,
    required bool shouldCreateUser,
  }) async {
    final password = buildSimulatedPassword(email);
    if (shouldCreateUser) {
      try {
        await _client.auth.signUp(
          email: email,
          password: password,
        );
        return;
      } on AuthException catch (error) {
        final message = error.message.toLowerCase();
        final alreadyExists = message.contains('already') ||
            message.contains('registered') ||
            message.contains('exists');
        if (!alreadyExists) {
          rethrow;
        }
      }
    }

    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  }) async {
    return _client.auth.signInWithPassword(
      email: email,
      password: buildSimulatedPassword(email),
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> upsertProfile({String? displayName}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return;
    }

    final payload = <String, dynamic>{
      'id': user.id,
      if (displayName != null && displayName.trim().isNotEmpty)
        'display_name': displayName.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _client.from('profiles').upsert(payload);
  }
}
