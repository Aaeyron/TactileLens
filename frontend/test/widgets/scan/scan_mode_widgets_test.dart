import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/ai/scan_processing_mode.dart';
import 'package:mobile/widgets/scan/scan_mode_widgets.dart';

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('Online / On-device selector', () {
    testWidgets('shows both choices and the hint for the selected one', (
      WidgetTester tester,
    ) async {
      ScanProcessingMode? chosen;

      await tester.pumpWidget(
        _host(
          ScanModeSelector(
            mode: ScanProcessingMode.online,
            onChanged: (ScanProcessingMode mode) => chosen = mode,
          ),
        ),
      );

      expect(find.text(ScanModeText.onlineLabel), findsOneWidget);
      expect(find.text(ScanModeText.onDeviceLabel), findsOneWidget);
      expect(find.text(ScanModeText.onlineHint), findsOneWidget);

      await tester.tap(find.text(ScanModeText.onDeviceLabel));
      expect(chosen, ScanProcessingMode.onDevice);
    });

    testWidgets('TalkBack hears which choice is selected', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        _host(
          ScanModeSelector(
            mode: ScanProcessingMode.onDevice,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text(ScanModeText.onDeviceHint), findsOneWidget);
      expect(
        tester.getSemantics(find.text(ScanModeText.onDeviceLabel)),
        isSemantics(isSelected: true, hasSelectedState: true, isButton: true),
      );
      expect(
        tester.getSemantics(find.text(ScanModeText.onlineLabel)),
        isSemantics(isSelected: false, hasSelectedState: true, isButton: true),
      );

      semantics.dispose();
    });

    testWidgets('each choice is at least 48 dp tall', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ScanModeSelector(mode: ScanProcessingMode.online, onChanged: (_) {}),
        ),
      );

      expect(
        tester.getSize(find.byType(SegmentedButton<ScanProcessingMode>)).height,
        greaterThanOrEqualTo(48),
      );
    });
  });

  group('privacy notice', () {
    Future<ScanProcessingMode?> openAndChoose(
      WidgetTester tester,
      Future<void> Function() choose,
    ) async {
      late Future<ScanProcessingMode?> result;

      await tester.pumpWidget(
        _host(
          Builder(
            builder: (BuildContext context) => TextButton(
              onPressed: () => result = showOnlinePrivacyNotice(context),
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Online scans are processed by a third-party service. For '
          'sensitive documents, use On-device.',
        ),
        findsOneWidget,
      );

      await choose();
      await tester.pumpAndSettle();

      return result;
    }

    testWidgets('Continue online returns Online', (WidgetTester tester) async {
      expect(
        await openAndChoose(
          tester,
          () => tester.tap(find.text(ScanModeText.continueOnline)),
        ),
        ScanProcessingMode.online,
      );
    });

    testWidgets('Use On-device returns On-device', (WidgetTester tester) async {
      expect(
        await openAndChoose(
          tester,
          () => tester.tap(find.text(ScanModeText.useOnDevice)),
        ),
        ScanProcessingMode.onDevice,
      );
    });

    testWidgets('closing it chooses nothing', (WidgetTester tester) async {
      // A tap outside the dialog, on the barrier.
      expect(
        await openAndChoose(tester, () => tester.tapAt(const Offset(4, 4))),
        isNull,
      );
    });

    testWidgets('TalkBack reads the notice and both buttons', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        _host(
          Builder(
            builder: (BuildContext context) => TextButton(
              onPressed: () => showOnlinePrivacyNotice(context),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(ScanModeText.privacyTitle), findsOneWidget);
      expect(
        find.bySemanticsLabel(ScanModeText.privacyMessage),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.text(ScanModeText.continueOnline)),
        isSemantics(isButton: true, label: ScanModeText.continueOnline),
      );
      expect(
        tester.getSemantics(find.text(ScanModeText.useOnDevice)),
        isSemantics(isButton: true, label: ScanModeText.useOnDevice),
      );

      semantics.dispose();
    });
  });
}
