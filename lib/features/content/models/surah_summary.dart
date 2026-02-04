class SurahSummary {
  const SurahSummary({
    required this.id,
    required this.name,
    required this.translation,
    required this.ayahCount,
    required this.summary,
  });

  final int id;
  final String name;
  final String translation;
  final int ayahCount;
  final String summary;

  factory SurahSummary.fromJson(Map<String, dynamic> json) {
    return SurahSummary(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      ayahCount: (json['ayah_count'] as num?)?.toInt() ?? 0,
      summary: json['summary'] as String? ?? '',
    );
  }
}
