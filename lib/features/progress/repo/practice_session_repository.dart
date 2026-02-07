import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class PracticeSessionRepository {
  PracticeSessionRepository(this._client);

  final SupabaseClient _client;

  Future<String> startSession({required String childId}) async {
    final accessToken = _client.auth.currentSession?.accessToken;
    final headers = (accessToken != null && accessToken.isNotEmpty)
        ? {'Authorization': 'Bearer $accessToken'}
        : null;

    final response = await _client.functions.invoke(
      'session_start',
      headers: headers,
      body: {
        'child_id': childId,
      },
    );

    final data = response.data;
    Map<String, dynamic> payload;
    if (data is Map<String, dynamic>) {
      payload = data;
    } else if (data is String) {
      payload = json.decode(data) as Map<String, dynamic>;
    } else {
      throw Exception('Unexpected response from session_start.');
    }

    final sessionId = payload['session_id'] as String?;
    if (sessionId == null || sessionId.isEmpty) {
      throw Exception('session_start did not return session_id.');
    }
    return sessionId;
  }

  Future<void> endSession({required String childId, required String sessionId}) async {
    final accessToken = _client.auth.currentSession?.accessToken;
    final headers = (accessToken != null && accessToken.isNotEmpty)
        ? {'Authorization': 'Bearer $accessToken'}
        : null;

    final response = await _client.functions.invoke(
      'session_end',
      headers: headers,
      body: {
        'child_id': childId,
        'session_id': sessionId,
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return;
    }
    if (data is String) {
      json.decode(data);
      return;
    }

    throw Exception('Unexpected response from session_end.');
  }
}

