import 'dart:async';
import 'dart:ui' show PathMetric;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../models/ai/scan_processing_mode.dart';
import '../../models/ai/scan_stage.dart';
import '../../styles/widgets/scan/scan_progress_overlay_styles.dart';

/// The wait while a page is scanned: a calm card over the dimmed page.
///
/// Four Braille cells spelling "scan" (⠎⠉⠁⠝) are written dot by dot, one
/// cell at a time, then fade out softly and start again. Under them, one
/// line names the real step the scan is in ([stage]); nothing shows
/// progress the app does not know. When the result is ready,
/// [ScanProgressOverlayState.finish] fills every dot and shows a short check
/// mark.
///
/// TalkBack reads the step line when it appears and when the step changes,
/// and "Scan complete" at the end; the cells are not in the semantics tree.
/// With reduce motion nothing moves: the cells are shown still and only the
/// step line changes.
class ScanProgressOverlay extends StatefulWidget {
  const ScanProgressOverlay({
    super.key,
    required this.mode,
    this.onCancel,
    this.stage,
  });

  static const String cancelLabel = 'Cancel';
  static const String cancelSemanticsLabel = 'Cancel scan';

  /// Where the page is being scanned; shown under the step line.
  final ScanProcessingMode mode;

  /// Shows a Cancel button while scanning. Cancel only stops waiting; the
  /// caller tells the teacher what happens to the scan.
  final VoidCallback? onCancel;

  /// The real step of the scan, from the scanning services. Null (or no
  /// listenable) shows the general line until a step is known.
  final ValueListenable<ScanStage?>? stage;

  @override
  State<ScanProgressOverlay> createState() => ScanProgressOverlayState();
}

