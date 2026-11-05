import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/braille/formula_braille_guard.dart';

/// The fixture shared with the AI service's guard tests
/// (ai_service/services/braille/test_formula_guard_shared.py).
const String _fixturePath =
    '../ai_service/services/braille/fixtures/formula_guard_shared.json';

Map<String, dynamic> _loadFixture() {
  final File file = File(_fixturePath);
  expect(
    file.existsSync(),
    isTrue,
    reason: 'Run flutter test from frontend/ so $_fixturePath is found.',
  );
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

List<String> _sorted(Iterable<String> values) => values.toList()..sort();

void main() {
  late Map<String, dynamic> fixture;
  late Map<String, dynamic> vocabulary;

  setUpAll(() {
    fixture = _loadFixture();
    vocabulary = fixture['vocabulary'] as Map<String, dynamic>;
  });

  test('vocabulary matches the AI service guard', () {
    expect(
      _sorted(FormulaBrailleGuard.supportedCommands),
      List<String>.from(vocabulary['supported_commands'] as List<dynamic>),
    );
    expect(
      _sorted(FormulaBrailleGuard.functionNames),
      List<String>.from(vocabulary['function_names'] as List<dynamic>),
    );
    expect(
      _sorted(FormulaBrailleGuard.supportedEnvironments),
      List<String>.from(vocabulary['supported_environments'] as List<dynamic>),
    );
    expect(FormulaBrailleGuard.longWordLength, vocabulary['long_word_length']);
    expect(
      FormulaBrailleGuard.shortWordLength,
      vocabulary['short_word_length'],
    );
    expect(FormulaBrailleGuard.shortWordLimit, vocabulary['short_word_limit']);
    expect(FormulaBrailleGuard.totalWordLimit, vocabulary['total_word_limit']);
    expect(FormulaBrailleGuard.rootSymbols, vocabulary['root_symbols']);
    expect(FormulaBrailleGuard.rootReason, vocabulary['root_reason']);
  });

  test('every shared case gives the same result as the AI service', () {
    final List<dynamic> cases = fixture['cases'] as List<dynamic>;
    expect(cases.length, greaterThanOrEqualTo(40));

    int checked = 0;

    for (final dynamic item in cases) {
      final Map<String, dynamic> expected = item as Map<String, dynamic>;

      if (expected['online_only'] == true) {
        continue;
      }

      final String input = expected['input'] as String;
      final FormulaReview review = FormulaBrailleGuard.review(input);

      expect(review.needsReview, expected['needs_review'], reason: input);
      expect(
        review.categories,
        List<String>.from(expected['categories'] as List<dynamic>),
        reason: input,
      );
      expect(review.reason, expected['reason'], reason: input);
      checked++;
    }

    expect(checked, greaterThanOrEqualTo(40));
  });
}
