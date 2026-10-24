import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:mobile/utils/slide_page_transitions.dart';

const Key _firstPage = Key('first page');
const Key _secondPage = Key('second page');

/// Two screens in the app's real theme; the button pushes the second.
Widget _app() {
  return MaterialApp(
    theme: appTheme(),
    home: Builder(
      builder: (BuildContext context) => Scaffold(
        key: _firstPage,
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) =>
                    const Scaffold(key: _secondPage, body: Text('Second')),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

/// The transition widgets between the route and [page].
List<Widget> _transitionsAbove(WidgetTester tester, Key page) {
  return tester
      .widgetList(
        find.ancestor(
          of: find.byKey(page),
          matching: find.byWidgetPredicate(
            (Widget widget) =>
                widget is SlideTransition ||
                widget is FadeTransition ||
                widget is ScaleTransition,
          ),
        ),
      )
      .toList();
}

double _slideX(WidgetTester tester, Key page) {
  final SlideTransition slide = _transitionsAbove(
    tester,
    page,
  ).whereType<SlideTransition>().single;

  return slide.position.value.dx;
}

void main() {
  test('every platform uses the slide', () {
    final PageTransitionsTheme theme = appTheme().pageTransitionsTheme;

    for (final TargetPlatform platform in TargetPlatform.values) {
      expect(
        theme.builders[platform],
        isA<SlidePageTransitionsBuilder>(),
        reason: platform.name,
      );
    }
  });

  testWidgets(
    'push slides in from the right and pop slides out to the right, '
    'with no fade or scale',
    (WidgetTester tester) async {
      await tester.pumpWidget(_app());
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Mid-push: only a horizontal slide, coming from the right.
      final List<Widget> pushing = _transitionsAbove(tester, _secondPage);
      expect(pushing, hasLength(1));
      expect(pushing.single, isA<SlideTransition>());
      expect(_slideX(tester, _secondPage), inExclusiveRange(0, 1));
      expect((pushing.single as SlideTransition).position.value.dy, 0);

      // The screen underneath does not fade or scale either.
      expect(
        _transitionsAbove(
          tester,
          _firstPage,
        ).where((Widget widget) => widget is! SlideTransition),
        isEmpty,
      );

      await tester.pumpAndSettle();
      expect(_slideX(tester, _secondPage), 0);

      // Mid-pop: sliding back out to the right.
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final List<Widget> popping = _transitionsAbove(tester, _secondPage);
      expect(popping, hasLength(1));
      expect(popping.single, isA<SlideTransition>());
      expect(_slideX(tester, _secondPage), inExclusiveRange(0, 1));

      await tester.pumpAndSettle();
      expect(find.byKey(_secondPage), findsNothing);
      expect(find.byKey(_firstPage), findsOneWidget);
    },
    variant: TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets('reduced motion switches screens instantly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: _app(),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(_transitionsAbove(tester, _secondPage), isEmpty);
  });
}
