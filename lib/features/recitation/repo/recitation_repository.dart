import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class RecitationRepository {
  RecitationRepository(this._client);

  final SupabaseClient _client;

  Future<String> uploadRecitation({
    required String localPath,
    required String storagePath,
  }) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception('Audio file not found.');
    }

    await _client.storage.from('recitations').upload(
          storagePath,
          file,
          fileOptions: const FileOptions(contentType: 'audio/m4a'),
        );

    return storagePath;
  }

  String buildStoragePath({
    required int surahId,
    required int ayahId,
  }) {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final randomSuffix = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return 'surah_$surahId/ayah_$ayahId/${timestamp}_$randomSuffix.m4a';
  }

  Future<Map<String, dynamic>> submitRecitation({
    required String childId,
    required int surahId,
    required int ayahId,
    required String audioPath,
    int? score,
    String? transcript,
    String? model,
    Map<String, dynamic>? meta,
  }) async {
    final accessToken = _client.auth.currentSession?.accessToken;
    final headers = (accessToken != null && accessToken.isNotEmpty)
        ? {'Authorization': 'Bearer $accessToken'}
        : null;

    final response = await _client.functions.invoke(
      'recitation_submit',
      headers: headers,
      body: {
        'child_id': childId,
        'surah_id': surahId,
        'ayah_id': ayahId,
        'audio_path': audioPath,
        if (score != null) 'score': score,
        if (transcript != null) 'transcript': transcript,
        if (model != null) 'model': model,
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

    throw Exception('Unexpected response from recitation_submit.');
  }
}
