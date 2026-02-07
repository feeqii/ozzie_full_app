import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase_client_provider.dart';
import '../../child/providers/child_providers.dart';
import '../models/quiz_models.dart';
import '../repo/quiz_repository.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return QuizRepository(client);
});

final surahProgressProvider = FutureProvider.family<SurahProgress?, int>((
  ref,
  surahId,
) async {
  final childId = ref.watch(selectedChildProvider)?.id;
  if (childId == null || childId.isEmpty) {
    return null;
  }
  final repo = ref.watch(quizRepositoryProvider);
  return repo.fetchSurahProgress(childId: childId, surahId: surahId);
});
