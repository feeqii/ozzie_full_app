import 'package:flutter_test/flutter_test.dart';

import 'package:ozzie/features/recitation/services/arabic_similarity.dart';

void main() {
  test('normalizeArabic strips diacritics and tatweel', () {
    const input = 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيمِ';
    final normalized = normalizeArabic(input);
    expect(normalized.contains('ِ'), false);
    expect(normalized.contains('ٰ'), false);
  });

  test('normalizeArabic normalizes alef variants', () {
    const input = 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ';
    final normalized = normalizeArabic(input);
    expect(normalized.contains('إ'), false);
    expect(normalized.contains('أ'), false);
    expect(normalized.contains('آ'), false);
  });

  test('computeSimilarityScore returns 100 for identical text', () {
    const text = 'الحمد لله رب العالمين';
    expect(computeSimilarityScore(text, text), 100);
  });

  test('computeSimilarityScore returns 0 for empty transcript', () {
    const ref = 'الحمد لله رب العالمين';
    expect(computeSimilarityScore('', ref), 0);
  });
}
