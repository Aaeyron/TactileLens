import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/ai/scan_processing_mode.dart';
import 'package:mobile/models/ai/scan_stage.dart';
import 'package:mobile/services/scan/scan_run.dart';
import 'package:mobile/styles/widgets/scan/scan_progress_overlay_styles.dart';
import 'package:mobile/widgets/scan/scan_progress_overlay.dart';

const String _scanning = 'Scanning your document…';
const String _stillWorking = 'Still working, large pages take longer.';
const String _startAnnouncement = 'Scanning, please wait';
const String _doneAnnouncement = 'Scan complete';

/// Hosts the overlay the way the scan screen does: shown while
/// [showing] is true, inside the camera area.
class _Host {
  final ValueNotifier<bool> showing = ValueNotifier<bool>(true);
  final ValueNotifier<ScanStage?> stage = ValueNotifier<ScanStage?>(null);
  final GlobalKey<ScanProgressOverlayState> key =
      GlobalKey<ScanProgressOverlayState>();

  Widget build({
    ScanProcessingMode mode = ScanProcessingMode.online,
    bool reduceMotion = false,
    bool supportsAnnounce = false,
    double textScale = 1,
  }) {
    return MaterialApp(
      builder: (BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduceMotion,
          supportsAnnounce: supportsAnnounce,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: ValueListenableBuilder<bool>(
          valueListenable: showing,
          builder: (BuildContext context, bool show, Widget? child) {
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const ColoredBox(color: Colors.white),
                if (show)
                  ScanProgressOverlay(key: key, mode: mode, stage: stage),
              ],
            );
          },
        ),
      ),
    );
  }
}

void _smallPhone(WidgetTester tester) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(320 * 3, 568 * 3);
  addTearDown(tester.view.reset);
}

/// Calls finish() if it has not run yet, and pumps frames until it
/// completes. Returns how many milliseconds of frames that took.
Future<int> _pumpUntilFinished(WidgetTester tester, _Host host) async {
  bool done = false;
  host.key.currentState!.finish().then((_) => done = true);

  int elapsed = 0;
  while (!done) {
    expect(elapsed, lessThan(2000), reason: 'finish() never completed');
    await tester.pump(const Duration(milliseconds: 25));
    elapsed += 25;
  }

  return elapsed;
}

/// Labels of every semantics node that has one, in tree order.
List<String> _labels(WidgetTester tester) {
  return find.semantics
      .byPredicate((SemanticsNode node) => node.label.isNotEmpty)
      .evaluate()
      .map((SemanticsNode node) => node.label)
      .toList();
}

