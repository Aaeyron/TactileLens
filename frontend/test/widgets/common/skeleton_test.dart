import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/widgets/common/skeleton.dart';

const TextStyle _style = TextStyle(fontSize: 18, height: 1.3);

Widget _host({required bool disableAnimations, required Widget child}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 300, child: SkeletonScope(child: child)),
        ),
      ),
    ),
  );
}

const Widget _line = SkeletonLine(
  style: _style,
  widthFactor: 0.5,
  baseColor: Colors.grey,
  highlightColor: Colors.white,
);

void main() {
  testWidgets('shimmer keeps animating when motion is allowed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(disableAnimations: false, child: _line));
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('reduced motion draws a still skeleton', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(disableAnimations: true, child: _line));

    // Would time out if the shimmer were still repeating.
    await tester.pumpAndSettle();

    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('a skeleton line is as tall as one line of the real text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        disableAnimations: true,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _line,
            Text('Real text', key: Key('real'), maxLines: 1, style: _style),
          ],
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(SkeletonLine)).height,
      tester.getSize(find.byKey(const Key('real'))).height,
    );
    expect(tester.getSize(find.byType(SkeletonLine)).width, 150);
  });
}
