import 'dart:math';

final _diacriticsRegex = RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]');
final _nonArabicRegex = RegExp(r'[^\u0600-\u06FF\s]');
final _tatweelRegex = RegExp(r'\u0640');
final _whitespaceRegex = RegExp(r'\s+');

String normalizeArabic(String input) {
  var text = input;
  text = text.replaceAll(_diacriticsRegex, '');
  text = text.replaceAll(_tatweelRegex, '');
  text = text.replaceAll(_nonArabicRegex, '');
  text = text
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ٱ', 'ا')
      .replaceAll('ى', 'ي');
  text = text.replaceAll(_whitespaceRegex, ' ').trim();
  return text;
}

int computeSimilarityScore(String transcript, String reference) {
  final a = normalizeArabic(transcript);
  final b = normalizeArabic(reference);
  if (a.isEmpty || b.isEmpty) {
    return 0;
  }
  final dist = _levenshtein(a, b);
  final maxLen = max(a.length, b.length);
  if (maxLen == 0) {
    return 0;
  }
  final similarity = 1 - (dist / maxLen);
  return (similarity * 100).round().clamp(0, 100);
}

int _levenshtein(String s, String t) {
  final m = s.length;
  final n = t.length;
  if (m == 0) return n;
  if (n == 0) return m;

  final prev = List<int>.generate(n + 1, (i) => i);
  final curr = List<int>.filled(n + 1, 0);

  for (var i = 1; i <= m; i++) {
    curr[0] = i;
    final sChar = s.codeUnitAt(i - 1);
    for (var j = 1; j <= n; j++) {
      final cost = sChar == t.codeUnitAt(j - 1) ? 0 : 1;
      curr[j] = [
        curr[j - 1] + 1,
        prev[j] + 1,
        prev[j - 1] + cost,
      ].reduce(min);
    }
    for (var j = 0; j <= n; j++) {
      prev[j] = curr[j];
    }
  }
  return prev[n];
}
