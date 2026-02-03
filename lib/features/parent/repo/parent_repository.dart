import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

class ParentRepository {
  ParentRepository(this._client);

  final SupabaseClient _client;

  Future<ParentProfile?> fetchProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }

    final response = await _client
        .from('profiles')
        .select('id, display_name, pin_hash')
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return ParentProfile.fromJson(response);
  }

  Future<ParentProfile> upsertProfile({String? displayName}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Not authenticated');
    }

    final payload = <String, dynamic>{
      'id': user.id,
      if (displayName != null && displayName.trim().isNotEmpty)
        'display_name': displayName.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _client
        .from('profiles')
        .upsert(payload)
        .select('id, display_name, pin_hash')
        .single();

    return ParentProfile.fromJson(response);
  }

  Future<ParentProfile> updatePinHash(String pinHash) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Not authenticated');
    }

    final response = await _client
        .from('profiles')
        .upsert({
          'id': user.id,
          'pin_hash': pinHash,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select('id, display_name, pin_hash')
        .single();

    return ParentProfile.fromJson(response);
  }
}
