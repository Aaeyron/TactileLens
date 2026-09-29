/// Converts LaTeX produced by the formula model into readable Unicode math.
///
/// The user must never see LaTeX commands. Use:
/// * [MathTextFormatter.latexToReadable] for a block that is known to be a
///   formula (the whole string is LaTeX).
/// * [MathTextFormatter.ensureReadable] for mixed text that may contain some
///   LaTeX. Plain text without LaTeX is returned unchanged.
///
/// Examples:
/// * `\sqrt{x+9}=5`        -> `√(x + 9) = 5`
/// * `\frac{3x+1}{x-2}`    -> `(3x + 1)/(x − 2)`
/// * `x^{n+1}`             -> `x^(n + 1)`
/// * `3x-4\leq11`          -> `3x − 4 ≤ 11`
class MathTextFormatter {
  const MathTextFormatter._();

  static const Map<String, String> _sup = <String, String>{
    '0': '⁰',
    '1': '¹',
    '2': '²',
    '3': '³',
    '4': '⁴',
    '5': '⁵',
    '6': '⁶',
    '7': '⁷',
    '8': '⁸',
    '9': '⁹',
    '+': '⁺',
    '−': '⁻',
    '-': '⁻',
    'n': 'ⁿ',
    'i': 'ⁱ',
  };

  static const Map<String, String> _sub = <String, String>{
    '0': '₀',
    '1': '₁',
    '2': '₂',
    '3': '₃',
    '4': '₄',
    '5': '₅',
    '6': '₆',
    '7': '₇',
    '8': '₈',
    '9': '₉',
    '+': '₊',
    '−': '₋',
    '-': '₋',
    'a': 'ₐ',
    'e': 'ₑ',
    'o': 'ₒ',
    'x': 'ₓ',
    'i': 'ᵢ',
    'j': 'ⱼ',
    'k': 'ₖ',
    'm': 'ₘ',
    'n': 'ₙ',
    't': 'ₜ',
  };

  static const Map<String, String> _symbols = <String, String>{
    'leq': '≤',
    'le': '≤',
    'leqslant': '≤',
    'geq': '≥',
    'ge': '≥',
    'geqslant': '≥',
    'neq': '≠',
    'ne': '≠',
    'lt': '<',
    'gt': '>',
    'approx': '≈',
    'equiv': '≡',
    'sim': '∼',
    'cong': '≅',
    'propto': '∝',
    'times': '×',
    'div': '÷',
    'cdot': '·',
    'ast': '*',
    'pm': '±',
    'mp': '∓',
    'infty': '∞',
    'sum': '∑',
    'prod': '∏',
    'int': '∫',
    'partial': '∂',
    'nabla': '∇',
    'degree': '°',
    'circ': '°',
    'prime': '′',
    'ldots': '…',
    'cdots': '…',
    'dots': '…',
    'vdots': '⋮',
    'to': '→',
    'rightarrow': '→',
    'longrightarrow': '→',
    'Rightarrow': '⇒',
    'Longrightarrow': '⇒',
    'implies': '⇒',
    'leftarrow': '←',
    'Leftarrow': '⇐',
    'leftrightarrow': '↔',
    'Leftrightarrow': '⇔',
    'iff': '⇔',
    'therefore': '∴',
    'because': '∵',
    'in': '∈',
    'notin': '∉',
    'ni': '∋',
    'subset': '⊂',
    'subseteq': '⊆',
    'supset': '⊃',
    'supseteq': '⊇',
    'cup': '∪',
    'cap': '∩',
    'emptyset': '∅',
    'varnothing': '∅',
    'forall': '∀',
    'exists': '∃',
    'neg': '¬',
    'land': '∧',
    'lor': '∨',
    'angle': '∠',
    'perp': '⊥',
    'parallel': '∥',
    'triangle': '△',
    'mid': '|',
    'vert': '|',
    'lvert': '|',
    'rvert': '|',
    'Vert': '‖',
    'lVert': '‖',
    'rVert': '‖',
    'langle': '⟨',
    'rangle': '⟩',
    'lfloor': '⌊',
    'rfloor': '⌋',
    'lceil': '⌈',
    'rceil': '⌉',
    'lbrace': '{',
    'rbrace': '}',
    'alpha': 'α',
    'beta': 'β',
    'gamma': 'γ',
    'delta': 'δ',
    'epsilon': 'ε',
    'varepsilon': 'ε',
    'zeta': 'ζ',
    'eta': 'η',
    'theta': 'θ',
    'vartheta': 'θ',
    'iota': 'ι',
    'kappa': 'κ',
    'lambda': 'λ',
    'mu': 'μ',
    'nu': 'ν',
    'xi': 'ξ',
    'pi': 'π',
    'varpi': 'π',
    'rho': 'ρ',
    'sigma': 'σ',
    'tau': 'τ',
    'upsilon': 'υ',
    'phi': 'φ',
    'varphi': 'φ',
    'chi': 'χ',
    'psi': 'ψ',
    'omega': 'ω',
    'Gamma': 'Γ',
    'Delta': 'Δ',
    'Theta': 'Θ',
    'Lambda': 'Λ',
    'Xi': 'Ξ',
    'Pi': 'Π',
    'Sigma': 'Σ',
    'Phi': 'Φ',
    'Psi': 'Ψ',
    'Omega': 'Ω',
    'percent': '%',
  };

