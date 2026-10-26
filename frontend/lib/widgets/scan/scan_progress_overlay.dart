import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../models/ai/scan_processing_mode.dart';
import '../../styles/widgets/scan/scan_progress_overlay_styles.dart';

/// The wait while a page is scanned: a soft beam sweeps down the dimmed
/// page and four Braille cells rise, dot by dot, to spell "scan" (⠎⠉⠁⠝),
/// then settle and start again. It loops calmly for as long as the scan
/// takes and shows no progress the app does not know.
///
/// TalkBack hears "Scanning, please wait" once when it appears and "Scan
/// complete" from [ScanProgressOverlayState.finish]; the animation itself
/// is not in the semantics tree. With reduce motion the cells are shown
/// raised and nothing moves.
class ScanProgressOverlay extends StatefulWidget {
  const ScanProgressOverlay({super.key, required this.mode});

  /// Where the page is being scanned; shown under the main line.
  final ScanProcessingMode mode;

  @override
  State<ScanProgressOverlay> createState() => ScanProgressOverlayState();
}

enum _Phase { looping, finishing, still }

class ScanProgressOverlayState extends State<ScanProgressOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: ScanProgressOverlayStyles.loopDuration,
  );

  Timer? _stillWorkingTimer;
  bool _stillWorking = false;
  bool _finished = false;
  _Phase _phase = _Phase.looping;
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

    if (_phase != _Phase.finishing) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.stop();
        _phase = _Phase.still;
      } else {
        _phase = _Phase.looping;
        if (!_controller.isAnimating) {
          unawaited(_controller.repeat());
        }
      }
    }

    if (!_announcedStart) {
      _announcedStart = true;
      _announce(ScanProgressOverlayStyles.scanningAnnouncement);
    }
  }

  @override
  void dispose() {
    _stillWorkingTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// The result is ready: tell TalkBack and, unless reduce motion is on,
  /// raise every dot in one gentle pulse. Completes when the result can be
  /// shown. Calling it again returns the same pulse.
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

    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() {});
      // One frame, so the live region update reaches TalkBack.
      await WidgetsBinding.instance.endOfFrame;
      return;
    }

    setState(() => _phase = _Phase.finishing);
    _controller
      ..stop()
      ..duration = ScanProgressOverlayStyles.finishDuration;

    try {
      await _controller.forward(from: 0).orCancel;
    } on TickerCanceled {
      // Disposed during the pulse; nothing left to show.
    }
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

    return BlockSemantics(
      child: ColoredBox(
        color: ScanProgressOverlayStyles.scrimColor,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ExcludeSemantics(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _BeamPainter(
                    animation: _controller,
                    visible: _phase == _Phase.looping,
                  ),
                ),
              ),
            ),
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
                            ExcludeSemantics(
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  size: _BrailleCellsPainter.size,
                                  painter: _BrailleCellsPainter(
                                    animation: _controller,
                                    phase: _phase,
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

/// A soft band of light moving down the page. Off screen between sweeps.
class _BeamPainter extends CustomPainter {
  _BeamPainter({required this.animation, required this.visible})
    : super(repaint: animation);

  final Animation<double> animation;
  final bool visible;

  @override
  void paint(Canvas canvas, Size size) {
    if (!visible) {
      return;
    }

    final double t = animation.value;

    if (t > ScanProgressOverlayStyles.sweepEnd) {
      return;
    }

    const double band = ScanProgressOverlayStyles.beamHeight;
    final double sweep = Curves.easeInOut.transform(
      t / ScanProgressOverlayStyles.sweepEnd,
    );
    final double center = -band / 2 + sweep * (size.height + band);
    final Rect rect = Rect.fromLTWH(0, center - band / 2, size.width, band);

    final Color glow = ScanProgressOverlayStyles.beamColor.withValues(
      alpha: ScanProgressOverlayStyles.beamMaxOpacity,
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            glow.withValues(alpha: 0),
            glow,
            glow.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, center),
        width: size.width,
        height: ScanProgressOverlayStyles.beamLineHeight,
      ),
      Paint()
        ..color = ScanProgressOverlayStyles.beamLineColor.withValues(
          alpha: ScanProgressOverlayStyles.beamLineOpacity,
        ),
    );
  }

  @override
  bool shouldRepaint(_BeamPainter oldDelegate) {
    return oldDelegate.visible != visible || oldDelegate.animation != animation;
  }
}

/// Four Braille cells spelling "scan". Dots numbered as in Braille: 1-3
/// down the left column, 4-6 down the right.
class _BrailleCellsPainter extends CustomPainter {
  _BrailleCellsPainter({required this.animation, required this.phase})
    : super(repaint: animation);

  final Animation<double> animation;
  final _Phase phase;

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

  /// Room for the pulse and the dot shadow on every side.
  static const double _margin = _dot * 1.5;

  static const Size size = Size(
    _cells * _cellWidth + (_cells - 1) * _cellGap + 2 * _margin,
    2 * _dot + 2 * _step + 2 * _margin,
  );

  /// How far dot [dotNumber] of cell [cell] is raised, 0 (flat) to 1.
  double _raise(int cell, int dotNumber, double t) {
    if (phase != _Phase.looping) {
      return 1;
    }

    final double settle = t <= ScanProgressOverlayStyles.settleStart
        ? 1
        : 1 -
              Curves.easeInOut.transform(
                (t - ScanProgressOverlayStyles.settleStart) /
                    (1 - ScanProgressOverlayStyles.settleStart),
              );

    // Cells wake up left to right while the beam passes, dots in order.
    final double sweep = math.min(t / ScanProgressOverlayStyles.sweepEnd, 1);
    final double start = 0.06 + cell * 0.13 + (dotNumber - 1) * 0.02;
    final double rise = ((sweep - start) / 0.12).clamp(0.0, 1.0);

    return Curves.easeOutCubic.transform(rise) * settle;
  }

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final double t = animation.value;
    final double pulse = phase == _Phase.finishing
        ? math.sin(math.pi * t) * ScanProgressOverlayStyles.finishPulseScale
        : 0;

    final Paint raisedPaint = Paint()
      ..color = ScanProgressOverlayStyles.raisedDotColor;
    final Paint shadowPaint = Paint()
      ..color = ScanProgressOverlayStyles.dotShadowColor;
    final Paint flatPaint = Paint()
      ..color = ScanProgressOverlayStyles.flatDotColor;
    final Paint emptyPaint = Paint()
      ..color = ScanProgressOverlayStyles.emptyDotColor;

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

        final double raise = _raise(cell, dotNumber, t);

        if (raise <= 0) {
          canvas.drawCircle(
            center,
            ScanProgressOverlayStyles.flatDotRadius,
            flatPaint,
          );
          continue;
        }

        final double radius =
            (ScanProgressOverlayStyles.flatDotRadius +
                (_dot - ScanProgressOverlayStyles.flatDotRadius) * raise) *
            (1 + pulse);
        final double lift = ScanProgressOverlayStyles.dotLift * raise;

        canvas.drawCircle(center + Offset(0, lift), radius, shadowPaint);
        canvas.drawCircle(
          center - Offset(0, lift / 2),
          radius,
          raisedPaint
            ..color = Color.lerp(
              ScanProgressOverlayStyles.flatDotColor,
              ScanProgressOverlayStyles.raisedDotColor,
              raise,
            )!,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BrailleCellsPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.animation != animation;
  }
}
