import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../models/ai/scan_processing_mode.dart';
import '../../styles/widgets/scan/scan_progress_overlay_styles.dart';

/// The wait while a page is scanned: a calm card over the dimmed page with
/// four still Braille cells spelling "scan" (⠎⠉⠁⠝) and a thin progress bar,
/// the only thing that moves. It shows no progress the app does not know.
///
/// TalkBack hears "Scanning, please wait" once when it appears and "Scan
/// complete" from [ScanProgressOverlayState.finish]; the cells and the bar
/// are not in the semantics tree. With reduce motion the bar is not shown
/// and nothing moves.
class ScanProgressOverlay extends StatefulWidget {
  const ScanProgressOverlay({super.key, required this.mode, this.onCancel});

  static const String cancelLabel = 'Cancel';
  static const String cancelSemanticsLabel = 'Cancel scan';

  /// Where the page is being scanned; shown under the main line.
  final ScanProcessingMode mode;

  /// Shows a Cancel button while scanning. Cancel only stops waiting; the
  /// caller tells the teacher what happens to the scan.
  final VoidCallback? onCancel;

  @override
  State<ScanProgressOverlay> createState() => ScanProgressOverlayState();
}

class ScanProgressOverlayState extends State<ScanProgressOverlay> {
  Timer? _stillWorkingTimer;
  bool _stillWorking = false;
  bool _finished = false;
  bool _announcedStart = false;