  static const Set<String> _functions = <String>{
    'sin',
    'cos',
    'tan',
    'sec',
    'csc',
    'cot',
    'sinh',
    'cosh',
    'tanh',
    'arcsin',
    'arccos',
    'arctan',
    'log',
    'ln',
    'exp',
    'lim',
    'max',
    'min',
    'det',
    'gcd',
    'lcm',
    'deg',
    'mod',
  };

  static const Set<String> _spaces = <String>{
    'quad',
    'qquad',
    'space',
    'enspace',
    'thinspace',
    'medspace',
    'thickspace',
  };

  static const Set<String> _ignored = <String>{
    'left',
    'right',
    'big',
    'Big',
    'bigg',
    'Bigg',
    'bigl',
    'bigr',
    'Bigl',
    'Bigr',
    'biggl',
    'biggr',
    'Biggl',
    'Biggr',
    'middle',
    'displaystyle',
    'textstyle',
    'scriptstyle',
    'limits',
    'nolimits',
    'nonumber',
    'notag',
    'centering',
    'hline',
  };

  static const Set<String> _textWrappers = <String>{
    'text',
    'textrm',
    'textit',
    'textbf',
    'textnormal',
    'mbox',
    'hbox',
    'textsf',
    'texttt',
  };

  static const Set<String> _mathWrappers = <String>{
    'mathrm',
    'mathbf',
    'mathit',
    'mathsf',
    'mathtt',
    'boldsymbol',
    'bm',
    'operatorname',
    'overline',
    'underline',
    'bar',
    'hat',
    'vec',
    'tilde',
    'widehat',
    'widetilde',
    'overrightarrow',
    'dot',
    'ddot',
    'boxed',
    'cancel',
    'underbrace',
    'overbrace',
    'phantom',
  };

  static const Map<String, String> _blackboard = <String, String>{
    'R': 'ℝ',
    'N': 'ℕ',
    'Z': 'ℤ',
    'Q': 'ℚ',
    'C': 'ℂ',
  };

  static const Set<String> _lineEnvironments = <String>{
    'aligned',
    'align',
    'align*',
    'split',
    'gathered',
    'gather',
    'eqnarray',
    'eqnarray*',
  };

  static const Map<String, String> _escaped = <String, String>{
    '{': '{',
    '}': '}',
    '%': '%',
    r'$': r'$',
    '&': '&',
    '#': '#',
    '_': '_',
    '|': '‖',
    ',': ' ',
    ';': ' ',
    ':': ' ',
    ' ': ' ',
    '!': '',
  };

  static const String _alwaysSpaced = '=<>≤≥≠≈≡∼≅∝→⇒⇐←↔⇔∈∉∋⊂⊆⊃⊇∪∩×÷·';
  static const String _signs = '+−±∓';

  static final RegExp _letter = RegExp(r'[A-Za-z]');
  static final RegExp _letterOrDigit = RegExp(r'[A-Za-z0-9]');
  static final RegExp _whitespace = RegExp(r'\s');
  static final RegExp _integer = RegExp(r'^[+\-−]?\d+$');
  static final RegExp _simple = RegExp(r'^[0-9.]+$|^[A-Za-zα-ωΑ-Ω]$');
  static final RegExp _bigDelimiter = RegExp(r'^(big|Big|bigg|Bigg)[lr]?$');
  static final RegExp _matrix = RegExp(r'^[pbBvV]?matrix$');
  static final RegExp _operandEnd = RegExp(
    r'[A-Za-z0-9α-ωΑ-Ω)\]}′'
    "'"
    r'!∞%.°…]',
  );
  static final RegExp _latexHint = RegExp(
    r'\\[A-Za-z]+|\\[()\[\]{}]|\$|[\^_]\{',
  );
  static final RegExp _mathInChunk = RegExp(r'\\[A-Za-z]|[\^_]\{|\\[{}]');
  static final String _supSubCharacters =
      '${_sup.values.join()}${_sub.values.join()}';

