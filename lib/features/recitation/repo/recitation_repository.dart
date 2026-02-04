import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class RecitationRepository {
  RecitationRepository(this._client);

  final SupabaseClient _client;

  Future<String> uploadRecitation({
    required String localPath,
    required String childId,
    required int surahId,
    required int ayahId,
  }) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception('Audio file not found.');
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final storagePath = '$childId/$surahId/$ayahId/$timestamp.m4a';

    await _client.storage.from('recitations').upload(
          storagePath,
          file,
          fileOptions: const FileOptions(contentType: 'audio/m4a'),
        );

    return storagePath;
  }

  Future<Map<String, dynamic>> submitRecitation({
    required String childId,
    required int surahId,
    required int ayahId,
    required String audioPath,
  }) async {
    final response = await _client.functions.invoke(
      'recitation_submit',
      body: {
        'child_id': childId,
        'surah_id': surahId,
        'ayah_id': ayahId,
        'audio_path': audioPath,
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
