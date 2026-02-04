class AyahContent {
  const AyahContent({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.meaning,
  });

  final int id;
  final String arabic;
  final String transliteration;
  final String translation;
  final String meaning;

  factory AyahContent.fromJson(Map<String, dynamic> json) {
    return AyahContent(
      id: (json['id'] as num).toInt(),
      arabic: json['arabic'] as String? ?? '',
      transliteration: json['transliteration'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
    );
  }
}
