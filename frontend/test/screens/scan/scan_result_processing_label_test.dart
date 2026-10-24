import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/ai/scan_document_result.dart';
import 'package:mobile/models/ai/scan_processing_mode.dart';
import 'package:mobile/screens/scan/scan_result_screen.dart';
import 'package:mobile/widgets/scan/scan_mode_widgets.dart';

ScanDocumentResult _result() {
  const DocumentBlock block = DocumentBlock(
    id: 0,
    order: 1,
    type: 'text',
    rawContent: 'Solve for x.',
    normalizedContent: 'Solve for x.',
    boundingBox: <double>[],
    polygonPoints: <List<double>>[],
    isText: true,
    isFormula: false,
    isTable: false,
    tableRows: <List<String>>[],
    brailleContent: '⠠⠎⠕⠇⠧⠑⠀⠿⠀⠰⠭⠲',
    brailleCode: 'ueb',
    brailleSuccess: true,
    brailleError: '',
  );

  return const ScanDocumentResult(
    model: 'test',
    pipelineVersion: 'test',
    device: 'test',
    pageCount: 1,
    processingTimeMs: 1,
    blocks: <DocumentBlock>[block],
    pages: <DocumentPage>[
      DocumentPage(
        pageIndex: 0,
        width: 0,
        height: 0,
        blocks: <DocumentBlock>[block],
      ),
    ],
  );
}

Future<void> _pump(WidgetTester tester, ScanDocumentResult result) async {
  tester.view.physicalSize = const Size(1080, 4800);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: ScanResultScreen(
        result: result,
        scannedImage: File('missing-test-image.png'),
      ),
    ),
  );

  // Entrance animation; the missing image keeps a spinner, so no settle.
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('an online result says it was processed online', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _result());

    expect(find.text(ScanModeText.processedOnline), findsOneWidget);
  });

  testWidgets('an on-device result says so', (WidgetTester tester) async {
    await _pump(
      tester,
      _result().withProcessingMode(ScanProcessingMode.onDevice),
    );

    expect(find.text(ScanModeText.processedOnDevice), findsOneWidget);
    expect(find.text(ScanModeText.processedOnline), findsNothing);
  });

  testWidgets('a fallback says the online scan did not finish', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();

    await _pump(
      tester,
      _result().withProcessingMode(
        ScanProcessingMode.onDevice,
        fellBackFromOnline: true,
      ),
    );

    expect(
      find.text(ScanModeText.processedOnDeviceAfterOnline),
      findsOneWidget,
    );
    // Screen readers read it too, as part of the result banner.
    expect(
      find.bySemanticsLabel(
        RegExp(RegExp.escape(ScanModeText.processedOnDeviceAfterOnline)),
      ),
      findsOneWidget,
    );

    semantics.dispose();
  });
}
