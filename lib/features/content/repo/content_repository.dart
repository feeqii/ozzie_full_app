import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/surah_content.dart';
import '../models/surah_summary.dart';

class ContentRepository {
  const ContentRepository();

  Future<List<SurahSummary>> fetchSurahSummaries() async {
    final raw = await rootBundle.loadString('assets/content/surah_list.json');
    final jsonData = json.decode(raw) as Map<String, dynamic>;
    final list = (jsonData['surahs'] as List<dynamic>? ?? [])
        .map((item) => SurahSummary.fromJson(item as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<SurahContent> fetchSurahContent(int surahId) async {
    final raw = await rootBundle.loadString('assets/content/surah_$surahId.json');
    final jsonData = json.decode(raw) as Map<String, dynamic>;
    return SurahContent.fromJson(jsonData);
  }
}
