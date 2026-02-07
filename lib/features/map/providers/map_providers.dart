import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase_client_provider.dart';
import '../../child/providers/child_providers.dart';
import '../models/map_models.dart';
import '../repo/map_repository.dart';

final mapRepositoryProvider = Provider<MapRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return MapRepository(client);
});

final mapStateProvider = FutureProvider<MapState?>((ref) async {
  final child = ref.watch(selectedChildProvider);
  final childId = child?.id;
  if (childId == null || childId.isEmpty) {
    return null;
  }
  final repo = ref.watch(mapRepositoryProvider);
  return repo.fetchMapState(childId: childId);
});

