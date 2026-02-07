import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/quiz_models.dart';

class QuizRepository {
  QuizRepository(this._client);

  final SupabaseClient _client;

  Future<SurahProgress?> fetchSurahProgress({
    required String childId,
    required int surahId,
  }) async {
    final response = await _client
        .from('surah_progress')
        .select('child_id, surah_id, stage, unlocked_ayah_max')
        .eq('child_id', childId)
        .eq('surah_id', surahId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return SurahProgress.fromJson(response);
  }

  Future<Map<String, dynamic>> submitQuiz({
    required String childId,
    required int surahId,
    required QuizType quizType,
    required List<QuizAnswerItem> answers,
  }) async {
    final accessToken = _client.auth.currentSession?.accessToken;
    final headers = (accessToken != null && accessToken.isNotEmpty)
        ? {'Authorization': 'Bearer $accessToken'}
        : null;

    final response = await _client.functions.invoke(
      'quiz_submit',
      headers: headers,
      body: {
        'child_id': childId,
        'surah_id': surahId,
        'quiz_type': quizType.apiValue,
        'answers': {'items': answers.map((item) => item.toJson()).toList()},
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is String) {
      return json.decode(data) as Map<String, dynamic>;
    }

    throw Exception('Unexpected response from quiz_submit.');
  }
}
