/// Offline copy of the AI service's formula guard
/// (ai_service/services/braille/formula_braille_guard.py).
///
/// Decides whether an offline formula is safe to translate into Braille.
/// Unsupported LaTeX, alignment markup, English words mixed into the math
/// and roots are held for review: no Braille, the readable text and a
/// reason instead. Same categories and reason text as online.
///
/// The vocabulary and rules are copied, not shared at run time. Both test
/// suites check them against ai_service/services/braille/fixtures/
/// formula_guard_shared.json, so the two guards cannot drift apart.
///
/// One online check is not repeated here: "markup left after
/// normalization" looks at the server's normalized text, which the app
/// does not have. The Braille escape check (any cell with dot 7 or 8)
/// catches what that would have produced.
library;

class FormulaReview {
  const FormulaReview({
    this.needsReview = false,
    this.categories = const <String>[],
    this.reason = '',
  });

  final bool needsReview;
  final List<String> categories;
  final String reason;

  static const FormulaReview none = FormulaReview();
}

abstract final class FormulaBrailleGuard {
  static const String unsupportedLatex = 'unsupported_latex';
  static const String alignment = 'alignment';
  static const String englishText = 'english_text';
  static const String root = 'root';

  // Provisional thresholds, as online. Words are runs of ASCII letters;
  // LaTeX command names and function names never count.
  static const int longWordLength = 4;
  static const int shortWordLength = 3;
  static const int shortWordLimit = 2;
  static const int totalWordLimit = 6;
  static const int wordsInReason = 4;

  static const String rootSymbols = '√∛∜';
  static const String rootReason =
      'contains a root (√): Nemeth radical not yet confirmed';

  /// Any block, after translation: Liblouis writes a symbol its tables do
  /// not define as an escape such as '\x221b' in Braille cells, whose
  /// backslash is an 8-dot cell. UEB and Nemeth only use 6-dot cells.
  static const String unsupportedSymbol = 'unsupported_symbol';
  static const String unsupportedSymbolReason =
      "contains a symbol our Braille tables don't support";
  static const int _eightDotFirst = 0x2840;
  static const int _eightDotLast = 0x28FF;

  /// Whether Liblouis output contains a cell with dot 7 or 8.
  static bool containsBrailleEscape(String braille) {
    return braille.runes.any(
      (int cell) => cell >= _eightDotFirst && cell <= _eightDotLast,
    );
  }

  /// Every LaTeX command the Braille normalizer converts
  /// (BrailleMathNormalizer.SUPPORTED_COMMANDS in the AI service).
  static const Set<String> supportedCommands = <String>{
    'Big', 'Bigg', 'Biggl', 'Biggm', 'Biggr', 'Bigl', 'Bigm', 'Bigr', //
    'alpha', 'approx', 'beta', 'big', 'bigg', 'biggl', 'biggm', 'biggr',
    'bigl', 'bigm', 'bigr', 'cdot', 'delta', 'dfrac', 'div', 'frac',
    'gamma', 'ge', 'geq', 'infty', 'int', 'lambda', 'le', 'left', 'leq',
    'mathbf', 'mathit', 'mathrm', 'mbox', 'mp', 'mu', 'ne', 'neq',
    'operatorname', 'pi', 'pm', 'prime', 'prod', 'qquad', 'quad', 'right',
    'sigma', 'sqrt', 'sum', 'text', 'textbf', 'textit', 'textrm', 'tfrac',
    'theta', 'times',
  };

  /// Function names may stay as words; Liblouis reads them as written.
  static const Set<String> functionNames = <String>{
    'cos', 'cot', 'csc', 'exp', 'lim', 'ln', 'log', 'max', 'min', 'sec', //
    'sin', 'tan',
  };

  /// Environments whose rows and columns the normalizer linearises.
  static const Set<String> supportedEnvironments = <String>{
    'align', 'align*', 'aligned', 'gather', 'gathered', 'split', //
  };

  static final RegExp _textWrapper = RegExp(
    r'\\(?:text|textrm|textbf|textit|mbox|mathrm|operatorname)\s*\{',
  );
  static final RegExp _rowBreak = RegExp(r'\\\\');
  static final RegExp _environment = RegExp(r'\\(?:begin|end)\s*\{([^{}]*)\}');
  static final RegExp _command = RegExp(r'\\([A-Za-z]+)');
  static final RegExp _column = RegExp(r'(?<!\\)&');
  static final RegExp _word = RegExp('[A-Za-z]+');
  static final RegExp _root = RegExp(r'\\sqrt(?![A-Za-z])|[√∛∜]');

  // The normalizer's stacked-fraction step, which runs before the checks:
  // stacked fractions legitimately use rows and "array".
  static final RegExp _stackedArrayFraction = RegExp(
    r'\\left\s*\(\s*'
    r'\\begin\{array\}\{[^{}]*\}\s*'
    r'(.+?)\s*\\\\\s*(.+?)\s*'
    r'\\end\{array\}\s*'
    r'\\right\s*\)',
    dotAll: true,
  );
  static final RegExp _stackedDoubleSlashFraction = RegExp(
    r'\(\s*([A-Za-z0-9.+\- ]+?)\s*\\\\\s*([A-Za-z0-9.+\- ]+?)\s*\)',
  );
  static final RegExp _stackedSingleSlashFraction = RegExp(
    r'\(\s*([A-Za-z0-9.+\- ]+?)\s*\\(?![A-Za-z])\s*([A-Za-z0-9.+\- ]+?)\s*\)',
  );