class ScanProgressOverlayState extends State<ScanProgressOverlay>
    with TickerProviderStateMixin {
  Timer? _stillWorkingTimer;
  bool _stillWorking = false;
  bool _finished = false;
  bool _announcedStart = false;
  ScanStage? _stage;

  /// One writing cycle: 0..1 repeats while the scan runs.
  late final AnimationController _writing = AnimationController(
    vsync: this,
    duration: ScanProgressOverlayStyles.writingCycle,
  );

  /// The check mark when the result is ready: 0..1 once.
  late final AnimationController _check = AnimationController(
    vsync: this,
    duration: ScanProgressOverlayStyles.checkDuration,
  );

  @override
  void initState() {
    super.initState();

    _stage = widget.stage?.value;
    widget.stage?.addListener(_onStage);

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
      _announce(
        _stage?.label ?? ScanProgressOverlayStyles.scanningAnnouncement,
      );
    }

    _syncMotion();
  }

  @override
  void didUpdateWidget(ScanProgressOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.stage != widget.stage) {
      oldWidget.stage?.removeListener(_onStage);
      widget.stage?.addListener(_onStage);
      _onStage();
    }
  }

  @override
  void dispose() {
    widget.stage?.removeListener(_onStage);
    _stillWorkingTimer?.cancel();
    _writing.dispose();
    _check.dispose();
    super.dispose();
  }

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  /// Writes only while the scan runs and motion is allowed.
  void _syncMotion() {
    final bool run = !_finished && !_reduceMotion;

    if (run && !_writing.isAnimating) {
      unawaited(_writing.repeat());
    } else if (!run && _writing.isAnimating) {
      _writing.stop();
    }
  }

  void _onStage() {
    final ScanStage? next = widget.stage?.value;

    if (!mounted || _finished || next == null || next == _stage) {
      return;
    }

    setState(() => _stage = next);
    _announce(next.label);
  }

  /// The result is ready: every dot filled, a short check mark (none with
  /// reduce motion), and "Scan complete" for TalkBack. Completes when the
  /// result can be shown. Calling it again returns the same future.
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
    _writing.stop();
    _announce(ScanProgressOverlayStyles.completeAnnouncement);

    setState(() {});

    if (_reduceMotion) {
      _check.value = 1;
    } else {
      await _check.forward().orCancel.catchError((Object _) {});
    }

    if (!mounted) {
      return;
    }

    // One frame, so the live region update reaches TalkBack.
    await WidgetsBinding.instance.endOfFrame;
  }

  bool get _usesAnnouncements => MediaQuery.supportsAnnounceOf(context);

  void _announce(String message) {
    // Where the platform supports announcements they are sent directly.
    // Android does not: there the step line is a live region, which
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
    // On screen the last step stays until the result opens (the check mark
    // shows it is done), so the card does not change size at the end.
    final String line =
        _stage?.label ?? ScanProgressOverlayStyles.scanningLabel;
    final String spoken = _finished
        ? ScanProgressOverlayStyles.completeAnnouncement
        : _stage?.label ?? ScanProgressOverlayStyles.scanningAnnouncement;

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
                    // Full width (up to the maximum), so step lines of
                    // different lengths do not resize the card.
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
                            // Takes the card's full width; nothing visible.
                            const SizedBox(width: double.infinity),
                            ExcludeSemantics(
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  key: const ValueKey<String>('scan-cells'),
                                  size: BrailleWritingPainter.size,
                                  painter: BrailleWritingPainter(
                                    writing: _writing,
                                    check: _check,
                                    still: _reduceMotion,
                                    finished: _finished,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height:
                                  ScanProgressOverlayStyles.cellsToTextSpacing,
                            ),
                            Semantics(
                              key: const ValueKey<String>('scan-status'),
                              liveRegion: !_usesAnnouncements,
                              label: spoken,
                              child: ExcludeSemantics(
                                child: Text(
                                  line,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
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

/// Four Braille cells spelling "scan", written dot by dot. Dots are
/// numbered as in Braille: 1-3 down the left column, 4-6 down the right.
/// Unraised positions stay as small faint white dots. Painted from the
/// animation values only (no widget rebuilds per frame).
@visibleForTesting
class BrailleWritingPainter extends CustomPainter {
  BrailleWritingPainter({
    required this.writing,
    required this.check,
    required this.still,
    required this.finished,
  }) : super(repaint: Listenable.merge(<Listenable>[writing, check]));

  /// s = 2 3 4, c = 1 4, a = 1, n = 1 3 4 5; each cell's dots in the order
  /// a hand writes them.
  static const List<List<int>> word = <List<int>>[
    <int>[2, 3, 4],
    <int>[1, 4],
    <int>[1],
    <int>[1, 3, 4, 5],
  ];

  final Animation<double> writing;
  final Animation<double> check;

  /// Reduce motion: every dot shown, nothing moves.
  final bool still;

  /// The scan is done: every dot shown and the check mark.
  final bool finished;

  static const double _dot = ScanProgressOverlayStyles.dotRadius;
  static const double _step = ScanProgressOverlayStyles.dotSpacing;
  static const double _cellGap = ScanProgressOverlayStyles.cellSpacing;
  static const double _cellWidth = 2 * _dot + _step;
  static const double _checkSlot = ScanProgressOverlayStyles.checkSize;

  /// Room for the dot shadow on every side.
  static const double _margin = _dot * 1.5;

  static const double _cellsWidth = 4 * _cellWidth + 3 * _cellGap + 2 * _margin;

  /// The cells only, so they stay centered. The check mark is drawn just
  /// right of them, inside the card's padding, so nothing moves when it
  /// appears.
  static const Size size = Size(
    _cellsWidth,
    2 * _dot + 2 * _step + 2 * _margin,
  );

  /// How much of dot [dotIndex] of [cell] is written at cycle time [t]
  /// (0..1): 0 not yet, 1 fully, with a soft ease-out; the whole word then
  /// fades together. Exposed for tests.
  static double dotAmount(int cell, int dotIndex, double t) {
    const double writeEnd = ScanProgressOverlayStyles.writePhaseEnd;
    const double holdEnd = ScanProgressOverlayStyles.holdPhaseEnd;
    const double fadeEnd = ScanProgressOverlayStyles.fadePhaseEnd;

    if (t >= fadeEnd) {
      return 0;
    }

    final double perCell = writeEnd / word.length;
    final double perDot = perCell / 4;
    final double start = cell * perCell + dotIndex * perDot;
    final double written = Curves.easeOutCubic.transform(
      ((t - start) / (perDot * 1.6)).clamp(0.0, 1.0),
    );

    if (t <= holdEnd) {
      return written;
    }

    final double fade = Curves.easeInOut.transform(
      ((t - holdEnd) / (fadeEnd - holdEnd)).clamp(0.0, 1.0),
    );
    return written * (1 - fade);
  }

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final Paint empty = Paint()
      ..color = ScanProgressOverlayStyles.emptyDotColor;
    final double t = writing.value;

    for (int cell = 0; cell < word.length; cell++) {
      final double left = _margin + cell * (_cellWidth + _cellGap) + _dot;

      for (int dotNumber = 1; dotNumber <= 6; dotNumber++) {
        final Offset center = Offset(
          left + (dotNumber <= 3 ? 0 : _step),
          _margin + _dot + ((dotNumber - 1) % 3) * _step,
        );

        // The empty position is always there, like the paper.
        canvas.drawCircle(
          center,
          ScanProgressOverlayStyles.flatDotRadius,
          empty,
        );

        final int order = word[cell].indexOf(dotNumber);
        if (order < 0) {
          continue;
        }

        final double amount = still || finished ? 1 : dotAmount(cell, order, t);
        if (amount <= 0) {
          continue;
        }

        final double radius = _dot * (0.6 + 0.4 * amount);
        final Offset lift = Offset(
          0,
          ScanProgressOverlayStyles.dotLift * amount,
        );
        canvas.drawCircle(
          center + lift,
          radius,
          Paint()
            ..color = ScanProgressOverlayStyles.dotShadowColor.withValues(
              alpha: ScanProgressOverlayStyles.dotShadowColor.a * amount,
            ),
        );
        canvas.drawCircle(
          center - lift / 2,
          radius,
          Paint()
            ..color = ScanProgressOverlayStyles.raisedDotColor.withValues(
              alpha: amount,
            ),
        );
      }
    }

    if (finished) {
      _paintCheck(canvas, check.value);
    }
  }

  /// The gold check mark in its slot, drawn on as [amount] goes 0..1.
  void _paintCheck(Canvas canvas, double amount) {
    if (amount <= 0) {
      return;
    }

    final double x0 = _cellsWidth + ScanProgressOverlayStyles.checkGap;
    final double cy = size.height / 2;
    const double s = _checkSlot;
    final Path tick = Path()
      ..moveTo(x0 + s * 0.12, cy + s * 0.02)
      ..lineTo(x0 + s * 0.40, cy + s * 0.28)
      ..lineTo(x0 + s * 0.90, cy - s * 0.26);

    final Paint stroke = Paint()
      ..color = ScanProgressOverlayStyles.checkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = ScanProgressOverlayStyles.checkStroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double eased = Curves.easeOutCubic.transform(amount);
    for (final PathMetric metric in tick.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * eased), stroke);
    }
  }

  @override
  bool shouldRepaint(BrailleWritingPainter oldDelegate) =>
      oldDelegate.still != still ||
      oldDelegate.finished != finished ||
      oldDelegate.writing != writing ||
      oldDelegate.check != check;
}
