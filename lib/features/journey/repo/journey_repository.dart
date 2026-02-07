import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/journey_models.dart';

class JourneyRepository {
  JourneyRepository(this._client);

  final SupabaseClient _client;

  Future<List<JourneyLevel>> fetchLevels({required int surahId}) async {
    final response = await _client
        .from('levels')
        .select('id, surah_id, type, order_index, ayah_id, checkpoint_index, config')
        .eq('surah_id', surahId)
        .order('order_index');

    final rows = (response as List).cast<Map<String, dynamic>>();
    return rows.map(JourneyLevel.fromJson).toList();
  }

  Future<List<JourneyProgress>> fetchProgress({
    required String childId,
    required List<String> levelIds,
  }) async {
    if (levelIds.isEmpty) {
      return const [];
    }

    final response = await _client
        .from('child_level_progress')
        .select('level_id, status, locked_until, attempts_today, pass_count_total, last_score, completed_at')
        .eq('child_id', childId)
        .inFilter('level_id', levelIds);

    final rows = (response as List).cast<Map<String, dynamic>>();
    return rows.map(JourneyProgress.fromJson).toList();
  }
}