  @override
  void initState() {
    super.initState();

    _stillWorkingTimer = Timer(ScanProgressOverlayStyles.stillWorkingAfter, () {
      if (mounted) {
        setState(() => _stillWorking = true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_announcedStart) {
      _announcedStart = true;
      _announce(ScanProgressOverlayStyles.scanningAnnouncement);
    }
  }

  @override
  void dispose() {
    _stillWorkingTimer?.cancel();
    super.dispose();
  }

  /// The result is ready: tell TalkBack and stop the progress bar.
  /// Completes after one frame, when the result can be shown. Calling it
  /// again returns the same future.
  Future<void> finish() {
    if (!mounted) {
      return Future<void>.value();
    }

    return _finishing ??= _finish();
  }

  Future<void>? _finishing;

  Future<void> _finish() async {
    _finished = true;
    _stillWorkingTimer?.cancel();
    _announce(ScanProgressOverlayStyles.completeAnnouncement);

    setState(() {});
    // One frame, so the live region update reaches TalkBack.
    await WidgetsBinding.instance.endOfFrame;
  }

  bool get _usesAnnouncements => MediaQuery.supportsAnnounceOf(context);

  void _announce(String message) {
    // Where the platform supports announcements they are sent directly.
    // Android does not: there the status line is a live region, which
    // TalkBack reads when it appears and when its text changes.
    if (_usesAnnouncements) {
      unawaited(
        SemanticsService.sendAnnouncement(
          View.of(context),
          message,
          Directionality.of(context),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String status = _finished
        ? ScanProgressOverlayStyles.completeAnnouncement
        : ScanProgressOverlayStyles.scanningAnnouncement;
    final bool showBar = !_finished && !MediaQuery.disableAnimationsOf(context);

    return BlockSemantics(
      child: ColoredBox(
        color: ScanProgressOverlayStyles.scrimColor,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: ScanProgressOverlayStyles.screenPadding,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: ScanProgressOverlayStyles.cardMaxWidth,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: ScanProgressOverlayStyles.cardColor,
                        borderRadius: ScanProgressOverlayStyles.cardRadius,
                        border: Border.all(
                          color: ScanProgressOverlayStyles.cardBorderColor,
                        ),
                      ),
                      child: Padding(
                        padding: ScanProgressOverlayStyles.cardPadding,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const ExcludeSemantics(
                              child: CustomPaint(
                                size: _BrailleCellsPainter.size,
                                painter: _BrailleCellsPainter(),
                              ),
                            ),
                            const SizedBox(
                              height:
                                  ScanProgressOverlayStyles.cellsToBarSpacing,
                            ),
                            // Same height with or without the bar, so the
                            // card does not jump when the scan finishes.
                            SizedBox(
                              key: const ValueKey<String>('scan-progress-bar'),
                              width: _BrailleCellsPainter.size.width,
                              height: ScanProgressOverlayStyles.barHeight,
                              child: showBar
                                  ? const ExcludeSemantics(
                                      child: ClipRRect(
                                        borderRadius:
                                            ScanProgressOverlayStyles.barRadius,
                                        child: LinearProgressIndicator(
                                          minHeight: ScanProgressOverlayStyles
                                              .barHeight,
                                          color: ScanProgressOverlayStyles
                                              .barColor,
                                          backgroundColor:
                                              ScanProgressOverlayStyles
                                                  .barTrackColor,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(
                              height:
                                  ScanProgressOverlayStyles.barToTextSpacing,
                            ),
                            Semantics(
                              key: const ValueKey<String>('scan-status'),
                              liveRegion: !_usesAnnouncements,
                              label: status,
                              child: const ExcludeSemantics(
                                child: Text(
                                  ScanProgressOverlayStyles.scanningLabel,
                                  textAlign: TextAlign.center,
                                  style: ScanProgressOverlayStyles
                                      .scanningTextStyle,
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: ScanProgressOverlayStyles.lineSpacing,
                            ),
                            Text(
                              widget.mode == ScanProcessingMode.online
                                  ? ScanProgressOverlayStyles.onlineLabel
                                  : ScanProgressOverlayStyles.onDeviceLabel,
                              textAlign: TextAlign.center,
                              style: ScanProgressOverlayStyles.modeTextStyle,
                            ),
                            if (_stillWorking && !_finished) ...<Widget>[
                              const SizedBox(
                                height: ScanProgressOverlayStyles.lineSpacing,
                              ),
                              const Text(
                                ScanProgressOverlayStyles.stillWorkingLabel,
                                textAlign: TextAlign.center,
                                style: ScanProgressOverlayStyles
                                    .stillWorkingTextStyle,
                              ),
                            ],
                            if (widget.onCancel != null &&
                                !_finished) ...<Widget>[
                              const SizedBox(
                                height: ScanProgressOverlayStyles.cancelSpacing,
                              ),
                              Semantics(
                                button: true,
                                label: ScanProgressOverlay.cancelSemanticsLabel,
                                excludeSemantics: true,
                                child: TextButton(
                                  style: ScanProgressOverlayStyles
                                      .cancelButtonStyle,
                                  onPressed: widget.onCancel,
                                  child: const Text(
                                    ScanProgressOverlay.cancelLabel,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Four still Braille cells spelling "scan", every dot raised. Dots
/// numbered as in Braille: 1-3 down the left column, 4-6 down the right.
class _BrailleCellsPainter extends CustomPainter {
  const _BrailleCellsPainter();

  /// s = 2 3 4, c = 1 4, a = 1, n = 1 3 4 5.
  static const List<Set<int>> _word = <Set<int>>[
    <int>{2, 3, 4},
    <int>{1, 4},
    <int>{1},
    <int>{1, 3, 4, 5},
  ];

  static const int _cells = 4;

  static const double _dot = ScanProgressOverlayStyles.dotRadius;
  static const double _step = ScanProgressOverlayStyles.dotSpacing;
  static const double _cellGap = ScanProgressOverlayStyles.cellSpacing;
  static const double _cellWidth = 2 * _dot + _step;

  /// Room for the dot shadow on every side.
  static const double _margin = _dot * 1.5;

  static const Size size = Size(
    _cells * _cellWidth + (_cells - 1) * _cellGap + 2 * _margin,
    2 * _dot + 2 * _step + 2 * _margin,
  );

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final Paint raisedPaint = Paint()
      ..color = ScanProgressOverlayStyles.raisedDotColor;
    final Paint shadowPaint = Paint()
      ..color = ScanProgressOverlayStyles.dotShadowColor;
    final Paint emptyPaint = Paint()
      ..color = ScanProgressOverlayStyles.emptyDotColor;

    const Offset lift = Offset(0, ScanProgressOverlayStyles.dotLift);

    for (int cell = 0; cell < _word.length; cell++) {
      final double left = _margin + cell * (_cellWidth + _cellGap) + _dot;

      for (int dotNumber = 1; dotNumber <= 6; dotNumber++) {
        final Offset center = Offset(
          left + (dotNumber <= 3 ? 0 : _step),
          _margin + _dot + ((dotNumber - 1) % 3) * _step,
        );

        if (!_word[cell].contains(dotNumber)) {
          canvas.drawCircle(
            center,
            ScanProgressOverlayStyles.flatDotRadius,
            emptyPaint,
          );
          continue;
        }

        canvas.drawCircle(center + lift, _dot, shadowPaint);
        canvas.drawCircle(center - lift / 2, _dot, raisedPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_BrailleCellsPainter oldDelegate) => false;
}
