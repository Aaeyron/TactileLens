import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/screens/scan/scan_screen.dart';
import 'package:mobile/widgets/scan/scan_selection_overlay.dart';

/// Pumps [child] on a screen of [size] with [textScale] and returns the
/// overflow messages it reported.
Future<List<String>> _pump(
  WidgetTester tester,
  Widget child, {
  required Size size,
  required double textScale,
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final List<String> overflows = <String>[];
  final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final String text = details.exceptionAsString();
    if (text.contains('overflowed')) {
      overflows.add(text.split('\n').first);
    }
    // Missing camera/sensor plugins in tests are not layout problems.
  };
  addTearDown(() => FlutterError.onError = previous);

  await tester.pumpWidget(
    MaterialApp(
      builder: (BuildContext context, Widget? app) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: app!,
      ),
      home: child,
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
  FlutterError.onError = previous;

  return overflows;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  for (final ({String name, Size size, double text}) screen
      in <({String name, Size size, double text})>[
        (name: 'small phone 320x568', size: const Size(320, 568), text: 1),
        (
          name: 'small phone 320x568, 2x text',
          size: const Size(320, 568),
          text: 2,
        ),
        (name: 'phone 360x800, 2x text', size: const Size(360, 800), text: 2),
        (
          name: 'landscape window 568x320, 2x text',
          size: const Size(568, 320),
          text: 2,
        ),
        (name: 'landscape window 800x360', size: const Size(800, 360), text: 1),
        (
          name: 'tablet 800x1280, 2x text',
          size: const Size(800, 1280),
          text: 2,
        ),
        (
          name: 'tablet landscape 1280x800',
          size: const Size(1280, 800),
          text: 1,
        ),
      ]) {
    testWidgets('scan screen does not overflow: ${screen.name}', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();

      final List<String> overflows = await _pump(
        tester,
        ScanScreen(onBack: () {}),
        size: screen.size,
        textScale: screen.text,
      );

      expect(overflows, isEmpty);

      // The controls keep their labels and 48 dp targets.
      for (final String label in <String>['Upload', 'Flash']) {
        final Finder control = find.bySemanticsLabel(RegExp('^$label'));
        expect(control, findsWidgets, reason: label);
        final Size size = tester.getSize(control.first);
        expect(size.width, greaterThanOrEqualTo(48), reason: label);
        expect(size.height, greaterThanOrEqualTo(48), reason: label);
      }

      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    });
  }

  testWidgets('the crop Reset button is at least 48 dp', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 320,
            height: 400,
            child: ScanSelectionOverlay(
              onRegionSelected: (_) {},
              onSelectionCleared: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // The tappable area of the Reset button (its InkWell).
    final Finder reset = find.ancestor(
      of: find.text('Reset'),
      matching: find.byType(InkWell),
    );
    expect(reset, findsOneWidget);
    final Size size = tester.getSize(reset);
    expect(size.height, greaterThanOrEqualTo(48));
    expect(size.width, greaterThanOrEqualTo(48));
  });
}
