import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/widgets/scan/scan_busy_indicator.dart';

Widget _host({required bool reduceMotion}) {
  return MaterialApp(
    builder: (BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: child!,
    ),
    home: const Scaffold(
      body: Center(
        child: SizedBox.square(
          dimension: 32,
          child: ScanBusyIndicator(strokeWidth: 3, color: Colors.blue),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('spins normally', (WidgetTester tester) async {
    await tester.pumpWidget(_host(reduceMotion: false));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('reduce motion: a still hourglass, nothing moves', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(reduceMotion: true));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
    expect(tester.getSize(find.byType(Icon)).width, 32);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  test(
    'the scan screen follows reduce motion for every animation it keeps',
    () {
      final String screen = File(
        'lib/screens/scan/scan_screen.dart',
      ).readAsStringSync();
      final String camera = File(
        'lib/widgets/scan/scan_camera_preview.dart',
      ).readAsStringSync();

      // Orientation-follow of the two message pills.
      expect(
        screen,
        isNot(
          contains('duration: ScanScreenStyles.orientationAnimationDuration'),
        ),
      );
      expect('duration: orientationDuration,'.allMatches(screen).length, 4);
      // Side controls and the capture button.
      expect(
        screen,
        isNot(contains('duration: const Duration(milliseconds: 180),')),
      );
      expect(screen, isNot(contains('CircularProgressIndicator(')));
      expect(screen, contains('ScanBusyIndicator('));
      // Camera starting.
      expect(camera, isNot(contains('CircularProgressIndicator(')));
      expect(camera, contains('ScanBusyIndicator('));
    },
  );
}
