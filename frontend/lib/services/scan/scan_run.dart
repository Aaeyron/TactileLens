/// Which scan the scan screen is waiting for.
///
/// Cancel only stops waiting: the online request is not aborted, and the
/// server finishes the scan (and saves it to History). A result or error
/// that arrives for a scan that is no longer current is dropped.
/// See "Cancelling a scan" in docs/architecture.md.
class ScanRun {
  /// Shown after Cancel on an online scan. The server allows one scan at
  /// a time per user and online scans can take up to about 2 minutes.
  static const String cancelledOnlineMessage =
      'This scan will finish in the background; you can scan again in '
      'about 2 minutes.';

  int _current = 0;
  bool _cancelled = false;

  /// Starts waiting for a new scan and returns its id.
  int start() {
    _cancelled = false;
    return ++_current;
  }

  /// Stops waiting for the current scan.
  void cancel() {
    _cancelled = true;
  }

  /// Whether scan [id] is still the one being waited for.
  bool isCurrent(int id) => id == _current && !_cancelled;
}
