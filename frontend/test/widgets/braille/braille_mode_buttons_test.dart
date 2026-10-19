import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/braille/braille_mode.dart';
import 'package:mobile/services/braille/braille_mode_translator.dart';
import 'package:mobile/styles/widgets/braille/braille_mode_selector_styles.dart';
import 'package:mobile/widgets/braille/braille_mode_selector.dart';
import 'package:mobile/widgets/braille/text_braille_copy_menu.dart';

const String _braille1 = BrailleModeSelectorStyles.uncontractedLabel;
const String _braille2 = BrailleModeSelectorStyles.contractedLabel;

Widget _host(Widget child, {double width = 360, double textScale = 1}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(width, 640),
        textScaler: TextScaler.linear(textScale),
      ),
      child: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}

Widget _buttons({
  BrailleMode selected = BrailleMode.contracted,
  BrailleModeAvailability availability = BrailleModeAvailability.available,
  bool showFallbackNote = false,
  ValueChanged<BrailleMode>? onChanged,
}) {
  return BrailleModeSelector(
    layout: BrailleModeSelectorLayout.buttons,
    selected: selected,
    availability: availability,
    showFallbackNote: showFallbackNote,
    onChanged: onChanged ?? (BrailleMode mode) {},
  );
}

Finder _filled(String label) => find.widgetWithText(FilledButton, label);
Finder _outlined(String label) => find.widgetWithText(OutlinedButton, label);

void main() {
  group('mode buttons', () {
    testWidgets(
      'the selected mode is filled with a check, the other outlined',
      (WidgetTester tester) async {
        await tester.pumpWidget(_host(_buttons()));

        expect(_filled(_braille2), findsOneWidget);
        expect(_outlined(_braille1), findsOneWidget);
        expect(_filled(_braille1), findsNothing);

        // Not by color alone: only the selected button carries the check.
        expect(
          find.descendant(
            of: _filled(_braille2),
            matching: find.byIcon(BrailleModeSelectorStyles.selectedIcon),
          ),
          findsOneWidget,
        );
        expect(
          find.byIcon(BrailleModeSelectorStyles.selectedIcon),
          findsOneWidget,
        );
      },
    );

    testWidgets('tapping a mode reports it', (WidgetTester tester) async {
      BrailleMode? chosen;

      await tester.pumpWidget(
        _host(_buttons(onChanged: (BrailleMode mode) => chosen = mode)),
      );

      await tester.tap(find.text(_braille1));

      expect(chosen, BrailleMode.uncontracted);
    });

    testWidgets('each button is at least 48dp tall', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(_buttons()));

      expect(
        tester.getSize(_filled(_braille2)).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSize(_outlined(_braille1)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('screen readers hear each label with its selected state', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();

      await tester.pumpWidget(_host(_buttons()));

      // Each button is one merged node: label, button role and state.
      expect(
        tester.getSemantics(find.text(_braille2)),
        isSemantics(
          label: _braille2,
          isButton: true,
          isEnabled: true,
          hasSelectedState: true,
          isSelected: true,
          isInMutuallyExclusiveGroup: true,
        ),
      );
      expect(
        tester.getSemantics(find.text(_braille1)),
        isSemantics(
          label: _braille1,
          isButton: true,
          hasSelectedState: true,
          isSelected: false,
          isInMutuallyExclusiveGroup: true,
        ),
      );

      semantics.dispose();
    });

    testWidgets('Braille 1 is disabled with each availability note', (
      WidgetTester tester,
    ) async {
      final Map<BrailleModeAvailability, String> notes =
          <BrailleModeAvailability, String>{
            BrailleModeAvailability.unsupportedPlatform:
                BrailleModeSelectorStyles.unsupportedPlatformNote,
            BrailleModeAvailability.noSourceText:
                BrailleModeSelectorStyles.noSourceTextNote,
            BrailleModeAvailability.mathOnly:
                BrailleModeSelectorStyles.mathOnlyNote,
          };

      for (final MapEntry<BrailleModeAvailability, String> entry
          in notes.entries) {
        await tester.pumpWidget(_host(_buttons(availability: entry.key)));

        expect(find.text(entry.value), findsOneWidget);
        expect(
          tester.widget<OutlinedButton>(_outlined(_braille1)).onPressed,
          isNull,
          reason: '${entry.key}',
        );
        expect(
          tester.widget<FilledButton>(_filled(_braille2)).onPressed,
          isNotNull,
        );
      }
    });

    testWidgets('the fallback note is shown under the buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(_buttons(showFallbackNote: true)));

      expect(find.text(BrailleModeSelectorStyles.fallbackNote), findsOneWidget);
    });

    testWidgets('on a small phone at the largest font they wrap cleanly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(_buttons(), width: 320, textScale: 2));

      expect(tester.takeException(), isNull);

      final Rect braille1 = tester.getRect(_outlined(_braille1));
      final Rect braille2 = tester.getRect(_filled(_braille2));

      expect(braille2.top, greaterThanOrEqualTo(braille1.bottom));
      expect(braille1.right, lessThanOrEqualTo(320));
      expect(braille2.right, lessThanOrEqualTo(320));
      expect(braille1.height, greaterThanOrEqualTo(48));
      expect(braille2.height, greaterThanOrEqualTo(48));
    });
  });

  group('copy menu', () {
    testWidgets('offers labelled Copy text and Copy Braille', (
      WidgetTester tester,
    ) async {
      int textCopies = 0;
      int brailleCopies = 0;

      await tester.pumpWidget(
        _host(
          TextBrailleCopyMenu(
            onCopyText: () => textCopies++,
            onCopyBraille: () => brailleCopies++,
          ),
        ),
      );

      expect(
        find.byTooltip(BrailleModeSelectorStyles.copyMenuTooltip),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.byType(TextBrailleCopyMenu)).height,
        greaterThanOrEqualTo(48),
      );

      await tester.tap(find.byType(TextBrailleCopyMenu));
      await tester.pumpAndSettle();

      expect(
        find.text(BrailleModeSelectorStyles.copyTextLabel),
        findsOneWidget,
      );
      expect(
        find.text(BrailleModeSelectorStyles.copyBrailleLabel),
        findsOneWidget,
      );

      await tester.tap(find.text(BrailleModeSelectorStyles.copyBrailleLabel));
      await tester.pumpAndSettle();

      expect(brailleCopies, 1);
      expect(textCopies, 0);
    });

    testWidgets('an item with nothing to copy is disabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(TextBrailleCopyMenu(onCopyText: () {}, onCopyBraille: null)),
      );

      await tester.tap(find.byType(TextBrailleCopyMenu));
      await tester.pumpAndSettle();

      final PopupMenuItem<Object?> brailleItem = tester
          .widgetList<PopupMenuItem<Object?>>(
            find.byWidgetPredicate((Widget widget) => widget is PopupMenuItem),
          )
          .last;

      expect(brailleItem.enabled, isFalse);
    });
  });
}
