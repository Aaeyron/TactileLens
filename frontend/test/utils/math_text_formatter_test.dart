// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter_test/flutter_test.dart';

import '../../lib/utils/math_text_formatter.dart';

void main() {
  const Map<String, String> formulas = <String, String>{
    r'3+5': r'3 + 5',
    r'12-7': r'12 − 7',
    r'4\times6': r'4 × 6',
    r'20\div5': r'20 ÷ 5',
    r'\frac{1}{2}': r'1/2',
    r'\frac{3x+1}{x-2}': r'(3x + 1)/(x − 2)',
    r'\frac{x}{x+5}': r'x/(x + 5)',
    r'\frac{\frac{1}{2}}{3}': r'(1/2)/3',
    r'x^{2}': r'x²',
    r'x^{3}': r'x³',
    r'2x^{4}-3x^{2}+1': r'2x⁴ − 3x² + 1',
    r'x^{n+1}': r'x^(n + 1)',
    r'\sqrt{x}': r'√x',
    r'\sqrt{x+9}=5': r'√(x + 9) = 5',
    r'\sqrt[3]{x}=4': r'∛x = 4',
    r'\sqrt{\frac{a+b}{c}}': r'√((a + b)/c)',
    r'2x+7=19': r'2x + 7 = 19',
    r'3x-5=10': r'3x − 5 = 10',
    r'x^{2}-5x+6=0': r'x² − 5x + 6 = 0',
    r'ax^{2}+bx+c=0': r'ax² + bx + c = 0',
    r'3x-4\leq11': r'3x − 4 ≤ 11',
    r'x\geq2': r'x ≥ 2',
    r'x\neq7': r'x ≠ 7',
    r'-2<x\leq5': r'−2 < x ≤ 5',
    r'2x^{3}-x^{2}+4x-7': r'2x³ − x² + 4x − 7',
    r'(x+2)(x-3)': r'(x + 2)(x − 3)',
    r'f(x)=2x^{2}+3': r'f(x) = 2x² + 3',
    r'g(x+1)': r'g(x + 1)',
    r'f^{-1}(x)': r'f⁻¹(x)',
    r'x+y=10': r'x + y = 10',
    r'2x-y=3': r'2x − y = 3',
    r'(2,5)': r'(2, 5)',
    r'|x-3|=5': r'|x − 3| = 5',
    r'\left|2x+1\right|\leq7': r'|2x + 1| ≤ 7',
    r'(a+b)^{2}=a^{2}+2ab+b^{2}': r'(a + b)² = a² + 2ab + b²',
    r'a^{2}-b^{2}=(a-b)(a+b)': r'a² − b² = (a − b)(a + b)',
    r'y=mx+b': r'y = mx + b',
    r'a \cdot b': r'a · b',
    r'a \times b': r'a × b',
    r'a \div b': r'a ÷ b',
    r'x=\pm 3': r'x = ±3',
    r'\pi\approx3.14': r'π ≈ 3.14',
    r'\sum x': r'∑x',
    r'\left(\sqrt{2}\right)^{2}=2': r'(√2)² = 2',
    r'\frac{x+1}{2}=3': r'(x + 1)/2 = 3',
    r'\frac{3x}{10}=6': r'(3x)/10 = 6',
    r'\text{b.}\ g\left(x\right)=\sqrt{5x-12}': r'b. g(x) = √(5x − 12)',
    r'x=\frac{7\pm\sqrt{(-7)^{2}-4(1)(-8)}}{2}=\frac{7\pm\sqrt{81}}{2}':
        r'x = (7 ± √((−7)² − 4(1)(−8)))/2 = (7 ± √81)/2',
    r'\frac{x-4}{2}-\frac{x}{5}=\frac{1}{10}': r'(x − 4)/2 − x/5 = 1/10',
    r'\frac{4}{x+1}=\frac{3}{x}+\frac{1}{15}': r'4/(x + 1) = 3/x + 1/15',
    r'x_{1}+x_{2}': r'x₁ + x₂',
    r'10^{-3}': r'10⁻³',
    r'\sin x+\cos(x)': r'sin x + cos(x)',
    r'f(x)=\begin{cases}x^{2} & x\geq0\\ -x & x<0\end{cases}':
        'f(x) = x², x ≥ 0\n−x, x < 0',
    r'$$x^{2}$$': r'x²',
    r'\(x\leq 2\)': r'x ≤ 2',
    r'1,000+2': r'1,000 + 2',
    r'\{1,2\}': r'{1, 2}',
    r'\lefted{\mathrm{~b.~g}\left(x\right)=\sqrt{5x-12}}':
        r'b. g(x) = √(5x − 12)',
  };

  const Map<String, String> mixedText = <String, String>{
    r'Solve for x: 3x \leq 11': r'Solve for x: 3x ≤ 11',
    r'The answer is $x^{2}$ here.': r'The answer is x² here.',
    r'Plain text - no math, costs $5 today.':
        r'Plain text - no math, costs $5 today.',
    r'Use \frac{x + 1}{2} now': r'Use (x + 1)/2 now',
    r'x^{2} and y^{3}': r'x² and y³',
    r'By definition, √2 is positive.': r'By definition, √2 is positive.',
  };

  group('MathTextFormatter.latexToReadable', () {
    formulas.forEach((String latex, String expected) {
      test(latex, () {
        final String readable = MathTextFormatter.latexToReadable(latex);

        expect(readable, expected);
        expect(readable.contains(r'\'), isFalse);
        expect(readable.contains(r'$'), isFalse);
      });
    });
  });

  group('MathTextFormatter.ensureReadable', () {
    mixedText.forEach((String text, String expected) {
      test(text, () {
        expect(MathTextFormatter.ensureReadable(text), expected);
      });
    });
  });
}
