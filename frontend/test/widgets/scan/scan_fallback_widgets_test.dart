import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/ai/scan_document_result.dart';
import 'package:mobile/models/ai/scan_processing_mode.dart';
import 'package:mobile/services/ai/ai_service.dart';
import 'package:mobile/widgets/scan/scan_mode_widgets.dart';

const ScanDocumentResult _result = ScanDocumentResult(
  model: 'test',
  pipelineVersion: 'test',
  device: 'test',
  pageCount: 1,
  processingTimeMs: 1,
  blocks: <DocumentBlock>[],
  pages: <DocumentPage>[],
);

const AIServiceException _hourlyLimit = AIServiceException(
  'You have reached the online scan limit for this hour.',
  code: 'scan_hourly_limit',
  statusCode: 429,
  fallbackRecommended: true,
  retryAfter: Duration(minutes: 30),
);

const AIServiceException _unavailable = AIServiceConnectionException(
  'The online OCR service is unavailable.',
  code: 'hosted_ocr_unavailable',
  statusCode: 503,
);

void main() {
  group('which mode processed the scan', () {
    test('online, on the device, and on the device after a failure', () {
      expect(processedByLabel(_result), ScanModeText.processedOnline);

      expect(
        processedByLabel(
          _result.withProcessingMode(ScanProcessingMode.onDevice),
        ),
        ScanModeText.processedOnDevice,
      );

      expect(
        processedByLabel(
          _result.withProcessingMode(
            ScanProcessingMode.onDevice,
            fellBackFromOnline: true,
          ),
        ),
        ScanModeText.processedOnDeviceAfterOnline,
      );
    });
  });

  group('offer after a failed online scan', () {
    test('a scan limit says when online scanning returns', () {
      final ({String title, String message}) text = onlineFailureText(
        _hourlyLimit,
      );

      expect(text.title, ScanModeText.scanLimitTitle);
      expect(
        text.message,
        'You have reached the online scan limit for this hour. Online '
        'scanning is available again in about 30 minutes.\n\n'
        '${ScanModeText.offerOnDevice}',
      );
    });

    test("Baidu's daily quota has its own title", () {
      const AIServiceException quota = AIServiceConnectionException(
        'The online OCR limit for today has been reached.',
        code: 'hosted_ocr_quota',
      );

      expect(onlineFailureText(quota).title, ScanModeText.hostedQuotaTitle);
    });

    test('other failures keep the server message and offer the device', () {
      final ({String title, String message}) text = onlineFailureText(
        _unavailable,
      );

      expect(text.title, ScanModeText.onlineFailedTitle);
      expect(
        text.message,
        startsWith('The online OCR service is unavailable.'),
      );
      expect(text.message, endsWith(ScanModeText.offerOnDevice));
    });

    Future<bool> openAndChoose(
      WidgetTester tester,
      Future<void> Function() choose,
    ) async {
      late Future<bool> result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) => TextButton(
                onPressed: () =>
                    result = showOnlineFailedDialog(context, _unavailable),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text(ScanModeText.onlineFailedTitle), findsOneWidget);

      await choose();
      await tester.pumpAndSettle();

      return result;
    }

    testWidgets('Scan on this device is the only way to say yes', (
      WidgetTester tester,
    ) async {
      expect(
        await openAndChoose(
          tester,
          () => tester.tap(find.text(ScanModeText.scanOnDevice)),
        ),
        isTrue,
      );
    });

    testWidgets('Not now says no', (WidgetTester tester) async {
      expect(
        await openAndChoose(
          tester,
          () => tester.tap(find.text(ScanModeText.notNow)),
        ),
        isFalse,
      );
    });

    testWidgets('closing the dialog says no', (WidgetTester tester) async {
      expect(
        await openAndChoose(tester, () => tester.tapAt(const Offset(4, 4))),
        isFalse,
      );
    });

    testWidgets('TalkBack reads the title, message and both buttons', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) => TextButton(
                onPressed: () => showOnlineFailedDialog(context, _hourlyLimit),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(ScanModeText.scanLimitTitle),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(onlineFailureText(_hourlyLimit).message),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.text(ScanModeText.scanOnDevice)),
        isSemantics(isButton: true, label: ScanModeText.scanOnDevice),
      );
      expect(
        tester.getSemantics(find.text(ScanModeText.notNow)),
        isSemantics(isButton: true, label: ScanModeText.notNow),
      );

      semantics.dispose();
    });
  });
}
