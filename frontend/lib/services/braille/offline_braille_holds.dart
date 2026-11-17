import 'formula_braille_guard.dart';

/// Extra on-device holds for formulas whose Braille would read as a
/// different formula. Found in the readiness pass of 2026-11-17 by running
/// worksheet formulas through the same normalizer and Liblouis tables the
/// app uses. Online has the same problems; these rules are not in the
/// shared (online + on-device) guard yet, so they live here.
///
/// Each one only holds a block (no Braille, readable text and a reason);
/// no Braille that is shown changes.
abstract final class OfflineBrailleHolds {
  static const String relationSign = 'relation_sign';
  static const String scriptGrouping = 'script_grouping';
  static const String setBraces = 'set_braces';

  /// ≠ ≤ ≥ ≈ are rewritten to "!=", "<=", ">=", "~=" before the Nemeth
  /// table, which reads "a != 0" as "a! = 0" (factorial, then equals) and
  /// "x <= 3" as two signs, "less than" and "equals".
  static const String relationSignReason =
      'contains ≠, ≤, ≥ or ≈: this sign does not come out right in Braille '
      'yet';

  /// Braces around an exponent or subscript are dropped before the Nemeth
  /// table, so x^{n+1} and x^{n}+1, 2^{3}4 and 2^{34}, or \log_{2}8 and
  /// \log_{28} give the same Braille.
  static const String scriptGroupingReason =
      'where an exponent or subscript ends is lost in Braille, so it could be '
      'read as a different formula';

  /// \{ \} become ( ) before the Nemeth table: a set reads as a group.
  static const String setBracesReason =
      'contains set braces { }: they would come out as parentheses';

  static final RegExp _relation = RegExp(
    r'\\(?:neq|ne|leq|le|geq|ge|leqslant|geqslant|approx|nleq|ngeq)'
    r'(?![A-Za-z])|[≠≤≥≈]',
  );

  static final RegExp _setBrace = RegExp(r'\\[{}]|\\[lr]brace(?![A-Za-z])');

  static final RegExp _scriptStart = RegExp(r'[\^_]\s*\{');

  /// What BrailleMathNormalizer writes without brackets (Python and
  /// Kotlin: SIMPLE_SCRIPT / [A-Za-z0-9+-]+).
  static final RegExp _flattened = RegExp(r'^[A-Za-z0-9+\-]+$');

  static final RegExp _plainNumber = RegExp(r'^-?\d+$');

  /// Whether [latex] (the formula model's LaTeX) must be held, and why.
  static FormulaReview review(String latex) {
    final List<(String, String)> findings = <(String, String)>[];

    if (_relation.hasMatch(latex)) {
      findings.add((relationSign, relationSignReason));
    }

    if (_losesScriptGrouping(latex)) {
      findings.add((scriptGrouping, scriptGroupingReason));
    }

    if (_setBrace.hasMatch(latex)) {
      findings.add((setBraces, setBracesReason));
    }

    if (findings.isEmpty) {
      return FormulaReview.none;
    }

    return FormulaReview(
      needsReview: true,
      categories: <String>[for (final (String, String) f in findings) f.$1],
      reason: <String>[for (final (String, String) f in findings) f.$2].join(
        '; ',
      ),
    );
  }

  /// True when a braced exponent or subscript is written without its
  /// braces and could then be read as a different formula:
  /// - it has more than one character and anything follows it, or it has
  ///   an operator inside (x^{n+1} = x^n+1 = x^{n}+1), except a plain
  ///   number at the very end (2^{10}, 10^{-3});
  /// - it has one character and a digit follows (2^{3}4 = 2^34).
  static bool _losesScriptGrouping(String latex) {
    for (final RegExpMatch match in _scriptStart.allMatches(latex)) {
      final int open = match.end - 1;
      final int? close = _closingBrace(latex, open);

      if (close == null) {
        continue;
      }

      final String inner = latex.substring(open + 1, close).replaceAll(' ', '');

      if (inner.isEmpty || !_flattened.hasMatch(inner)) {
        // Written with brackets, e.g. ^(2x+1): its end is kept.
        continue;
      }

      final String rest = latex.substring(close + 1).trimLeft();
      final String following = rest.replaceFirst(
        RegExp(r'^(?:\\right)?[)\]}|.]*'),
        '',
      );

      if (inner.length > 1) {
        final bool hasOperator = inner.substring(1).contains(RegExp('[+-]'));
        final bool plainNumberAtEnd =
            following.isEmpty && _plainNumber.hasMatch(inner);

        if (hasOperator || !plainNumberAtEnd) {
          return true;
        }
      } else if (RegExp(r'^\d').hasMatch(rest)) {
        return true;
      }
    }

    return false;
  }

  static int? _closingBrace(String text, int open) {
    int depth = 0;

    for (int index = open; index < text.length; index++) {
      final String character = text[index];

      if (character == '\\') {
        index++;
        continue;
      }

      if (character == '{') {
        depth++;
      } else if (character == '}') {
        depth--;

        if (depth == 0) {
          return index;
        }
      }
    }

    return null;
  }
}
