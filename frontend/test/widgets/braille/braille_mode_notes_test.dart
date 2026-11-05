import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/braille/braille_mode.dart';
import 'package:mobile/styles/widgets/braille/braille_mode_selector_styles.dart';
import 'package:mobile/widgets/braille/braille_mode_selector.dart';

Widget _host(Widget child, {double width = 360, double textScale = 1}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(width, 900),
        textScaler: TextScaler.linear(textScale),
      ),
      child: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}

BrailleModeSelector _selector({
  bool fallback = false,
  BrailleMode? savedMode,
  BrailleModeSelectorLayout layout = BrailleModeSelectorLayout.buttons,
}) {
  return BrailleModeSelector(
    selected: BrailleMode.contracted,
    onChanged: (_) {},
    showFallbackNote: fallback,
    savedMode: savedMode,
    layout: layout,
  );
}

void main() {
  group('Braille 1 fallback note', () {
    testWidgets('is a banner with an icon that says Braille 2 is shown', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(_selector(fallback: true)));

      expect(find.text(BrailleModeSelectorStyles.fallbackNote), findsOneWidget);
      expect(BrailleModeSelectorStyles.fallbackNote, contains('Braille 2'));
      expect(
        find.byIcon(BrailleModeSelectorStyles.fallbackIcon),
        findsOneWidget,
      );

      final Finder banner = find.byKey(BrailleModeSelector.fallbackBannerKey);
      expect(banner, findsOneWidget);
      final DecoratedBox box = tester.widget<DecoratedBox>(
        find.descendant(of: banner, matching: find.byType(DecoratedBox)).first,
      );
      expect(
        (box.decoration as BoxDecoration).color,
        BrailleModeSelectorStyles.fallbackBackgroundColor,
      );
    });

    testWidgets('is announced by screen readers (live region)', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.pumpWidget(_host(_selector(fallback: true)));

      expect(
        tester.getSemantics(find.text(BrailleModeSelectorStyles.fallbackNote)),
        matchesSemantics(
          label: BrailleModeSelectorStyles.fallbackNote,
          isLiveRegion: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('is not shown when Braille 1 worked', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(_selector()));

      expect(find.text(BrailleModeSelectorStyles.fallbackNote), findsNothing);
      expect(find.byKey(BrailleModeSelector.fallbackBannerKey), findsNothing);
    });
  });

  group('saved grade', () {
    testWidgets('a saved record says which grade it was saved in', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(_selector(savedMode: BrailleMode.contracted)),
      );
      expect(find.text('Saved in Braille 2 (Contracted)'), findsOneWidget);

      await tester.pumpWidget(
        _host(_selector(savedMode: BrailleMode.uncontracted)),
      );
      expect(find.text('Saved in Braille 1 (Spell Out)'), findsOneWidget);
    });

    testWidgets('a result that is not a saved record shows no grade line', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(_selector()));

      expect(find.textContaining('Saved in Braille'), findsNothing);
    });

    testWidgets('the chips layout shows it too', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          _selector(
            savedMode: BrailleMode.contracted,
            layout: BrailleModeSelectorLayout.chips,
          ),
        ),
      );

      expect(find.text('Saved in Braille 2 (Contracted)'), findsOneWidget);
    });
  });

  testWidgets('banner and saved grade fit a small phone at 2x text', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(640, 1136);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(
        _selector(fallback: true, savedMode: BrailleMode.uncontracted),
        width: 320,
        textScale: 2,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text(BrailleModeSelectorStyles.fallbackNote), findsOneWidget);
    expect(find.text('Saved in Braille 1 (Spell Out)'), findsOneWidget);
  });
}
