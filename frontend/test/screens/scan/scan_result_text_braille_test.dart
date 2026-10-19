import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/ai/scan_document_result.dart';
import 'package:mobile/models/braille/braille_mode.dart';
import 'package:mobile/screens/scan/scan_result_screen.dart';
import 'package:mobile/services/braille/braille_mode_translator.dart';
import 'package:mobile/styles/widgets/braille/braille_mode_selector_styles.dart';
import 'package:mobile/widgets/braille/text_braille_copy_menu.dart';

import '../../fixtures/braille_modes.dart';

final BrailleModeFixture _fixture = brailleModeFixtures.first;

DocumentBlock _block(String braille) {
  return DocumentBlock(
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
    brailleContent: braille,
    brailleCode: 'ueb',
    brailleSuccess: braille.isNotEmpty,
    brailleError: '',
  );
}

List<DocumentPage> _pages(String braille) {
  return <DocumentPage>[
    DocumentPage(
      pageIndex: 0,
      width: 0,
      height: 0,
      blocks: <DocumentBlock>[_block(braille)],
    ),
  ];
}

ScanDocumentResult _result(List<DocumentPage> pages) {
  return ScanDocumentResult(
    model: 'test',
    pipelineVersion: 'test',
    device: 'test',
    pageCount: 1,
    processingTimeMs: 0,
    blocks: pages.single.blocks,
    pages: pages,
  );
}

Future<void> _pumpResult(
  WidgetTester tester,
  ScanDocumentResult result, {
  BrailleModeView? initialBrailleView,
}) async {
  tester.view.physicalSize = const Size(1080, 4800);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: ScanResultScreen(
        result: result,
        scannedImage: File('missing-test-image.png'),
        initialBrailleView: initialBrailleView,
      ),
    ),
  );

  // Entrance animation; the missing image keeps a spinner, so no settle.
  await tester.pump(const Duration(seconds: 1));
}

/// No copy control of any kind: no Copy menu, copy icon or "Copy" label.
void _expectNoCopyControls() {
  expect(find.byType(TextBrailleCopyMenu), findsNothing);
  expect(find.byIcon(Icons.copy_rounded), findsNothing);
  expect(find.textContaining('Copy'), findsNothing);
  expect(
    find.byTooltip(BrailleModeSelectorStyles.copyMenuTooltip),
    findsNothing,
  );
}

void main() {
  testWidgets('the Text and Braille section has mode buttons and no copy', (
    WidgetTester tester,
  ) async {
    await _pumpResult(
      tester,
      _result(_pages(_fixture.contracted)),
      // Braille 1 prepared before the screen opened.
      initialBrailleView: BrailleModeView(
        pages: _pages(_fixture.uncontracted),
        mode: BrailleMode.uncontracted,
      ),
    );

    _expectNoCopyControls();
    expect(find.byType(ChoiceChip), findsNothing);

    final Finder braille1 = find.widgetWithText(
      FilledButton,
      BrailleModeSelectorStyles.uncontractedLabel,
    );

    expect(braille1, findsOneWidget);
    expect(
      find.widgetWithText(
        OutlinedButton,
        BrailleModeSelectorStyles.contractedLabel,
      ),
      findsOneWidget,
    );

    // The buttons still sit right under the section title.
    expect(
      tester.getRect(braille1).top,
      greaterThan(tester.getRect(find.text('Text and Braille')).bottom),
    );

    // Saving is unchanged.
    expect(find.text('Save to Materials'), findsOneWidget);
  });

  testWidgets('switching modes still works', (WidgetTester tester) async {
    await _pumpResult(
      tester,
      _result(_pages(_fixture.contracted)),
      initialBrailleView: BrailleModeView(
        pages: _pages(_fixture.uncontracted),
        mode: BrailleMode.uncontracted,
      ),
    );

    await tester.tap(find.text(BrailleModeSelectorStyles.contractedLabel));
    await tester.pump();

    expect(
      find.widgetWithText(
        FilledButton,
        BrailleModeSelectorStyles.contractedLabel,
      ),
      findsOneWidget,
    );
    _expectNoCopyControls();
  });

  testWidgets('older results with separate sections have no copy either', (
    WidgetTester tester,
  ) async {
    // No per-block Braille, so the screen uses the two-section layout.
    await _pumpResult(tester, _result(_pages('')));

    expect(find.text('Scanned Content (Preview)'), findsOneWidget);
    expect(find.text('Braille Output (Translation)'), findsOneWidget);
    _expectNoCopyControls();
  });
}
