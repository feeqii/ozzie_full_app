import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/map_models.dart';

class MapRepository {
  MapRepository(this._client);

  final SupabaseClient _client;

  Future<MapState> fetchMapState({required String childId}) async {
    final accessToken = _client.auth.currentSession?.accessToken;
    final headers = (accessToken != null && accessToken.isNotEmpty)
        ? {'Authorization': 'Bearer $accessToken'}
        : null;

    final response = await _client.functions.invoke(
      'get_map_state',
      headers: headers,
      body: {'child_id': childId},
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return MapState.fromJson(data);
    }
    if (data is String) {
      return MapState.fromJson(json.decode(data) as Map<String, dynamic>);
    }
    throw Exception('Unexpected response from get_map_state.');
  }

  Future<void> startSurah({required String childId, required int surahId}) async {
    final accessToken = _client.auth.currentSession?.accessToken;
    final headers = (accessToken != null && accessToken.isNotEmpty)
        ? {'Authorization': 'Bearer $accessToken'}
        : null;

    final response = await _client.functions.invoke(
      'start_surah',
      headers: headers,
      body: {'child_id': childId, 'surah_id': surahId},
    );

    if (response.status != 200) {
      throw Exception('start_surah failed: ${response.data}');
    }
  }

  Future<void> completeLevel({required String childId, required String levelId}) async {
    final accessToken = _client.auth.currentSession?.accessToken;
    final headers = (accessToken != null && accessToken.isNotEmpty)
        ? {'Authorization': 'Bearer $accessToken'}
        : null;

    final response = await _client.functions.invoke(
      'level_complete',
      headers: headers,
      body: {'child_id': childId, 'level_id': levelId},
    );

    if (response.status != 200) {
      throw Exception('level_complete failed: ${response.data}');
    }
  }
}

