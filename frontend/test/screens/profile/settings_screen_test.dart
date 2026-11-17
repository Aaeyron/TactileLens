import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/screens/profile/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps the Settings screen on a 320x568 phone with [textScale] and
/// returns the overflow messages it reported.
Future<List<String>> _pump(WidgetTester tester, double textScale) async {
  tester.view.physicalSize = const Size(640, 1136);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final List<String> overflows = <String>[];
  final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final String text = details.exceptionAsString();
    if (text.contains('overflowed')) {
      overflows.add(text.split('\n').first);
    }
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
      home: const SettingsScreen(),
    ),
  );
  await tester.pumpAndSettle();
  FlutterError.onError = previous;

  return overflows;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('Settings has no controls that do nothing', (
    WidgetTester tester,
  ) async {
    await _pump(tester, 1);

    // Text size, contrast, animations, haptics, recognition, layout and
    // auto-save were saved but never read anywhere; they are gone.
    expect(find.byType(Switch), findsNothing);
    expect(find.byType(DropdownButton<Object>), findsNothing);
    for (final String removed in <String>[
      'High Contrast',
      'Reduce Animations',
      'Haptic Feedback',
      'Recognition Preference',
      'Preserve Document Layout',
      'Automatically Save Scans',
    ]) {
      expect(find.text(removed), findsNothing, reason: removed);
    }

    // What is left does something, and the display line says the truth.
    expect(find.text('Default Braille Mode'), findsOneWidget);
    expect(find.text('Text Size and Display'), findsOneWidget);
    expect(find.textContaining("follows your phone's text size"), findsOneWidget);
  });

  for (final double scale in <double>[1, 2]) {
    testWidgets('Settings fits a 320x568 phone at ${scale}x text with 48 dp '
        'targets', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();

      final List<String> overflows = await _pump(tester, scale);

      expect(overflows, isEmpty);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      semantics.dispose();
    });
  }
}
