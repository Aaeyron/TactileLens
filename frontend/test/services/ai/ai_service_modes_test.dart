import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/models/ai/scan_document_result.dart';
import 'package:mobile/models/ai/scan_processing_mode.dart';
import 'package:mobile/services/ai/ai_service.dart';
import 'package:mobile/services/ai/offline_ocr_service.dart';
import 'package:mobile/utils/session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

const ScanDocumentResult _deviceResult = ScanDocumentResult(
  model: 'offline',
  pipelineVersion: 'offline-onnx-v1',
  device: 'mobile-cpu',
  pageCount: 1,
  processingTimeMs: 1,
  blocks: <DocumentBlock>[],
  pages: <DocumentPage>[],
);

class _FakeOfflineOcrService extends OfflineOcrService {
  int scans = 0;

  @override
  Future<ScanDocumentResult> scanDocument(File imageFile) async {
    scans++;
    return _deviceResult;
  }

  @override
  Future<void> dispose() async {}
}

http.Response _json(
  int status,
  Map<String, Object?> body, {
  String? retryAfter,
}) {
  return http.Response(
    jsonEncode(body),
    status,
    headers: <String, String>{
      'content-type': 'application/json',
      'retry-after': ?retryAfter,
    },
  );
}

final http.Response _success = _json(200, <String, Object?>{
  'success': true,
  'blocks': <Object>[],
  'pages': <Object>[],
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;
  late File image;
  late List<http.Request> requests;
  late _FakeOfflineOcrService offline;

  void signedIn() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SessionManager.userIdKey: 7,
    });
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'access_token': 'test-token',
    });
  }

  AIService service(http.Response Function() respond) {
    return AIService(
      client: MockClient((http.Request request) async {
        requests.add(request);
        return respond();
      }),
      offlineOcrService: offline,
      baseUrl: 'http://backend.example.invalid',
      scanMode: AIService.sessionMode,
    );
  }

  Future<AIServiceException> scanError(AIService ai) async {
    try {
      await ai.scanDocument(image, mode: ScanProcessingMode.online);
    } on AIServiceException catch (error) {
      return error;
    }
    fail('expected an AIServiceException');
  }

  setUp(() async {
    requests = <http.Request>[];
    offline = _FakeOfflineOcrService();
    directory = await Directory.systemTemp.createTemp('ai_modes_test');
    image = File('${directory.path}/page.png')
      ..writeAsBytesSync(<int>[0x89, 0x50, 0x4e, 0x47]);
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  group('choosing where to scan', () {
    test(
      'guests always scan on the device, even if Online is asked for',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          SessionManager.guestModeKey: true,
        });
        FlutterSecureStorage.setMockInitialValues(<String, String>{});

        final ScanDocumentResult result = await service(
          () => _success,
        ).scanDocument(image, mode: ScanProcessingMode.online);

        expect(requests, isEmpty);
        expect(offline.scans, 1);
        expect(result.processingMode, ScanProcessingMode.onDevice);
      },
    );

    test('a signed-in teacher can choose On-device', () async {
      signedIn();

      final ScanDocumentResult result = await service(
        () => _success,
      ).scanDocument(image, mode: ScanProcessingMode.onDevice);

      expect(requests, isEmpty);
      expect(result.processingMode, ScanProcessingMode.onDevice);
      expect(result.fellBackFromOnline, isFalse);
    });

    test('an online scan is marked online', () async {
      signedIn();

      final ScanDocumentResult result = await service(
        () => _success,
      ).scanDocument(image, mode: ScanProcessingMode.online);

      expect(requests, hasLength(1));
      expect(offline.scans, 0);
      expect(result.processingMode, ScanProcessingMode.online);
    });
  });

  group('Idempotency-Key', () {
    test('every scan the teacher starts gets its own key', () async {
      signedIn();
      final AIService ai = service(() => _success);

      await ai.scanDocument(image, mode: ScanProcessingMode.online);
      await ai.scanDocument(image, mode: ScanProcessingMode.online);

      final List<String?> keys = requests
          .map((http.Request request) => request.headers['Idempotency-Key'])
          .toList();

      expect(keys, hasLength(2));
      for (final String? key in keys) {
        // The format the server accepts.
        expect(key, matches(RegExp(r'^[A-Za-z0-9_-]{8,128}$')));
      }
      expect(keys.first, isNot(keys.last));
    });
  });

  group('server errors', () {
    setUp(signedIn);

    test('a scan limit carries its code, wait time and the fallback', () async {
      final AIServiceException error = await scanError(
        service(
          () => _json(429, <String, Object?>{
            'success': false,
            'message': 'You have reached the online scan limit for this hour.',
            'code': 'scan_hourly_limit',
            'fallback_recommended': true,
            'retry_after_seconds': 1800,
          }, retryAfter: '1800'),
        ),
      );

      expect(error.isScanLimit, isTrue);
      expect(error.statusCode, 429);
      expect(error.fallbackRecommended, isTrue);
      expect(error.retryAfter, const Duration(minutes: 30));
      expect(
        error.message,
        'You have reached the online scan limit for this hour.',
      );
    });

    test('a scan already running is reported, with no fallback', () async {
      final AIServiceException error = await scanError(
        service(
          () => _json(409, <String, Object?>{
            'success': false,
            'message': 'A scan is already in progress for this account.',
            'code': 'scan_in_progress',
            'fallback_recommended': false,
          }),
        ),
      );

      expect(error.isScanInProgress, isTrue);
      expect(error.fallbackRecommended, isFalse);
    });

    test('hosted OCR errors keep the server code and fallback flag', () async {
      final AIServiceException quota = await scanError(
        service(
          () => _json(503, <String, Object?>{
            'success': false,
            'message': 'The online OCR limit for today has been reached.',
            'code': 'hosted_ocr_quota',
            'fallback_recommended': true,
          }),
        ),
      );

      expect(quota, isA<AIServiceConnectionException>());
      expect(quota.code, 'hosted_ocr_quota');
      expect(quota.fallbackRecommended, isTrue);

      final AIServiceException timeout = await scanError(
        service(
          () => _json(504, <String, Object?>{
            'success': false,
            'message': 'The online OCR service took too long.',
            'code': 'hosted_ocr_timeout',
            'fallback_recommended': true,
          }),
        ),
      );

      expect(timeout.code, 'hosted_ocr_timeout');
      expect(timeout.fallbackRecommended, isTrue);
    });

    test('the server can turn the fallback off', () async {
      final AIServiceException error = await scanError(
        service(
          () => _json(503, <String, Object?>{
            'success': false,
            'message': 'Unavailable.',
            'fallback_recommended': false,
          }),
        ),
      );

      expect(error.fallbackRecommended, isFalse);
    });

    test('a bad image is reported without a fallback', () async {
      final AIServiceException error = await scanError(
        service(
          () => _json(415, <String, Object?>{
            'success': false,
            'message': 'The uploaded file is not a valid image.',
            'code': 'invalid_image',
            'fallback_recommended': false,
          }),
        ),
      );

      expect(error.statusCode, 415);
      expect(error.code, 'invalid_image');
      expect(error.fallbackRecommended, isFalse);
    });

    test('a dropped connection recommends the fallback', () async {
      final AIService ai = AIService(
        client: MockClient((http.Request request) async {
          requests.add(request);
          throw http.ClientException('Connection reset');
        }),
        offlineOcrService: offline,
        baseUrl: 'http://backend.example.invalid',
        scanMode: AIService.sessionMode,
      );

      final AIServiceException error = await scanError(ai);

      expect(error, isA<AIServiceConnectionException>());
      expect(error.fallbackRecommended, isTrue);
      // Never resent, and never scanned on the device without asking.
      expect(requests, hasLength(1));
      expect(offline.scans, 0);
    });
  });
}
