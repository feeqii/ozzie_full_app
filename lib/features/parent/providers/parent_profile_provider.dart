import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase_client_provider.dart';
import '../../auth/providers/auth_session_provider.dart';
import '../models/profile.dart';
import '../repo/parent_repository.dart';

final parentRepositoryProvider = Provider<ParentRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ParentRepository(client);
});

final parentProfileProvider = FutureProvider<ParentProfile?>((ref) async {
  final session = await ref.watch(authSessionProvider.future);
  if (session == null) {
    return null;
  }
  final repo = ref.watch(parentRepositoryProvider);
  final profile = await repo.fetchProfile();
  if (profile != null) {
    return profile;
  }

  try {
    return await repo.upsertProfile();
  } catch (_) {
    return null;
  }
});

final pinVerifiedProvider = StateProvider<bool>((ref) => false);

class PinAttemptState {
  const PinAttemptState({
    this.remaining = 5,
    this.cooldownUntil,
  });

  final int remaining;
  final DateTime? cooldownUntil;

  PinAttemptState copyWith({
    int? remaining,
    DateTime? cooldownUntil,
  }) {
    return PinAttemptState(
      remaining: remaining ?? this.remaining,
      cooldownUntil: cooldownUntil ?? this.cooldownUntil,
    );
  }
}

class PinAttemptController extends StateNotifier<PinAttemptState> {
  PinAttemptController() : super(const PinAttemptState());

  void registerFailure() {
    final nextRemaining = state.remaining - 1;
    if (nextRemaining <= 0) {
      state = PinAttemptState(
        remaining: 5,
        cooldownUntil: DateTime.now().add(const Duration(seconds: 30)),
      );
      return;
    }
    state = state.copyWith(remaining: nextRemaining);
  }

  void reset() {
    state = const PinAttemptState();
  }

  bool get isCoolingDown {
    final until = state.cooldownUntil;
    if (until == null) {
      return false;
    }
    return DateTime.now().isBefore(until);
  }
}

final pinAttemptProvider = StateNotifierProvider<PinAttemptController, PinAttemptState>((ref) {
  return PinAttemptController();
});
