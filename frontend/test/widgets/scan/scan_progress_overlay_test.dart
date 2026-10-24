import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/ai/scan_processing_mode.dart';
import 'package:mobile/widgets/scan/scan_progress_overlay.dart';

const String _scanning = 'Scanning your document…';
const String _stillWorking = 'Still working, large pages take longer.';
const String _startAnnouncement = 'Scanning, please wait';
const String _doneAnnouncement = 'Scan complete';

/// Hosts the overlay the way the scan screen does: shown while
/// [showing] is true, inside the camera area.
class _Host {
  final ValueNotifier<bool> showing = ValueNotifier<bool>(true);
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
                if (show) ScanProgressOverlay(key: key, mode: mode),
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
    // The loop is running.
    expect(tester.binding.hasScheduledFrame, isTrue);

    await tester.pumpWidget(host.build(mode: ScanProcessingMode.onDevice));
    expect(find.text('On this device'), findsOneWidget);
  });

  testWidgets('loops for a long wait without stopping', (
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

    // The result is ready: a short pulse (about 300 ms), then the overlay
    // goes away.
    bool finished = false;
    host.key.currentState!.finish().then((_) => finished = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(finished, isFalse);
    expect(await _pumpUntilFinished(tester, host), lessThanOrEqualTo(350));
    expect(finished, isTrue);

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

  test('the scan screen uses this overlay', () {
    final String source = File(
      'lib/screens/scan/scan_screen.dart',
    ).readAsStringSync().replaceAll('\r\n', '\n');

    expect(
      source,
      contains('ScanProgressOverlay(key: _progressKey, mode: _processingMode)'),
    );
    expect(source, contains('await _progressKey.currentState?.finish();'));
    expect(source, isNot(contains('_ProcessingOverlay')));
  });
}
