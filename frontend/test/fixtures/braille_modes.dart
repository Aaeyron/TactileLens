/// One sentence in both Braille modes.
///
/// The Braille matches Liblouis 3.38.0 (en-ueb-g1.ctb for Braille 1,
/// en-ueb-g2.ctb for Braille 2, unicode.dis), the version and tables used
/// by both the AI service and the Android app. It is NOT expert-validated:
/// these fixtures only pin the current Liblouis output so changes are
/// noticed. A Braille expert must review correctness.
class BrailleModeFixture {
  const BrailleModeFixture({
    required this.text,
    required this.uncontracted,
    required this.contracted,
  });

  final String text;

  /// Braille 1 (Spell Out).
  final String uncontracted;

  /// Braille 2 (Contracted).
  final String contracted;
}

/// Matches Liblouis 3.38.0, not expert-validated.
const List<BrailleModeFixture> brailleModeFixtures = <BrailleModeFixture>[
  BrailleModeFixture(
    text: 'the children and the people said that they would go through',
    uncontracted: '⠞⠓⠑⠀⠉⠓⠊⠇⠙⠗⠑⠝⠀⠁⠝⠙⠀⠞⠓⠑⠀⠏⠑⠕⠏⠇⠑⠀⠎⠁⠊⠙⠀⠞⠓⠁⠞⠀⠞⠓⠑⠽⠀⠺⠕⠥⠇⠙⠀⠛⠕⠀⠞⠓⠗⠕⠥⠛⠓',
    contracted: '⠮⠀⠡⠝⠀⠯⠀⠮⠀⠏⠀⠎⠙⠀⠞⠀⠮⠽⠀⠺⠙⠀⠛⠀⠐⠹',
  ),
  BrailleModeFixture(
    text: 'Knowledge is power, and people should work for the world.',
    uncontracted: '⠠⠅⠝⠕⠺⠇⠑⠙⠛⠑⠀⠊⠎⠀⠏⠕⠺⠑⠗⠂⠀⠁⠝⠙⠀⠏⠑⠕⠏⠇⠑⠀⠎⠓⠕⠥⠇⠙⠀⠺⠕⠗⠅⠀⠋⠕⠗⠀⠞⠓⠑⠀⠺⠕⠗⠇⠙⠲',
    contracted: '⠠⠅⠀⠊⠎⠀⠏⠪⠻⠂⠀⠯⠀⠏⠀⠩⠙⠀⠐⠺⠀⠿⠀⠮⠀⠸⠺⠲',
  ),
  BrailleModeFixture(
    text: 'Every one of them can do it with some help.',
    uncontracted: '⠠⠑⠧⠑⠗⠽⠀⠕⠝⠑⠀⠕⠋⠀⠞⠓⠑⠍⠀⠉⠁⠝⠀⠙⠕⠀⠊⠞⠀⠺⠊⠞⠓⠀⠎⠕⠍⠑⠀⠓⠑⠇⠏⠲',
    contracted: '⠠⠑⠀⠐⠕⠀⠷⠀⠮⠍⠀⠉⠀⠙⠀⠭⠀⠾⠀⠐⠎⠀⠓⠑⠇⠏⠲',
  ),
  BrailleModeFixture(
    text: 'THE BIG RED DOG ran home.',
    uncontracted: '⠠⠠⠠⠞⠓⠑⠀⠃⠊⠛⠀⠗⠑⠙⠀⠙⠕⠛⠠⠄⠀⠗⠁⠝⠀⠓⠕⠍⠑⠲',
    contracted: '⠠⠠⠠⠮⠀⠃⠊⠛⠀⠗⠫⠀⠙⠕⠛⠠⠄⠀⠗⠁⠝⠀⠓⠕⠍⠑⠲',
  ),
  BrailleModeFixture(
    text: 'Find x if 3x + 2 = 11.',
    uncontracted: '⠠⠋⠊⠝⠙⠀⠭⠀⠊⠋⠀⠼⠉⠭⠀⠐⠖⠀⠼⠃⠀⠐⠶⠀⠼⠁⠁⠲',
    contracted: '⠠⠋⠔⠙⠀⠰⠭⠀⠊⠋⠀⠼⠉⠭⠀⠐⠖⠀⠼⠃⠀⠐⠶⠀⠼⠁⠁⠲',
  ),
];
