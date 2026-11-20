import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/braille/formula_braille_guard.dart';
import 'package:mobile/services/braille/offline_braille_holds.dart';

void main() {
  group('held: the Braille would read as a different formula', () {
    final Map<String, String> held = <String, String>{
      // ≠ ≤ ≥ ≈ become "!=", "<=", ">=", "~=": "a! = 0", "x < = 3".
      r'a\neq 0': OfflineBrailleHolds.relationSign,
      r'a\ne b': OfflineBrailleHolds.relationSign,
      r'3x-5\leq 10': OfflineBrailleHolds.relationSign,
      r'x\le 4': OfflineBrailleHolds.relationSign,
      r'x \geq -2': OfflineBrailleHolds.relationSign,
      r'x\ge 1': OfflineBrailleHolds.relationSign,
      r'x\geqslant 0': OfflineBrailleHolds.relationSign,
      r'\pi\approx 3.14': OfflineBrailleHolds.relationSign,
      'x ≤ 3': OfflineBrailleHolds.relationSign,
      // Exponent braces dropped: same Braille as another formula.
      r'x^{n+1}': OfflineBrailleHolds.scriptGrouping, // = x^{n}+1
      r'x^{n+1}y': OfflineBrailleHolds.scriptGrouping,
      r'2^{x+1}=8': OfflineBrailleHolds.scriptGrouping, // = 2^{x}+1=8
      r'e^{2x}+1': OfflineBrailleHolds.scriptGrouping, // = e^{2}x+1
      r'x^{2n}': OfflineBrailleHolds.scriptGrouping, // = x^{2}n
      r'x^{-1}y': OfflineBrailleHolds.scriptGrouping, // = x^{-1y}
      r'2^{3}4': OfflineBrailleHolds.scriptGrouping, // = 2^{34}
      r'\log_{2}8=3': OfflineBrailleHolds.scriptGrouping, // = \log_{28}
      r'2^{10}x': OfflineBrailleHolds.scriptGrouping,
      r'a_{n+1}=2a_{n}': OfflineBrailleHolds.scriptGrouping,
      r'x_{12}y': OfflineBrailleHolds.scriptGrouping,
      // Set braces become parentheses.
      r'\{1,2,3\}': OfflineBrailleHolds.setBraces,
      r'A=\lbrace x \rbrace': OfflineBrailleHolds.setBraces,
    };

    held.forEach((String latex, String category) {
      test(latex, () {
        final FormulaReview review = OfflineBrailleHolds.review(latex);

        expect(review.needsReview, isTrue);
        expect(review.categories, contains(category));
        expect(review.reason, isNotEmpty);
      });
    });
  });

  group('not held: grouping is kept or nothing is ambiguous', () {
    for (final String latex in <String>[
      r'2x+3=7',
      r'x^{2}-5x+6=0',
      r'\frac{x+1}{2}=3',
      r'y=mx+b',
      r'x^{2}+y^{2}=r^{2}',
      r'\left(x+2\right)\left(x-3\right)',
      r'\frac{3x}{10}=6',
      r'2\left(x-4\right)=10',
      r'x \times 3 = 12',
      r'12 \div 4 = 3',
      r'-\frac{1}{2}x+4',
      r'x = 3.5',
      r'f(x)=2x^{3}-1',
      r'\pi r^{2}',
      r'x_{1}+x_{2}',
      r'10^{-3}',
      r'2^{10}',
      r'\left(x^{12}\right)',
      // A one-character exponent followed by a letter (3x²y) is the
      // common case; whether its Braille is right is an expert question,
      // so it is not held here.
      r'3x^{2}y',
      // Written with brackets by the normalizer: ^(2x+1), end kept.
      r'x^{2 \cdot x}',
      // Plain "<" and ">" translate as single signs.
      r'x<5',
      r'y>-1',
    ]) {
      test(latex, () {
        expect(OfflineBrailleHolds.review(latex).needsReview, isFalse);
      });
    }
  });

  test('several problems give every reason, in order', () {
    final FormulaReview review = OfflineBrailleHolds.review(r'x^{n+1}\leq\{1\}');

    expect(review.categories, <String>[
      OfflineBrailleHolds.relationSign,
      OfflineBrailleHolds.scriptGrouping,
      OfflineBrailleHolds.setBraces,
    ]);
    expect(
      review.reason,
      '${OfflineBrailleHolds.relationSignReason}; '
      '${OfflineBrailleHolds.scriptGroupingReason}; '
      '${OfflineBrailleHolds.setBracesReason}',
    );
  });

  test('reasons are plain words a teacher can act on (no LaTeX)', () {
    for (final String reason in <String>[
      OfflineBrailleHolds.relationSignReason,
      OfflineBrailleHolds.scriptGroupingReason,
      OfflineBrailleHolds.setBracesReason,
    ]) {
      expect(reason, isNot(contains(r'\')));
      expect(reason, isNot(contains('^')));
    }
  });
}
