import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/quiz_models.dart';

class QuizRecitationRepository {
  QuizRecitationRepository(this._client);

  final SupabaseClient _client;

  String buildStoragePath({required int surahId, required QuizType quizType}) {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final randomSuffix = DateTime.now().microsecondsSinceEpoch.toRadixString(
      36,
    );
    return 'quiz/surah_$surahId/${quizType.apiValue}/${timestamp}_$randomSuffix.m4a';
  }

  Future<String> uploadRecitation({
    required String localPath,
    required String storagePath,
  }) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception('Audio file not found.');
    }

    await _client.storage
        .from('recitations')
        .upload(
          storagePath,
          file,
          fileOptions: const FileOptions(contentType: 'audio/m4a'),
        );

    return storagePath;
  }

  Future<Map<String, dynamic>> submitLevelRecitation({
    required String childId,
    required int surahId,
    required QuizType quizType,
    required String audioPath,
    Map<String, dynamic>? meta,
  }) async {
    final accessToken = _client.auth.currentSession?.accessToken;
    final headers = (accessToken != null && accessToken.isNotEmpty)
        ? {'Authorization': 'Bearer $accessToken'}
        : null;

    final response = await _client.functions.invoke(
      'level_recitation_submit',
      headers: headers,
      body: {
        'child_id': childId,
        'surah_id': surahId,
        'quiz_type': quizType.apiValue,
        'audio_path': audioPath,
        if (meta != null) 'meta': meta,
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is String) {
      return json.decode(data) as Map<String, dynamic>;
    }

    throw Exception('Unexpected response from level_recitation_submit.');
  }
}
