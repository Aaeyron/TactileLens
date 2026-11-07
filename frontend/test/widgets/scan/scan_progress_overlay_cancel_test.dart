import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/ai/scan_processing_mode.dart';
import 'package:mobile/services/scan/scan_run.dart';
import 'package:mobile/widgets/scan/scan_progress_overlay.dart';

Future<GlobalKey<ScanProgressOverlayState>> _pump(
  WidgetTester tester, {
  VoidCallback? onCancel,
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(320 * 3, 568 * 3);
  addTearDown(tester.view.reset);

  final GlobalKey<ScanProgressOverlayState> key =
      GlobalKey<ScanProgressOverlayState>();

  await tester.pumpWidget(
    MaterialApp(
      builder: (BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: true,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: ScanProgressOverlay(
          key: key,
          mode: ScanProcessingMode.online,
          onCancel: onCancel,
        ),
      ),
    ),
  );
  await tester.pump();

  return key;
}

void main() {
  group('Cancel on the scanning overlay', () {
    testWidgets('is not shown without a cancel handler', (
      WidgetTester tester,
    ) async {
      await _pump(tester);

      expect(find.text(ScanProgressOverlay.cancelLabel), findsNothing);
    });

    testWidgets('is a 48 dp button TalkBack can find, and calls back', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      int cancels = 0;

      await _pump(tester, onCancel: () => cancels++);

      final Finder button = find.bySemanticsLabel(
        ScanProgressOverlay.cancelSemanticsLabel,
      );
      expect(button, findsOneWidget);

      final Size size = tester.getSize(
        find.ancestor(
          of: find.text(ScanProgressOverlay.cancelLabel),
          matching: find.byType(TextButton),
        ),
      );
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));

      await tester.tap(find.text(ScanProgressOverlay.cancelLabel));
      expect(cancels, 1);

      semantics.dispose();
    });

    testWidgets('is hidden once the result is ready', (
      WidgetTester tester,
    ) async {
      final GlobalKey<ScanProgressOverlayState> key = await _pump(
        tester,
        onCancel: () {},
      );

      // finish() waits for a frame, so pump while it runs.
      final Future<void> finishing = key.currentState!.finish();
      await tester.pump();
      await tester.pump();
      await finishing;
      await tester.pump();

      expect(find.text(ScanProgressOverlay.cancelLabel), findsNothing);
    });

    testWidgets('fits a 320x568 phone at 2x text', (WidgetTester tester) async {
      await _pump(tester, onCancel: () {}, textScale: 2);

      expect(tester.takeException(), isNull);
      expect(find.text(ScanProgressOverlay.cancelLabel), findsOneWidget);
    });
  });

  group('ScanRun', () {
    test('only the latest scan is current', () {
      final ScanRun run = ScanRun();

      final int first = run.start();
      expect(run.isCurrent(first), isTrue);

      final int second = run.start();
      expect(run.isCurrent(first), isFalse);
      expect(run.isCurrent(second), isTrue);
    });

    test('a cancelled scan is no longer current, so its result is dropped', () {
      final ScanRun run = ScanRun();
      final int scan = run.start();

      run.cancel();

      expect(run.isCurrent(scan), isFalse);
    });

    test('the message says what really happens', () {
      expect(
        ScanRun.cancelledOnlineMessage,
        'This scan will finish in the background; you can scan again in '
        'about 2 minutes.',
      );
    });
  });
}