  /// True when [text] still contains something that looks like LaTeX.
  static bool containsLatex(String text) => _latexHint.hasMatch(text);

  /// Converts a whole LaTeX formula into readable Unicode math.
  static String latexToReadable(String latex) {
    if (latex.trim().isEmpty) {
      return '';
    }

    final String readable = _pretty(_convert(_stripDelimiters(latex)));

    // Last safety net: never let a backslash reach the user.
    return readable.replaceAll(r'\', '');
  }

  /// Converts only the LaTeX parts of mixed text. Text without LaTeX is
  /// returned unchanged, so "costs $5 today" and "√2" stay as they are.
  static String ensureReadable(String text) {
    if (text.isEmpty || !containsLatex(text)) {
      return text;
    }

    String result = text.replaceAllMapped(
      RegExp(r'\$\$([\s\S]+?)\$\$|\\\[([\s\S]+?)\\\]|\\\(([\s\S]+?)\\\)'),
      (Match match) => latexToReadable(
        match.group(1) ?? match.group(2) ?? match.group(3) ?? '',
      ),
    );

    result = result.replaceAllMapped(RegExp(r'\$([^$\n]+?)\$'), (Match match) {
      final String inner = match.group(1) ?? '';

      return RegExp(r'\\[A-Za-z]|[\^_]').hasMatch(inner)
          ? latexToReadable(inner)
          : match.group(0)!;
    });

    // Convert whitespace-separated chunks that still hold LaTeX. Braces keep
    // "\frac{x + 1}{2}" together as one chunk.
    final StringBuffer output = StringBuffer();
    final StringBuffer chunk = StringBuffer();
    int depth = 0;

    void flush() {
      if (chunk.isEmpty) {
        return;
      }

      final String value = chunk.toString();
      output.write(
        _mathInChunk.hasMatch(value) ? latexToReadable(value) : value,
      );
      chunk.clear();
    }

    for (int i = 0; i < result.length; i++) {
      final String c = result[i];

      if (c == '{') {
        depth++;
      } else if (c == '}') {
        depth = depth > 0 ? depth - 1 : 0;
      }

      if (depth == 0 && _whitespace.hasMatch(c)) {
        flush();
        output.write(c);
      } else {
        chunk.write(c);
      }
    }

    flush();

    return output
        .toString()
        .replaceAllMapped(
          RegExp(r'\\([A-Za-z]+)'),
          (Match match) => match.group(1) ?? '',
        )
        .replaceAll(r'\', '');
  }

  // ---------------------------------------------------------------------------
  // Parsing helpers
  // ---------------------------------------------------------------------------

  static bool _isLetter(String c) => _letter.hasMatch(c);

  static String _charAt(String s, int i) => i >= 0 && i < s.length ? s[i] : '';

  /// Reads a group that starts at [start] with [open]. Returns the inner text
  /// and the index after the closing character. An unclosed group takes the
  /// rest of the string.
  static (String, int)? _readBraced(
    String s,
    int start, [
    String open = '{',
    String close = '}',
  ]) {
    if (start >= s.length || s[start] != open) {
      return null;
    }

    int depth = 0;

    for (int i = start; i < s.length; i++) {
      final String c = s[i];

      if (c == r'\') {
        i++;
        continue;
      }

      if (c == open) {
        depth++;
      } else if (c == close) {
        depth--;

        if (depth == 0) {
          return (s.substring(start + 1, i), i + 1);
        }
      }
    }

    return (s.substring(start + 1), s.length);
  }

  static int _skipSpaces(String s, int i) {
    int index = i;

    while (index < s.length && _whitespace.hasMatch(s[index])) {
      index++;
    }

    return index;
  }

  /// Reads one command argument: a braced group, a command, or one character.
  static (String, int) _readArgument(String s, int i) {
    final int index = _skipSpaces(s, i);

    if (index >= s.length) {
      return ('', index);
    }

    if (s[index] == '{') {
      return _readBraced(s, index)!;
    }

    if (s[index] == r'\' && index + 1 < s.length) {
      if (_isLetter(s[index + 1])) {
        int end = index + 1;

        while (end < s.length && _isLetter(s[end])) {
          end++;
        }

        return (s.substring(index, end), end);
      }

      return (s.substring(index, index + 2), index + 2);
    }

    return (s[index], index + 1);
  }

  static (String, int) _findEnvironmentEnd(String s, int i, String env) {
    final String beginTag = '\\begin{$env}';
    final String endTag = '\\end{$env}';
    int depth = 1;
    int index = i;

    while (index < s.length) {
      if (s.startsWith(beginTag, index)) {
        depth++;
        index += beginTag.length;
        continue;
      }

      if (s.startsWith(endTag, index)) {
        depth--;

        if (depth == 0) {
          return (s.substring(i, index), index + endTag.length);
        }

        index += endTag.length;
        continue;
      }

      index++;
    }

    return (s.substring(i), s.length);
  }

  /// Splits an environment body on top-level `\\` row breaks.
  static List<String> _splitRows(String body) {
    final List<String> rows = <String>[];
    int depth = 0;
    int start = 0;
    int i = 0;

    while (i < body.length) {
      final String c = body[i];

      if (c == r'\' && i + 1 < body.length) {
        if (body[i + 1] == r'\' && depth == 0) {
          rows.add(body.substring(start, i));
          i += 2;
          start = i;
          continue;
        }

        i += 2;
        continue;
      }

      if (c == '{') {
        depth++;
      } else if (c == '}') {
        depth--;
      }

      i++;
    }

    rows.add(body.substring(start));

    return rows;
  }

  static bool _isSimple(String value) => _simple.hasMatch(value);

  static bool _isWrapped(String value) {
    if (!value.startsWith('(') || !value.endsWith(')')) {
      return false;
    }

    int depth = 0;

    for (int i = 0; i < value.length; i++) {
      if (value[i] == '(') {
        depth++;
      } else if (value[i] == ')') {
        depth--;

        if (depth == 0 && i < value.length - 1) {
          return false;
        }
      }
    }

    return true;
  }

  static String _wrap(String value) {
    final String trimmed = value.trim();

    return _isSimple(trimmed) || _isWrapped(trimmed) ? trimmed : '($trimmed)';
  }

  static String _script(String kind, String content) {
    final String c = content.trim();

    if (c.isEmpty) {
      return '';
    }

    if (kind == '^') {
      if (_integer.hasMatch(c) || c == 'n' || c == 'i') {
        return c.split('').map((String ch) => _sup[ch] ?? ch).join();
      }

      return c.length == 1 ? '^$c' : '^($c)';
    }

    if (_integer.hasMatch(c) || (c.length == 1 && _sub.containsKey(c))) {
      return c.split('').map((String ch) => _sub[ch] ?? ch).join();
    }

    return c.length == 1 ? '_$c' : '_($c)';
  }

  static String _unescapeText(String text) {
    if (text.contains(r'\')) {
      return _convert(text, textMode: true);
    }

    return text.replaceAll('~', ' ');
  }

  // ---------------------------------------------------------------------------
  // LaTeX -> linear Unicode (spacing is fixed later by _pretty)
  // ---------------------------------------------------------------------------

  static String _convert(String s, {bool textMode = false}) {
    final StringBuffer out = StringBuffer();
    int i = 0;

    while (i < s.length) {
      final String c = s[i];

      if (c == r'\') {
        if (i + 1 >= s.length) {
          i++;
          continue;
        }

        final String next = s[i + 1];

        if (next == r'\') {
          out.write('\n');
          i += 2;
          continue;
        }

        if (_isLetter(next)) {
          int end = i + 1;

          while (end < s.length && _isLetter(s[end])) {
            end++;
          }

          final String name = s.substring(i + 1, end);
          i = end;
          i = _convertCommand(s, i, name, out, textMode);
          continue;
        }

        out.write(_escaped[next] ?? next);
        i += 2;
        continue;
      }

      if (c == '{') {
        final (String, int) group = _readBraced(s, i)!;
        out.write(_convert(group.$1, textMode: textMode));
        i = group.$2;
        continue;
      }

      if (c == '}') {
        i++;
        continue;
      }

      if ((c == '^' || c == '_') && !textMode) {
        final (String, int) argument = _readArgument(s, i + 1);
        i = argument.$2;
        out.write(_script(c, _convert(argument.$1)));
        continue;
      }

      if (c == '&') {
        i++;
        continue;
      }

      if (c == '~') {
        out.write(' ');
        i++;
        continue;
      }

      if (_whitespace.hasMatch(c)) {
        if (textMode) {
          out.write(' ');
        }

        i++;
        continue;
      }

      if (c == '-' && !textMode) {
        out.write('−');
        i++;
        continue;
      }

      out.write(c);
      i++;
    }

    return out.toString();
  }

  /// Handles one `\name` command. Returns the index after its arguments.
  static int _convertCommand(
    String s,
    int start,
    String name,
    StringBuffer out,
    bool textMode,
  ) {
    int i = start;

    if (name == 'frac' ||
        name == 'dfrac' ||
        name == 'tfrac' ||
        name == 'cfrac') {
      final (String, int) numerator = _readArgument(s, i);
      final (String, int) denominator = _readArgument(s, numerator.$2);
      out.write(
        '${_wrap(_convert(numerator.$1))}/${_wrap(_convert(denominator.$1))}',
      );
      return denominator.$2;
    }

    if (name == 'binom' || name == 'dbinom' || name == 'tbinom') {
      final (String, int) n = _readArgument(s, i);
      final (String, int) k = _readArgument(s, n.$2);
      out.write('C(${_convert(n.$1)},${_convert(k.$1)})');
      return k.$2;
    }

    if (name == 'sqrt') {
      i = _skipSpaces(s, i);
      String index = '';

      if (_charAt(s, i) == '[') {
        final (String, int) group = _readBraced(s, i, '[', ']')!;
        index = _convert(group.$1).trim();
        i = group.$2;
      }

      final (String, int) argument = _readArgument(s, i);
      final String radicand = _convert(argument.$1).trim();
      final String symbol;

      if (index.isEmpty || index == '2') {
        symbol = '√';
      } else if (index == '3') {
        symbol = '∛';
      } else if (index == '4') {
        symbol = '∜';
      } else if (RegExp(r'^\d+$').hasMatch(index) || index == 'n') {
        symbol = '${_script('^', index)}√';
      } else {
        symbol = '√[$index]';
      }

      out.write(symbol);
      out.write(_isSimple(radicand) ? radicand : '($radicand)');
      return argument.$2;
    }

    if (_ignored.contains(name)) {
      if (name == 'left' ||
          name == 'right' ||
          name == 'middle' ||
          _bigDelimiter.hasMatch(name)) {
        i = _skipSpaces(s, i);

        // "\left." and "\right." are invisible delimiters.
        if (_charAt(s, i) == '.') {
          i++;
        }
      }

      return i;
    }

    if (_textWrappers.contains(name)) {
      final (String, int) argument = _readArgument(s, i);
      out.write(_unescapeText(argument.$1));
      return argument.$2;
    }

    if (name == 'mathbb') {
      final (String, int) argument = _readArgument(s, i);
      final String value = argument.$1.trim();
      out.write(_blackboard[value] ?? _convert(value));
      return argument.$2;
    }

    if (_mathWrappers.contains(name)) {
      final (String, int) argument = _readArgument(s, i);
      out.write(_convert(argument.$1, textMode: textMode));
      return argument.$2;
    }

    if (name == 'begin') {
      final (String, int) argument = _readArgument(s, i);
      final String env = argument.$1.trim();
      i = argument.$2;

      if (env == 'array' || env == 'tabular') {
        i = _readArgument(s, i).$2; // Skip the column spec, e.g. {cc}.
      }

      final (String, int) body = _findEnvironmentEnd(s, i, env);
      final bool lineEnvironment = _lineEnvironments.contains(env);

      final List<String> rows = _splitRows(body.$1)
          .map((String row) {
            if (lineEnvironment) {
              return _convert(row.replaceAll('&', '')).trim();
            }

            return _convert(
              row.replaceAll('&', '\u0001'),
            ).replaceAll('\u0001', ', ').trim();
          })
          .where((String row) => row.isNotEmpty)
          .toList();

      if (_matrix.hasMatch(env)) {
        out.write('[${rows.join('; ')}]');
      } else {
        out.write(rows.join('\n'));
      }

      return body.$2;
    }

    if (name == 'end') {
      return _readArgument(s, i).$2;
    }

    if (_spaces.contains(name)) {
      out.write(' ');
      return i;
    }

    if (name == 'hspace' ||
        name == 'vspace' ||
        name == 'label' ||
        name == 'tag') {
      return _readArgument(s, i).$2;
    }

    if (_functions.contains(name)) {
      out.write(name);
      final int next = _skipSpaces(s, i);
      final String following = _charAt(s, next);

      if (following.isNotEmpty &&
          (_letterOrDigit.hasMatch(following) || following == r'\')) {
        out.write(' ');
      }

      return i;
    }

    final String? symbol = _symbols[name];

    if (symbol != null) {
      out.write(symbol);
      return i;
    }

    // Unknown (possibly hallucinated) command: keep its argument, drop the
    // command name.
    final int next = _skipSpaces(s, i);

    if (_charAt(s, next) == '{') {
      final (String, int) group = _readBraced(s, next)!;
      out.write(_convert(group.$1, textMode: textMode));
      return group.$2;
    }

    return i;
  }

  // ---------------------------------------------------------------------------
  // Spacing
  // ---------------------------------------------------------------------------

  static String _trimEnd(String value) => value.replaceAll(RegExp(r' +$'), '');

  /// True when the text before a + or − ends with an operand, which makes the
  /// sign a binary operator ("x − 2") instead of a negative sign ("−2").
  static bool _isOperandEnd(String out) {
    int k = out.length - 1;

    while (k >= 0 && out[k] == ' ') {
      k--;
    }

    if (k < 0) {
      return false;
    }

    final String previous = out[k];

    if (previous == '\n') {
      return false;
    }

    if (_operandEnd.hasMatch(previous) ||
        _supSubCharacters.contains(previous)) {
      return true;
    }

    if (previous == '|') {
      // An even number of bars means this bar closes |x − 3|.
      final int lineStart = out.lastIndexOf('\n', k) + 1;
      final int bars = out
          .substring(lineStart, k + 1)
          .split('')
          .where((String ch) => ch == '|')
          .length;

      return bars.isEven;
    }

    return false;
  }

  static String _pretty(String raw) {
    String out = '';

    for (int i = 0; i < raw.length; i++) {
      final String c = raw[i];

      if (c == ' ') {
        if (out.isNotEmpty && !out.endsWith(' ') && !out.endsWith('\n')) {
          out += ' ';
        }

        continue;
      }

      if (c == '\n') {
        out = '${_trimEnd(out)}\n';
        continue;
      }

      if (_alwaysSpaced.contains(c)) {
        out = '${_trimEnd(out)} $c ';
        continue;
      }

      if (_signs.contains(c)) {
        if (_isOperandEnd(out)) {
          out = '${_trimEnd(out)} $c ';
        } else {
          out += c;
        }

        continue;
      }

      if (c == ',') {
        // Keep thousands separators such as 1,000 together.
        final bool thousands =
            RegExp(r'\d$').hasMatch(_trimEnd(out)) &&
            RegExp(r'^\d{3}(?!\d)').hasMatch(raw.substring(i + 1));

        out = '${_trimEnd(out)}${thousands ? ',' : ', '}';
        continue;
      }

      if (c == ')' || c == ']') {
        out = '${_trimEnd(out)}$c';
        continue;
      }

      if (out.endsWith('( ') || out.endsWith('[ ')) {
        out = _trimEnd(out);
      }

      out += c;
    }

    return out
        .split('\n')
        .map(
          (String line) => line
              .replaceAll(RegExp(r' {2,}'), ' ')
              .replaceAllMapped(
                RegExp(r'([(\[]) '),
                (Match match) => match.group(1)!,
              )
              .replaceAllMapped(
                RegExp(r' ([)\],])'),
                (Match match) => match.group(1)!,
              )
              .trim(),
        )
        .where((String line) => line.isNotEmpty)
        .join('\n');
  }

  static String _stripDelimiters(String value) {
    final String text = value
        .replaceAll(RegExp(r'```(?:latex|math|tex)?'), '')
        .trim();

    const List<List<String>> pairs = <List<String>>[
      <String>[r'$$', r'$$'],
      <String>[r'\[', r'\]'],
      <String>[r'\(', r'\)'],
      <String>[r'$', r'$'],
    ];

    for (final List<String> pair in pairs) {
      final String open = pair[0];
      final String close = pair[1];

      if (text.startsWith(open) &&
          text.endsWith(close) &&
          text.length >= open.length + close.length) {
        return text.substring(open.length, text.length - close.length).trim();
      }
    }

    return text;
  }
}
