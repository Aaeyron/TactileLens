import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/ai/paddle_onnx_native_service.dart';
import 'package:mobile/services/braille/offline_agreement_holds.dart';

void main() {
  group('words read as single letters', () {
    test('worksheet notes are found', () {
      expect(
        OfflineAgreementHolds.lostWords(r'x\neq1a n d x\neq-4'),
        isNotEmpty,
      );
      expect(
        OfflineAgreementHolds.lostWords(r'R e a s o n:81>\frac{1}{81}'),
        <String>['Reason'],
      );
      expect(
        OfflineAgreementHolds.lostWords(
          r'a^{2}-b^{2}\quad O u r~S o l u t i o n',
        ),
        isNotEmpty,
      );
    });

    test('products, commands and text groups are not words', () {
      expect(OfflineAgreementHolds.lostWords('x y z=1'), isEmpty);
      expect(OfflineAgreementHolds.lostWords('a b c'), isEmpty);
      expect(OfflineAgreementHolds.lostWords(r'\text{and}'), isEmpty);
      expect(OfflineAgreementHolds.lostWords(r'\frac{x+1}{2}=3'), isEmpty);
      expect(OfflineAgreementHolds.lostWords('f(x) = 2x'), isEmpty);
    });
  });

  group('review', () {
    test('two readings that differ are held, with a plain reason', () {
      final review = OfflineAgreementHolds.review(
        '=k+3h',
        readingsAgree: false,
      );
      expect(review.needsReview, isTrue);
      expect(review.categories, <String>[OfflineAgreementHolds.readingsDiffer]);
      expect(review.reason, OfflineAgreementHolds.readingsDifferReason);
      expect(review.reason, isNot(contains(r'\')));
    });

    test('agreeing readings and a check that did not run are not held', () {
      expect(
        OfflineAgreementHolds.review('0=k+3h', readingsAgree: true).needsReview,
        isFalse,
      );
      expect(OfflineAgreementHolds.review('0=k+3h').needsReview, isFalse);
    });

    test('lost words are held even when both models agree', () {
      final review = OfflineAgreementHolds.review(
        r'x\neq0a n d y\neq0',
        readingsAgree: true,
      );
      expect(review.needsReview, isTrue);
      expect(review.categories, <String>[OfflineAgreementHolds.lostTextWords]);
    });

    test('both reasons together', () {
      final review = OfflineAgreementHolds.review(
        r'x\neq0a n d y\neq0',
        readingsAgree: false,
      );
      expect(review.categories, <String>[
        OfflineAgreementHolds.readingsDiffer,
        OfflineAgreementHolds.lostTextWords,
      ]);
      expect(review.reason, contains('; '));
    });
  });

  test('the pipeline block carries the agreement result', () {
    final agree = OfflineDocumentBlock.fromMap(<String, Object?>{
      'type': 'formula',
      'content': '0=k+3h',
      'check_latex': '=k+3h',
      'readings_agree': false,
    });
    expect(agree.readingsAgree, isFalse);
    expect(agree.checkLatex, '=k+3h');

    final text = OfflineDocumentBlock.fromMap(<String, Object?>{
      'type': 'text',
      'content': 'Solve for x.',
    });
    expect(text.readingsAgree, isNull);
  });
}
