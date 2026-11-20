/// Plain words for a "Needs review" reason, for a teacher.
///
/// The stored reason stays exactly as the guard wrote it (online and on the
/// device write the same text, checked by shared tests); only what is shown
/// is rewritten. A reason has one or more parts joined by "; ". Parts that
/// are already plain are kept as they are.
String plainReviewReason(String reason) {
  final List<String> parts = reason
      .split('; ')
      .map((String part) => part.trim())
      .where((String part) => part.isNotEmpty)
      .map(_plainPart)
      .toList(growable: false);

  // Two technical parts can become the same sentence.
  return parts.toSet().join('; ');
}

final RegExp _englishWords = RegExp(
  r'^contains English text \(\d+ words?: (.*)\)$',
);

String _plainPart(String part) {
  if (part.startsWith('unsupported LaTeX:')) {
    return 'uses math notation that cannot be put into Braille yet';
  }

  if (part.startsWith('alignment or row markup')) {
    return 'has several rows or columns of math that cannot be put into '
        'Braille as one line';
  }

  final RegExpMatch? words = _englishWords.firstMatch(part);

  if (words != null) {
    return 'has words mixed into the math (${words.group(1)})';
  }

  if (part == 'markup left after normalization') {
    return 'could not be fully converted for Braille';
  }

  return part;
}
