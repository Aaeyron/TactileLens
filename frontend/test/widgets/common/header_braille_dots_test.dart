import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/styles/widgets/common/header_braille_dots_styles.dart';
import 'package:mobile/widgets/common/header_braille_dots.dart';

void main() {
  testWidgets('a 4x3 grid of dots, fixed size', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: HeaderBrailleDots()),
      ),
    );

    expect(tester.getSize(find.byType(HeaderBrailleDots)), const Size(37, 26));
    expect(
      find.descendant(
        of: find.byType(HeaderBrailleDots),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
      ),
      findsNWidgets(
        HeaderBrailleDotsStyles.columns * HeaderBrailleDotsStyles.rows,
      ),
    );
    // Decorative and still: no animation widgets.
    expect(
      find.descendant(
        of: find.byType(HeaderBrailleDots),
        matching: find.byWidgetPredicate(
          (Widget w) => w is ImplicitlyAnimatedWidget,
        ),
      ),
      findsNothing,
    );
  });

  testWidgets('decorative: nothing for screen readers, not tappable', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              const Text('Settings'),
              const HeaderBrailleDots(),
            ],
          ),
        ),
      ),
    );

    // Hidden from screen readers and pointers; the page text still reads.
    expect(
      find.descendant(
        of: find.byType(HeaderBrailleDots),
        matching: find.byType(ExcludeSemantics),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(HeaderBrailleDots),
        matching: find.byType(IgnorePointer),
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Settings'), findsOneWidget);

    semantics.dispose();
  });
}
