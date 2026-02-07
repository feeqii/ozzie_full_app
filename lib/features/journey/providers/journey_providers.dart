import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase_client_provider.dart';
import '../../child/providers/child_providers.dart';
import '../models/journey_models.dart';
import '../repo/journey_repository.dart';

final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return JourneyRepository(client);
});

final surahLevelsProvider = FutureProvider.family<List<JourneyLevel>, int>((ref, surahId) async {
  final repo = ref.watch(journeyRepositoryProvider);
  return repo.fetchLevels(surahId: surahId);
});

final surahJourneyStepsProvider = FutureProvider.family<List<JourneyStep>, int>((ref, surahId) async {
  final child = ref.watch(selectedChildProvider);
  final childId = child?.id;
  if (childId == null || childId.isEmpty) {
    return const [];
  }

  final repo = ref.watch(journeyRepositoryProvider);
  final levels = await ref.watch(surahLevelsProvider(surahId).future);
  final levelIds = levels.map((level) => level.id).where((id) => id.isNotEmpty).toList();
  final progressRows = await repo.fetchProgress(childId: childId, levelIds: levelIds);
  final progressById = {for (final row in progressRows) row.levelId: row};

  return levels
      .map(
        (level) => JourneyStep(
          level: level,
          progress: progressById[level.id] ??
              JourneyProgress(
                levelId: level.id,
                status: JourneyLevelStatus.locked,
              ),
        ),
      )
      .toList();
});

