import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/utils/review_reason_text.dart';

void main() {
  group('plainReviewReason', () {
    final Map<String, String> cases = <String, String>{
      // Shared guard (online and on device).
      r'unsupported LaTeX: \hat':
          'uses math notation that cannot be put into Braille yet',
      r'unsupported LaTeX: \hat, \vec; unsupported LaTeX: cases environment':
          'uses math notation that cannot be put into Braille yet',
      r'alignment or row markup (& or \)':
          'has several rows or columns of math that cannot be put into '
          'Braille as one line',
      'contains English text (1 words: when)':
          'has words mixed into the math (when)',
      'contains English text (6 words: the, total, cost, per, ...)':
          'has words mixed into the math (the, total, cost, per, ...)',
      'markup left after normalization':
          'could not be fully converted for Braille',
      // Already plain: kept as they are.
      'contains a root (√): Nemeth radical not yet confirmed':
          'contains a root (√): Nemeth radical not yet confirmed',
      "contains a symbol our Braille tables don't support":
          "contains a symbol our Braille tables don't support",
      'low OCR confidence': 'low OCR confidence',
      // Several parts keep their order.
      r'unsupported LaTeX: \hat; contains English text (1 words: when); '
              'contains a root (√): Nemeth radical not yet confirmed':
          'uses math notation that cannot be put into Braille yet; '
          'has words mixed into the math (when); '
          'contains a root (√): Nemeth radical not yet confirmed',
    };

    cases.forEach((String stored, String shown) {
      test(stored, () => expect(plainReviewReason(stored), shown));
    });

    test('no LaTeX commands are shown for any guard reason', () {
      for (final String stored in cases.keys) {
        expect(plainReviewReason(stored), isNot(contains(r'\')));
      }
    });
  });
}
