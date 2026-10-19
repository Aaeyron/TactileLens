import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/ai/scan_document_result.dart';
import 'package:mobile/models/braille/braille_mode.dart';
import 'package:mobile/services/braille/braille_mode_translator.dart';
import 'package:mobile/services/braille/offline_braille_service.dart';
import 'package:mobile/styles/widgets/braille/braille_mode_selector_styles.dart';
import 'package:mobile/widgets/braille/braille_mode_section.dart';

import '../../fixtures/braille_modes.dart';

final BrailleModeFixture _fixture = brailleModeFixtures.first;

List<DocumentPage> _pages() {
  return <DocumentPage>[
    DocumentPage(
      pageIndex: 0,
      width: 0,
      height: 0,
      blocks: <DocumentBlock>[
        DocumentBlock(
          id: 0,
          order: 0,
          type: 'text',
          rawContent: _fixture.text,
          normalizedContent: _fixture.text,
          boundingBox: const <double>[],
          polygonPoints: const <List<double>>[],
          isText: true,
          isFormula: false,
          isTable: false,
          tableRows: const <List<String>>[],
          brailleContent: _fixture.contracted,
          brailleCode: 'ueb',
          brailleSuccess: true,
          brailleError: '',
        ),
      ],
    ),
  ];
}

/// Answers with the fixture's Braille 1 once [release] completes.
class _GatedTranslator {
  Completer<void> release = Completer<void>();
  int calls = 0;

  Future<List<OfflineBrailleResult>> call(
    List<String> lines,
    BrailleMode mode,
  ) async {
    calls++;
    await release.future;

    return lines
        .map(
          (String line) => OfflineBrailleResult(
            success: true,
            code: 'ueb',
            content: _fixture.uncontracted,
            error: null,
          ),
        )
        .toList();
  }
}

Widget _host({
  required BrailleModeTranslator translator,
  required BrailleMode initialMode,
  double width = 360,
  double textScale = 1,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(width, 900),
        textScaler: TextScaler.linear(textScale),
      ),
      child: Scaffold(
        body: SizedBox(
          width: width,
          child: BrailleModeSection(
            pages: _pages(),
            initialMode: initialMode,
            translator: translator,
            builder:
                (BuildContext context, BrailleModeView? view, Widget selector) {
                  return Column(
                    children: <Widget>[
                      selector,
                      if (view == null)
                        const BrailleModeLoadingPlaceholder()
                      else
                        Text(view.combinedBraille, key: const Key('braille')),
                    ],
                  );
                },
          ),
        ),
      ),
    ),
  );
}

String _shownBraille(WidgetTester tester) {
  return tester.widget<Text>(find.byKey(const Key('braille'))).data!;
}

void main() {
  testWidgets('Braille 2 shows at once without translating', (
    WidgetTester tester,
  ) async {
    final _GatedTranslator fake = _GatedTranslator();

    await tester.pumpWidget(
      _host(
        translator: BrailleModeTranslator(
          translateLines: fake.call,
          isSupported: () => true,
        ),
        initialMode: BrailleMode.contracted,
      ),
    );

    expect(_shownBraille(tester), _fixture.contracted);
    expect(fake.calls, 0);
  });

  testWidgets('Braille 1 never flashes Braille 2 before it is ready', (
    WidgetTester tester,
  ) async {
    final _GatedTranslator fake = _GatedTranslator();

    await tester.pumpWidget(
      _host(
        translator: BrailleModeTranslator(
          translateLines: fake.call,
          isSupported: () => true,
        ),
        initialMode: BrailleMode.uncontracted,
      ),
    );

    // While translating: a placeholder, never the Braille 2 content.
    expect(find.byKey(const Key('braille')), findsNothing);
    expect(find.byType(BrailleModeLoadingPlaceholder), findsOneWidget);

    fake.release.complete();
    await tester.pump();
    await tester.pump();

    expect(_shownBraille(tester), _fixture.uncontracted);
  });

  testWidgets('a failing translator shows Braille 2 with a short note', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        translator: BrailleModeTranslator(
          translateLines: (List<String> lines, BrailleMode mode) async {
            throw const OfflineBrailleException('Missing en-ueb-g1.ctb');
          },
          isSupported: () => true,
        ),
        initialMode: BrailleMode.uncontracted,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(_shownBraille(tester), _fixture.contracted);
    expect(find.text(BrailleModeSelectorStyles.fallbackNote), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('on other platforms Braille 1 is disabled with a note', (
    WidgetTester tester,
  ) async {
    final _GatedTranslator fake = _GatedTranslator();

    await tester.pumpWidget(
      _host(
        translator: BrailleModeTranslator(
          translateLines: fake.call,
          isSupported: () => false,
        ),
        initialMode: BrailleMode.contracted,
      ),
    );

    expect(
      find.text(BrailleModeSelectorStyles.unsupportedPlatformNote),
      findsOneWidget,
    );

    final ChoiceChip braille1 = tester.widget<ChoiceChip>(
      find.widgetWithText(
        ChoiceChip,
        BrailleModeSelectorStyles.uncontractedLabel,
      ),
    );
    expect(braille1.onSelected, isNull);

    await tester.tap(find.text(BrailleModeSelectorStyles.uncontractedLabel));
    await tester.pump();

    expect(_shownBraille(tester), _fixture.contracted);
    expect(fake.calls, 0);
  });

  testWidgets('switching back to Braille 2 wins over a slow Braille 1', (
    WidgetTester tester,
  ) async {
    final _GatedTranslator fake = _GatedTranslator();

    await tester.pumpWidget(
      _host(
        translator: BrailleModeTranslator(
          translateLines: fake.call,
          isSupported: () => true,
        ),
        initialMode: BrailleMode.contracted,
      ),
    );

    await tester.tap(find.text(BrailleModeSelectorStyles.uncontractedLabel));
    await tester.pump();
    await tester.tap(find.text(BrailleModeSelectorStyles.contractedLabel));
    await tester.pump();

    // The late Braille 1 result must not replace the chosen Braille 2.
    fake.release.complete();
    await tester.pump();
    await tester.pump();

    expect(_shownBraille(tester), _fixture.contracted);
  });

  testWidgets('the selector wraps at the largest font size', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        translator: BrailleModeTranslator(
          translateLines: _GatedTranslator().call,
          isSupported: () => true,
        ),
        initialMode: BrailleMode.contracted,
        width: 320,
        textScale: 2,
      ),
    );

    expect(tester.takeException(), isNull);

    final Rect braille1 = tester.getRect(
      find.text(BrailleModeSelectorStyles.uncontractedLabel),
    );
    final Rect braille2 = tester.getRect(
      find.text(BrailleModeSelectorStyles.contractedLabel),
    );

    expect(braille2.top, greaterThan(braille1.top), reason: 'chips wrapped');
  });
}
