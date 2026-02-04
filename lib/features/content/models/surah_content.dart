import 'ayah_content.dart';

class SurahContent {
  const SurahContent({
    required this.id,
    required this.name,
    required this.translation,
    required this.ayahs,
  });

  final int id;
  final String name;
  final String translation;
  final List<AyahContent> ayahs;

  factory SurahContent.fromJson(Map<String, dynamic> json) {
    final ayahList = (json['ayahs'] as List<dynamic>? ?? [])
        .map((item) => AyahContent.fromJson(item as Map<String, dynamic>))
        .toList();

    return SurahContent(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      ayahs: ayahList,
    );
  }
}
