import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> sendOtp({
    required String email,
    required bool shouldCreateUser,
  }) async {
    await _client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: shouldCreateUser,
      emailRedirectTo: null,
    );
  }

  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  }) async {
    return _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
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