void main() {
  testWidgets('shows while the scan runs, with the mode', (
    WidgetTester tester,
  ) async {
    final _Host host = _Host();

    await tester.pumpWidget(host.build());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ScanProgressOverlay), findsOneWidget);
    expect(find.text(_scanning), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text(_stillWorking), findsNothing);
    // The Braille cells are being written; the old progress bar is gone.
    expect(find.byKey(const ValueKey<String>('scan-cells')), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(tester.binding.hasScheduledFrame, isTrue);

    await tester.pumpWidget(host.build(mode: ScanProcessingMode.onDevice));
    expect(find.text('On this device'), findsOneWidget);
  });

  testWidgets('the Braille writing keeps going for a long wait', (
    WidgetTester tester,
  ) async {
    final _Host host = _Host();
    await tester.pumpWidget(host.build());

    // 150 s, about the longest online scan.
    for (int second = 0; second < 150; second++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(tester.binding.hasScheduledFrame, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Still working" appears after 20 s, not before', (
    WidgetTester tester,
  ) async {
    final _Host host = _Host();
    await tester.pumpWidget(host.build());

    await tester.pump(const Duration(seconds: 19));
    expect(find.text(_stillWorking), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text(_stillWorking), findsOneWidget);
  });

  testWidgets('stops when the result arrives', (WidgetTester tester) async {
    final _Host host = _Host();
    await tester.pumpWidget(host.build());
    await tester.pump(const Duration(seconds: 2));

    // The result is ready: every dot filled and a short check mark (under
    // 0.4 s), then the overlay can go away.
    expect(await _pumpUntilFinished(tester, host), lessThanOrEqualTo(400));

    host.showing.value = false;
    await tester.pump();

    expect(find.byType(ScanProgressOverlay), findsNothing);
    // Nothing keeps ticking.
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pump(const Duration(seconds: 30));
    expect(find.text(_stillWorking), findsNothing);
  });

  testWidgets('reduce motion shows a still version and finishes at once', (
    WidgetTester tester,
  ) async {
    final _Host host = _Host();
    await tester.pumpWidget(host.build(reduceMotion: true));
    await tester.pump();

    expect(find.text(_scanning), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pump(const Duration(seconds: 5));
    expect(tester.binding.hasScheduledFrame, isFalse);

    bool finished = false;
    host.key.currentState!.finish().then((_) => finished = true);
    await tester.pump();
    await tester.pump();
    expect(finished, isTrue);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  group('TalkBack', () {
    testWidgets('Android: a live region says "Scanning, please wait", '
        'then "Scan complete"; the animation is not read', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final _Host host = _Host();

      await tester.pumpWidget(host.build());
      await tester.pump(const Duration(seconds: 1));

      expect(
        tester.getSemantics(find.byKey(const ValueKey<String>('scan-status'))),
        isSemantics(label: _startAnnouncement, isLiveRegion: true),
      );
      // Only the status and the mode: the beam and dots are excluded.
      expect(_labels(tester), <String>[_startAnnouncement, 'Online']);
      // Android does not take one-off announcements.
      expect(tester.takeAnnouncements(), isEmpty);

      // Many frames later the label is unchanged, so it is read once.
      await tester.pump(const Duration(seconds: 10));
      expect(_labels(tester), <String>[_startAnnouncement, 'Online']);

      await _pumpUntilFinished(tester, host);

      expect(
        tester.getSemantics(find.byKey(const ValueKey<String>('scan-status'))),
        isSemantics(label: _doneAnnouncement, isLiveRegion: true),
      );
      semantics.dispose();
    });

    testWidgets('where announcements are supported: each is sent once', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final _Host host = _Host();

      await tester.pumpWidget(host.build(supportsAnnounce: true));
      for (int frame = 0; frame < 60; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(tester.takeAnnouncements().map((a) => a.message), <String>[
        _startAnnouncement,
      ]);

      await _pumpUntilFinished(tester, host);
      // A second call does nothing.
      await _pumpUntilFinished(tester, host);

      expect(tester.takeAnnouncements().map((a) => a.message), <String>[
        _doneAnnouncement,
      ]);
      semantics.dispose();
    });
  });

  testWidgets('fits a small phone at 2x text, with every line shown', (
    WidgetTester tester,
  ) async {
    _smallPhone(tester);
    final _Host host = _Host();

    await tester.pumpWidget(
      host.build(mode: ScanProcessingMode.onDevice, textScale: 2),
    );
    await tester.pump(const Duration(seconds: 21));

    expect(find.text(_stillWorking), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      host.build(
        mode: ScanProcessingMode.onDevice,
        textScale: 2,
        reduceMotion: true,
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the card keeps its size when the scan finishes', (
    WidgetTester tester,
  ) async {
    final _Host host = _Host();
    await tester.pumpWidget(host.build());
    await tester.pump(const Duration(seconds: 1));
    final Size before = tester.getSize(find.byType(DecoratedBox).last);

    await _pumpUntilFinished(tester, host);
    expect(tester.getSize(find.byType(DecoratedBox).last), before);
  });

  test('no leftover effects: no beam or pulse in the overlay', () {
    final String source = File(
      'lib/widgets/scan/scan_progress_overlay.dart',
    ).readAsStringSync();

    for (final String gone in <String>[
      '_BeamPainter',
      'finishPulse',
      'LinearProgressIndicator',
    ]) {
      expect(source, isNot(contains(gone)), reason: gone);
    }
  });

  group('real steps', () {
    testWidgets('shows each step the scan reports, and TalkBack hears it', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final _Host host = _Host();
      await tester.pumpWidget(host.build(mode: ScanProcessingMode.onDevice));
      await tester.pump();

      // Before the first step: the general line.
      expect(find.text(_scanning), findsOneWidget);

      for (final ScanStage step in <ScanStage>[
        ScanStage.preparingScanner,
        ScanStage.readingOnDevice,
        ScanStage.convertingToBraille,
      ]) {
        host.stage.value = step;
        await tester.pump();

        expect(find.text(step.label), findsOneWidget);
        final SemanticsNode status = tester.getSemantics(
          find.byKey(const ValueKey<String>('scan-status')),
        );
        expect(status.label, step.label);
        // Android: a live region, read whenever the step changes.
        expect(status.flagsCollection.isLiveRegion, isTrue);
      }

      // Only the step line is read; the cells are not in the tree.
      expect(_labels(tester).where((String l) => l.contains('⠎')), isEmpty);

      await _pumpUntilFinished(tester, host);
      expect(
        tester
            .getSemantics(find.byKey(const ValueKey<String>('scan-status')))
            .label,
        _doneAnnouncement,
      );
      semantics.dispose();
    });

    testWidgets('where announcements are supported, each step is sent once', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final _Host host = _Host();
      await tester.pumpWidget(host.build(supportsAnnounce: true));
      await tester.pump();

      host.stage.value = ScanStage.checkingConnection;
      await tester.pump();
      // The same step again is not repeated.
      host.stage.value = ScanStage.checkingConnection;
      await tester.pump();
      host.stage.value = ScanStage.readingOnline;
      await tester.pump(const Duration(seconds: 3));

      expect(tester.takeAnnouncements().map((a) => a.message), <String>[
        _startAnnouncement,
        ScanStage.checkingConnection.label,
        ScanStage.readingOnline.label,
      ]);
      semantics.dispose();
    });

    testWidgets('reduce motion: still cells, the step line still changes', (
      WidgetTester tester,
    ) async {
      final _Host host = _Host();
      await tester.pumpWidget(host.build(reduceMotion: true));
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);

      host.stage.value = ScanStage.readingOnline;
      await tester.pump();
      expect(find.text(ScanStage.readingOnline.label), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('Braille writing', () {
    test('cells are written left to right, dot by dot, then fade out', () {
      double at(int cell, int dot, double t) =>
          BrailleWritingPainter.dotAmount(cell, dot, t);

      // Nothing at the start of a cycle.
      expect(at(0, 0, 0), 0);
      // The first cell starts before the second, and the second before the
      // last.
      expect(at(0, 0, 0.08), greaterThan(0));
      expect(at(1, 0, 0.08), 0);
      expect(at(3, 3, 0.4), 0);
      // Every dot is fully written during the hold.
      for (int cell = 0; cell < 4; cell++) {
        for (
          int dot = 0;
          dot < BrailleWritingPainter.word[cell].length;
          dot++
        ) {
          expect(at(cell, dot, 0.70), closeTo(1, 1e-9));
        }
      }
      // Soft fade out, then nothing before the next cycle.
      expect(at(0, 0, 0.83), allOf(greaterThan(0), lessThan(1)));
      expect(at(0, 0, 0.95), 0);
      // Smooth: no jump between neighbouring frames (60 fps).
      const double frame = 1 / (2.8 * 60);
      for (double t = 0; t < 1 - frame; t += frame) {
        expect(
          (at(1, 1, t + frame) - at(1, 1, t)).abs(),
          lessThan(0.35),
          reason: 't = $t',
        );
      }
    });

    test('white dots and the gold check stand out on the navy card', () {
      double contrast(Color a, Color b) {
        final double la = a.computeLuminance(), lb = b.computeLuminance();
        return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
      }

      // The card is slightly see-through; judge it at its darkest-likely
      // backdrop (black) and the brightest one (white camera frame).
      const Color card = ScanProgressOverlayStyles.cardColor;
      for (final Color backdrop in <Color>[Colors.black, Colors.white]) {
        final Color cardOn = Color.alphaBlend(card, backdrop);
        expect(
          contrast(ScanProgressOverlayStyles.raisedDotColor, cardOn),
          greaterThan(7),
        );
        expect(
          contrast(ScanProgressOverlayStyles.checkColor, cardOn),
          greaterThan(4.5),
        );
        // Unraised positions are a faint hint, clearly below the raised dots.
        final Color empty = Color.alphaBlend(
          ScanProgressOverlayStyles.emptyDotColor,
          cardOn,
        );
        expect(contrast(empty, cardOn), lessThan(3));
      }
    });

    test('the word is "scan" in Braille (s c a n)', () {
      expect(BrailleWritingPainter.word, <List<int>>[
        <int>[2, 3, 4],
        <int>[1, 4],
        <int>[1],
        <int>[1, 3, 4, 5],
      ]);
    });
  });

  test('the scan screen uses this overlay', () {
    final String source = File(
      'lib/screens/scan/scan_screen.dart',
    ).readAsStringSync().replaceAll('\r\n', '\n');

    expect(source, contains('ScanProgressOverlay(\n'));
    expect(source, contains('key: _progressKey,\n'));
    expect(source, contains('mode: _processingMode,\n'));
    // The real steps come from the scanning services.
    expect(source, contains('stage: _aiService.stage,'));
    // Cancel is offered for online scans only.
    expect(
      source,
      contains(
        'onCancel: _processingMode == ScanProcessingMode.online\n'
        '                  ? _cancelScan\n'
        '                  : null,',
      ),
    );
    expect(source, contains('await _progressKey.currentState?.finish();'));
    expect(source, isNot(contains('_ProcessingOverlay')));
  });

  test('the confirmation sheet states the same time limit as Cancel', () {
    final String source = File(
      'lib/screens/scan/scan_screen.dart',
    ).readAsStringSync();

    expect(
      ScanRun.processingTimeMessage,
      'Processing can take up to 3 minutes.',
    );
    expect(ScanRun.cancelledOnlineMessage, contains('up to 3 minutes'));
    expect(
      source,
      contains(
        'static const String processingDetail = '
        'ScanRun.processingTimeMessage;',
      ),
    );
    expect(source, isNot(contains('2 minutes')));
  });
}
