/// How UEB text is written in Braille. Nemeth math is never affected.
enum BrailleMode {
  /// Braille 1 (Spell Out): uncontracted UEB, every letter written out.
  uncontracted('uncontracted'),

  /// Braille 2 (Contracted): UEB Grade 2. The default and the format the
  /// scanners produce.
  contracted('contracted');

  const BrailleMode(this.wireName);

  /// Name used in storage, platform channels and saved JSON.
  final String wireName;

  static const BrailleMode defaultMode = BrailleMode.contracted;

  /// Reads a stored name. Anything missing or unknown means Braille 2, so
  /// records saved before modes existed keep working.
  static BrailleMode fromWireName(Object? value) {
    for (final BrailleMode mode in BrailleMode.values) {
      if (mode.wireName == value) {
        return mode;
      }
    }

    return defaultMode;
  }
}
