import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/providers/auth_session_provider.dart';
import '../../../core/supabase_client_provider.dart';
import '../models/child_profile.dart';
import '../repo/child_repository.dart';

const _selectedChildKey = 'selected_child_id';

final childRepositoryProvider = Provider<ChildRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ChildRepository(client);
});

final childrenProvider = FutureProvider<List<ChildProfile>>((ref) async {
  final session = await ref.watch(authSessionProvider.future);
  if (session == null) {
    return [];
  }
  final repo = ref.watch(childRepositoryProvider);
  return repo.fetchChildren();
});

final selectedChildIdProvider = StateNotifierProvider<SelectedChildController, AsyncValue<String?>>((ref) {
  return SelectedChildController();
});

class SelectedChildController extends StateNotifier<AsyncValue<String?>> {
  SelectedChildController() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AsyncValue.data(prefs.getString(_selectedChildKey));
  }

  Future<void> selectChild(String childId) async {
    state = AsyncValue.data(childId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedChildKey, childId);
  }

  Future<void> clear() async {
    state = const AsyncValue.data(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedChildKey);
  }
}

final selectedChildProvider = Provider<ChildProfile?>((ref) {
  final childrenAsync = ref.watch(childrenProvider);
  final selectedIdAsync = ref.watch(selectedChildIdProvider);

  final children = childrenAsync.asData?.value ?? const <ChildProfile>[];
  final selectedId = selectedIdAsync.asData?.value;

  if (selectedId == null) {
    return null;
  }

  for (final child in children) {
    if (child.id == selectedId) {
      return child;
    }
  }
  return null;
});
