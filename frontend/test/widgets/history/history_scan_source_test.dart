import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/ai/scan_processing_mode.dart';
import 'package:mobile/models/history/history_model.dart';
import 'package:mobile/services/ai/offline_ocr_service.dart';
import 'package:mobile/widgets/history/history_scan_source.dart';

HistoryRecord _record(String? pipelineVersion) {
  return HistoryRecord.fromJson(<String, dynamic>{
    'id': 1,
    'user_id': 1,
    'title': 'Fractions',
    'recognized_content': '1/2',
    'braille_content': '',
    'document_blocks': <Object>[],
    'pipeline_version': pipelineVersion,
    'created_at': '2026-11-05T08:00:00Z',
    'updated_at': '2026-11-05T08:00:00Z',
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            // About the text column of a History card on a 320 dp phone.
            child: SizedBox(width: 140, child: child),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('where a saved scan was processed', () {
    test('the on-device pipeline version means On this device', () {
      expect(
        ScanProcessingMode.fromPipelineVersion(
          OfflineOcrService.pipelineVersion,
        ),
        ScanProcessingMode.onDevice,
      );
      expect(
        _record(OfflineOcrService.pipelineVersion).processingMode,
        ScanProcessingMode.onDevice,
      );
    });

    test('a server pipeline version means Online', () {
      for (final String version in <String>['v1.5', '1.5', 'PaddleOCR-VL']) {
        expect(
          _record(version).processingMode,
          ScanProcessingMode.online,
          reason: version,
        );
      }
    });

    test('records saved without a version show nothing', () {
      expect(_record(null).processingMode, isNull);
      expect(_record('  ').processingMode, isNull);
    });
  });

  testWidgets('shows Online with a label TalkBack reads', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();

    await _pump(
      tester,
      const HistoryScanSource(mode: ScanProcessingMode.online),
    );

    expect(find.text(HistoryScanSource.onlineLabel), findsOneWidget);
    expect(find.bySemanticsLabel('Scanned online'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('shows On this device with a label TalkBack reads', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();

    await _pump(
      tester,
      const HistoryScanSource(mode: ScanProcessingMode.onDevice),
    );

    expect(find.text(HistoryScanSource.onDeviceLabel), findsOneWidget);
    expect(find.bySemanticsLabel('Scanned on this device'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('wraps instead of overflowing at 2x text on a small card', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const HistoryScanSource(mode: ScanProcessingMode.onDevice),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    final Text text = tester.widget<Text>(
      find.text(HistoryScanSource.onDeviceLabel),
    );
    expect(text.overflow, isNot(TextOverflow.ellipsis));
  });

  testWidgets('the details line names the place in full', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const HistoryScanSource(
        mode: ScanProcessingMode.onDevice,
        detailed: true,
      ),
    );

    expect(find.text('Processed on this device'), findsOneWidget);

    await _pump(
      tester,
      const HistoryScanSource(mode: ScanProcessingMode.online, detailed: true),
    );

    expect(find.text('Processed online'), findsOneWidget);
  });
}
