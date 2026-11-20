import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/ai/scan_document_result.dart';
import 'package:mobile/models/ai/scan_processing_mode.dart';
import 'package:mobile/screens/auth/guest_setup_screen.dart';
import 'package:mobile/screens/history/history_screen.dart';
import 'package:mobile/screens/home/home_screen.dart';
import 'package:mobile/screens/main/tab_data_cache.dart';
import 'package:mobile/screens/scan/scan_result_screen.dart';
import 'package:mobile/utils/session_manager.dart';
import 'package:mobile/widgets/scan/scan_mode_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

DocumentBlock _block(
  int id,
  String text,
  String braille, {
  bool formula = false,
  String reviewReason = '',
}) {
  return DocumentBlock(
    id: id,
    order: id,
    type: formula ? 'display_formula' : 'text',
    rawContent: text,
    normalizedContent: text,
    boundingBox: const <double>[],
    polygonPoints: const <List<double>>[],
    isText: !formula,
    isFormula: formula,
    isTable: false,
    tableRows: const <List<String>>[],
    brailleContent: braille,
    brailleCode: formula ? 'nemeth' : 'ueb',
    brailleSuccess: braille.isNotEmpty,
    brailleError: braille.isEmpty ? 'Needs review: $reviewReason' : '',
    needsReview: reviewReason.isNotEmpty,
    reviewReason: reviewReason,
  );
}

/// A guest worksheet result: text, a formula, a held block and a flagged
/// block, as an on-device scan returns them.
ScanDocumentResult _result() {
  final List<DocumentBlock> blocks = <DocumentBlock>[
    _block(
      0,
      'Read each question carefully and show your work.',
      '⠠⠗⠂⠙⠀⠑⠁⠡⠀⠐⠟⠀⠉⠜⠑⠰⠇⠇⠽⠀⠯⠀⠩⠪⠀⠽⠗⠀⠐⠺⠲',
    ),
    _block(1, '(x + 1)/2 = 3', '⠷⠰⠭⠬⠼⠂⠾⠸⠌⠷⠼⠆⠾⠀⠨⠅⠀⠼⠒', formula: true),
    _block(
      2,
      '√(x + 9) = 5',
      '',
      formula: true,
      reviewReason: 'contains a root (√): Nemeth radical not yet confirmed',
    ),
    _block(
      3,
      'Solve for x.',
      '⠠⠎⠕⠇⠧⠑⠀⠿⠀⠰⠭⠲',
      reviewReason: 'low OCR confidence',
    ),
  ];

  return ScanDocumentResult(
    model: 'test',
    pipelineVersion: 'offline-onnx-v1',
    device: 'mobile-cpu',
    pageCount: 1,
    processingTimeMs: 1,
    blocks: blocks,
    pages: <DocumentPage>[
      DocumentPage(pageIndex: 0, width: 0, height: 0, blocks: blocks),
    ],
  );
}

/// Pumps [child] on a 320x568 phone with [textScale]; returns overflows.
Future<List<String>> _pump(
  WidgetTester tester,
  Widget child,
  double textScale,
) async {
  tester.view.physicalSize = const Size(640, 1136);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final List<String> overflows = <String>[];
  final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final String text = details.exceptionAsString();
    if (text.contains('overflowed')) {
      overflows.add(text.split('\n').first);
    }
    // Database and camera plugins are missing in tests; not layout errors.
  };
  addTearDown(() => FlutterError.onError = previous);

  await tester.pumpWidget(
    MaterialApp(
      builder: (BuildContext context, Widget? app) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: app!,
      ),
      home: child,
    ),
  );
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
  FlutterError.onError = previous;

  return overflows;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SessionManager.guestModeKey: true,
    });
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  final Map<String, Widget Function()> screens = <String, Widget Function()>{
    'Home': () => HomeScreen(
      cache: TabDataCache(),
      onScanPressed: () {},
      onMaterialsPressed: () {},
      onHistoryPressed: () {},
    ),
    'History': () => HistoryScreen(cache: TabDataCache(), onBack: () {}),
    'Result': () =>
        ScanResultScreen(result: _result(), scannedImage: File('none.jpg')),
    'Guest setup': () => const GuestSetupScreen(),
    'Scan mode choice': () => Scaffold(
      body: Center(
        child: ScanModeSelector(
          mode: ScanProcessingMode.onDevice,
          onChanged: (_) {},
        ),
      ),
    ),
  };

  for (final double scale in <double>[1, 2]) {
    for (final MapEntry<String, Widget Function()> screen in screens.entries) {
      testWidgets('${screen.key} fits a 320x568 phone at ${scale}x text, '
          'with 48 dp labelled targets', (WidgetTester tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();

        final List<String> overflows = await _pump(
          tester,
          screen.value(),
          scale,
        );

        expect(overflows, isEmpty);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 3));
        semantics.dispose();
      });
    }
  }

  testWidgets('Home has no notifications button (there is no such feature)', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await _pump(tester, screens['Home']!(), 1);

    expect(find.bySemanticsLabel('Notifications'), findsNothing);
    expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
    semantics.dispose();
  });

  test('scan modes are named Online and On this device everywhere', () {
    expect(ScanModeText.onlineLabel, 'Online');
    expect(ScanModeText.onDeviceLabel, 'On this device');
    for (final String text in <String>[
      ScanModeText.privacyMessage,
      ScanModeText.useOnDevice,
      ScanModeText.offerOnDevice,
      ScanModeText.onDeviceHint,
    ]) {
      expect(text, isNot(contains('On-device')), reason: text);
    }
  });
}