  /// Whether [content] (LaTeX or Unicode) contains a root.
  static bool containsRoot(String content) => _root.hasMatch(content);

  /// Checks one offline formula block before it is sent to Liblouis.
  static FormulaReview review(String rawContent) {
    if (rawContent.trim().isEmpty) {
      return FormulaReview.none;
    }

    final String structure = _replaceStackedFractions(rawContent);
    final List<(String, String)> findings = <(String, String)>[];

    final List<String> unsupported = _unsupportedLatex(structure);

    if (unsupported.isNotEmpty) {
      findings.add((
        unsupportedLatex,
        'unsupported LaTeX: ${unsupported.join(', ')}',
      ));
    }

    if (_hasUnsupportedAlignment(structure)) {
      findings.add((alignment, r'alignment or row markup (& or \\)'));
    }

    final List<String> words = _englishWords(structure);

    if (words.isNotEmpty) {
      final String shown = words.take(wordsInReason).join(', ');
      final String more = words.length > wordsInReason ? ', ...' : '';
      findings.add((
        englishText,
        'contains English text (${words.length} words: $shown$more)',
      ));
    }

    if (containsRoot(rawContent)) {
      findings.add((root, rootReason));
    }

    if (findings.isEmpty) {
      return FormulaReview.none;
    }

    return FormulaReview(
      needsReview: true,
      categories: List<String>.unmodifiable(
        findings.map(((String, String) finding) => finding.$1),
      ),
      reason: findings.map(((String, String) finding) => finding.$2).join('; '),
    );
  }

  static String _replaceStackedFractions(String content) {
    String replaceFraction(Match match) {
      final String numerator = match.group(1)!.replaceAll('&', '').trim();
      final String denominator = match.group(2)!.replaceAll('&', '').trim();

      if (numerator.isEmpty || denominator.isEmpty) {
        return match.group(0)!;
      }

      return '($numerator)/($denominator)';
    }

    String normalized = content.replaceAllMapped(
      _stackedArrayFraction,
      replaceFraction,
    );
    normalized = normalized.replaceAllMapped(
      _stackedDoubleSlashFraction,
      replaceFraction,
    );
    return normalized.replaceAllMapped(
      _stackedSingleSlashFraction,
      replaceFraction,
    );
  }

  static List<String> _unsupportedLatex(String structure) {
    // Remove row breaks first so "\\x" is not read as the command "\x".
    final String text = structure.replaceAll(_rowBreak, ' ');

    final Set<String> environments = <String>{
      for (final Match match in _environment.allMatches(text))
        if (!supportedEnvironments.contains(match.group(1)!.trim()))
          match.group(1)!.trim(),
    };

    final Set<String> commands = <String>{
      for (final Match match in _command.allMatches(
        text.replaceAll(_environment, ' '),
      ))
        if (!supportedCommands.contains(match.group(1)) &&
            !functionNames.contains(match.group(1)))
          match.group(1)!,
    };

    return <String>[
      ...(commands.map((String name) => '\\$name').toList()..sort()),
      ...(environments.map((String name) => '$name environment').toList()
        ..sort()),
    ];
  }

  static bool _hasUnsupportedAlignment(String structure) {
    if (!_rowBreak.hasMatch(structure) && !_column.hasMatch(structure)) {
      return false;
    }

    final Set<String> environments = <String>{
      for (final Match match in _environment.allMatches(structure))
        match.group(1)!.trim(),
    };

    return environments.isEmpty ||
        !environments.every(supportedEnvironments.contains);
  }

  /// Words that look like English, outside then inside text wrappers.
  /// Empty when the thresholds are not reached.
  static List<String> _englishWords(String structure) {
    final (String outside, String inside) = _splitTextWrappers(structure);

    List<String> wordsOf(String text) {
      final String plain = text
          .replaceAll(_environment, ' ')
          .replaceAll(_command, ' ');

      return <String>[
        for (final Match match in _word.allMatches(plain))
          if (match.group(0)!.length >= shortWordLength &&
              !functionNames.contains(match.group(0)!.toLowerCase()))
            match.group(0)!,
      ];
    }

    final List<String> outsideWords = wordsOf(outside);
    final List<String> insideWords = wordsOf(inside);
    final List<String> allWords = <String>[...outsideWords, ...insideWords];

    final bool hasLongWord = outsideWords.any(
      (String word) => word.length >= longWordLength,
    );

    if (hasLongWord ||
        outsideWords.length >= shortWordLimit ||
        allWords.length >= totalWordLimit) {
      return allWords;
    }

    return const <String>[];
  }

  /// Splits LaTeX into the parts outside and inside \text{...} groups.
  static (String, String) _splitTextWrappers(String structure) {
    final List<String> outside = <String>[];
    final List<String> inside = <String>[];
    int index = 0;

    while (true) {
      final Match? match = _textWrapper
          .allMatches(structure, index)
          .firstOrNull;

      if (match == null) {
        outside.add(structure.substring(index));
        break;
      }

      outside.add(structure.substring(index, match.start));

      // match.end is just past the opening brace.
      int depth = 1;
      int position = match.end;

      while (position < structure.length && depth > 0) {
        final String character = structure[position];

        if (character == '{') {
          depth++;
        } else if (character == '}') {
          depth--;
        }

        position++;
      }

      inside.add(
        structure.substring(match.end, depth == 0 ? position - 1 : position),
      );
      index = position;
    }

    return (outside.join(' '), inside.join(' '));
  }
}
