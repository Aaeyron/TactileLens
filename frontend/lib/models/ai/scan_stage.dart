/// A real step of a running scan, reported by the scanning services as it
/// starts. Only steps the app can actually observe are listed: an online
/// scan is one request to the server, and the on-device reader finds and
/// reads text and math in one native call, so those are one step each.
enum ScanStage {
  /// Online: the quick check that the server answers (up to 8 s).
  checkingConnection('Checking the connection…'),

  /// Online: the page is uploaded and read on the server.
  readingOnline('Reading the page online…'),

  /// On this device: the scanning models are loaded (first scan only).
  preparingScanner('Preparing the scanner…'),

  /// On this device: the page is searched for text and math and read.
  readingOnDevice('Reading text and math…'),

  /// On this device: the recognized text and math become Braille.
  convertingToBraille('Converting to Braille…');

  const ScanStage(this.label);

  /// Shown under the Braille cells and read by TalkBack.
  final String label;
}
