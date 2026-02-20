import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/child_profile.dart';

class ChildRepository {
  ChildRepository(this._client);

  final SupabaseClient _client;

  Future<List<ChildProfile>> fetchChildren() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Not authenticated');
    }

    final response = await _client
        .from('children')
        .select('id, parent_id, name, avatar_key, birth_year, gender')
        .eq('parent_id', user.id)
        .order('created_at');

    return response
        .map<ChildProfile>((row) => ChildProfile.fromJson(row))
        .toList();
  }

  Future<ChildProfile> addChild({
    required String name,
    int? birthYear,
    String? gender,
    String? avatarKey,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Not authenticated');
    }

    final response = await _client
        .from('children')
        .insert({
          'parent_id': user.id,
          'name': name.trim(),
          if (birthYear != null) 'birth_year': birthYear,
          if (gender != null) 'gender': gender,
          if (avatarKey != null) 'avatar_key': avatarKey,
        })
        .select('id, parent_id, name, avatar_key, birth_year, gender')
        .single();

    return ChildProfile.fromJson(response);
  }

  Future<void> ensureChildSettings(String childId) async {
    await _client.from('child_settings').upsert({
      'child_id': childId,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<ChildProfile> updateChild({
    required String childId,
    String? name,
    int? birthYear,
    String? gender,
    String? avatarKey,
  }) async {
    final payload = <String, dynamic>{};

    if (name != null && name.trim().isNotEmpty) {
      payload['name'] = name.trim();
    }
    if (birthYear != null) {
      payload['birth_year'] = birthYear;
    }
    if (gender != null) {
      payload['gender'] = gender;
    }
    if (avatarKey != null) {
      payload['avatar_key'] = avatarKey;
    }

    final response = await _client
        .from('children')
        .update(payload)
        .eq('id', childId)
        .select('id, parent_id, name, avatar_key, birth_year, gender')
        .single();

    return ChildProfile.fromJson(response);
  }

  Future<void> deleteChild(String childId) async {
    await _client.from('children').delete().eq('id', childId);
  }
}
