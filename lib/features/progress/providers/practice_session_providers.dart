import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase_client_provider.dart';
import '../repo/practice_session_repository.dart';
import 'practice_session_controller.dart';

final practiceSessionRepositoryProvider = Provider<PracticeSessionRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PracticeSessionRepository(client);
});

final practiceSessionControllerProvider =
    StateNotifierProvider<PracticeSessionController, PracticeSessionState>((ref) {
  final repo = ref.watch(practiceSessionRepositoryProvider);
  return PracticeSessionController(ref, repo);
});

