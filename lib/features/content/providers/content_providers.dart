import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/surah_content.dart';
import '../models/surah_summary.dart';
import '../repo/content_repository.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return const ContentRepository();
});

final surahSummariesProvider = FutureProvider<List<SurahSummary>>((ref) async {
  final repo = ref.watch(contentRepositoryProvider);
  return repo.fetchSurahSummaries();
});

final surahContentProvider = FutureProvider.family<SurahContent, int>((ref, surahId) async {
  final repo = ref.watch(contentRepositoryProvider);
  return repo.fetchSurahContent(surahId);
});
