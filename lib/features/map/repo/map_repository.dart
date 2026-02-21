import 'dart:async';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/map_models.dart';

class MapRepository {
  MapRepository(this._client);

  final SupabaseClient _client;
  static const Duration _requestTimeout = Duration(seconds: 12);

  Map<String, String>? get _authHeaders {
    final accessToken = _client.auth.currentSession?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }
    return {'x-user-jwt': 'Bearer $accessToken'};
  }

  Future<MapState> fetchMapState({required String childId}) async {
    final response = await _client.functions
        .invoke(
          'get_map_state',
          headers: _authHeaders,
          body: {'child_id': childId},
        )
        .timeout(
          _requestTimeout,
          onTimeout: () => throw TimeoutException('get_map_state timed out'),
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

  Future<void> startSurah({
    required String childId,
    required int surahId,
  }) async {
    final response = await _client.functions
        .invoke(
          'start_surah',
          headers: _authHeaders,
          body: {'child_id': childId, 'surah_id': surahId},
        )
        .timeout(
          _requestTimeout,
          onTimeout: () => throw TimeoutException('start_surah timed out'),
        );

    if (response.status != 200) {
      throw Exception('start_surah failed: ${response.data}');
    }
  }

  Future<void> completeLevel({
    required String childId,
    required String levelId,
  }) async {
    final response = await _client.functions
        .invoke(
          'level_complete',
          headers: _authHeaders,
          body: {'child_id': childId, 'level_id': levelId},
        )
        .timeout(
          _requestTimeout,
          onTimeout: () => throw TimeoutException('level_complete timed out'),
        );

    if (response.status != 200) {
      throw Exception('level_complete failed: ${response.data}');
    }
  }
}
