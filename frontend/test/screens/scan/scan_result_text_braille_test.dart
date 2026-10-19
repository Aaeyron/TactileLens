import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    brailleSuccess: true,
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

void main() {
  late String? copied;

  setUp(() {
    copied = null;
  });

  Future<void> pumpResult(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 4800);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    final List<DocumentPage> contracted = _pages(_fixture.contracted);

    await tester.pumpWidget(
      MaterialApp(
        home: ScanResultScreen(
          result: ScanDocumentResult(
            model: 'test',
            pipelineVersion: 'test',
            device: 'test',
            pageCount: 1,
            processingTimeMs: 0,
            blocks: contracted.single.blocks,
            pages: contracted,
          ),
          scannedImage: File('missing-test-image.png'),
          // Braille 1 prepared before the screen opened.
          initialBrailleView: BrailleModeView(
            pages: _pages(_fixture.uncontracted),
            mode: BrailleMode.uncontracted,
          ),
        ),
      ),
    );

    // Entrance animation; the missing image keeps a spinner, so no settle.
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> copyBraille(WidgetTester tester) async {
    await tester.tap(find.byType(TextBrailleCopyMenu));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text(BrailleModeSelectorStyles.copyBrailleLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('mode buttons replace the copy buttons, with one selector', (
    WidgetTester tester,
  ) async {
    await pumpResult(tester);

    // No chip selector and no separate copy buttons in the section.
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text(BrailleModeSelectorStyles.copyBrailleLabel), findsNothing);
    expect(find.text(BrailleModeSelectorStyles.copyTextLabel), findsNothing);

    final Finder braille1 = find.widgetWithText(
      FilledButton,
      BrailleModeSelectorStyles.uncontractedLabel,
    );
    final Finder braille2 = find.widgetWithText(
      OutlinedButton,
      BrailleModeSelectorStyles.contractedLabel,
    );

    expect(braille1, findsOneWidget);
    expect(braille2, findsOneWidget);

    // The buttons sit right under the section title, where the copy
    // buttons were; the copy menu is in the title row.
    final Rect title = tester.getRect(find.text('Text and Braille'));
    final Rect copyMenu = tester.getRect(find.byType(TextBrailleCopyMenu));

    expect(tester.getRect(braille1).top, greaterThan(title.bottom));
    expect(copyMenu.top, lessThan(title.bottom));
    expect(copyMenu.bottom, greaterThan(title.top));
  });

  testWidgets('Copy Braille copies the mode on screen', (
    WidgetTester tester,
  ) async {
    await pumpResult(tester);

    await copyBraille(tester);
    expect(copied, _fixture.uncontracted);

    await tester.tap(find.text(BrailleModeSelectorStyles.contractedLabel));
    await tester.pump();

    await copyBraille(tester);
    expect(copied, _fixture.contracted);
  });
}
