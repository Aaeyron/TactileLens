import 'formula_braille_guard.dart';

/// On-device holds that come with the agreement check (two formula models).
/// Each one only holds a block: no Braille, the readable text and a reason.
/// No Braille that is shown changes.
///
/// Measured on 40 held-out worksheet pages on the phone (2026-11-21):
/// wrong Braille shown without a hold went from 44 formulas to 34 with the
/// word hold alone, and to 2 with the agreement check; correctly shown
/// formulas went from 40 to 31.
abstract final class OfflineAgreementHolds {
  static const String readingsDiffer = 'readings_differ';
  static const String lostTextWords = 'lost_text_words';

  /// The app's formula model and the check model read this formula
  /// differently, so at least one of them is wrong.
  static const String readingsDifferReason =
      'the two formula readings differ: check it against the printed page';

  /// Printed words inside the formula lost their text marking, so their
  /// letters would be read as math variables (for example "a n d").
  static const String lostTextWordsReason =
      'has words that were read as single letters in the math';

  static const Set<String> _commonWords = <String>{
    'and',
    'or',
    'if',
    'then',
    'for',
    'all',
    'where',
    'when',
    'with',
    'the',
    'is',
    'are',
    'not',
    'real',
    'number',
    'numbers',
    'reason',
    'so',
    'thus',
    'hence',
    'let',
    'find',
    'solve',
    'true',
    'false',
    'yes',
    'no',
    'any',
    'each',
    'some',
    'only',
    'otherwise',
    'since',
    'because',
    'but',
    'of',
    'in',
    'on',
    'at',
    'to',
    'by',
    'as',
    'be',
    'an',
  };

  /// Three or more single letters separated by spaces, not part of a command
  /// or a longer word.
  static final RegExp _spaced = RegExp(
    r'(?<![\\A-Za-z])([A-Za-z])((?:[ ~]+[A-Za-z]){2,})(?![A-Za-z])',
  );

  /// The words in [latex] that lost their \text marking ("a n d" -> "and").
  /// A run of four or more letters always counts; three letters only when
  /// they spell a common word, so products such as "x y z" are not held.
  static List<String> lostWords(String latex) {
    final List<String> words = <String>[];

    for (final RegExpMatch match in _spaced.allMatches(latex)) {
      final String word = '${match.group(1)}${match.group(2)}'
          .replaceAll(' ', '')
          .replaceAll('~', '');

      if (word.length >= 4 || _commonWords.contains(word.toLowerCase())) {
        words.add(word);
      }
    }

    return words;
  }

  /// Whether a formula block must be held. [readingsAgree] is the
  /// pipeline's agreement result; null means the check did not run, which
  /// does not hold the block on its own.
  static FormulaReview review(String latex, {bool? readingsAgree}) {
    final List<(String, String)> findings = <(String, String)>[];

    if (readingsAgree == false) {
      findings.add((readingsDiffer, readingsDifferReason));
    }

    if (lostWords(latex).isNotEmpty) {
      findings.add((lostTextWords, lostTextWordsReason));
    }

    if (findings.isEmpty) {
      return FormulaReview.none;
    }

    return FormulaReview(
      needsReview: true,
      categories: <String>[for (final (String c, String _) in findings) c],
      reason: <String>[
        for (final (String _, String r) in findings) r,
      ].join('; '),
    );
  }
}
