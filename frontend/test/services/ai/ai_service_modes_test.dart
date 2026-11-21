import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/models/ai/scan_document_result.dart';
import 'package:mobile/models/ai/scan_processing_mode.dart';
import 'package:mobile/models/ai/scan_stage.dart';
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

  // The quick check before an online scan (GET /) answers; only scans
  // (POST) are recorded.
  AIService service(http.Response Function() respond) {
    return AIService(
      client: MockClient((http.Request request) async {
        if (request.method == 'GET') {
          return _json(200, <String, Object?>{'success': true});
        }
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

    for (final String buildMode in <String>[
      AIService.remoteMode,
      AIService.hybridMode,
    ]) {
      test(
        'a guest scan never uses the network, even in a "$buildMode" build',
        () async {
          SharedPreferences.setMockInitialValues(<String, Object>{
            SessionManager.guestModeKey: true,
          });
          FlutterSecureStorage.setMockInitialValues(<String, String>{
            // Even a stale token from an earlier sign-in is never used.
            'access_token': 'stale-token',
          });

          final AIService ai = AIService(
            client: MockClient((http.Request request) async {
              requests.add(request);
              return _success;
            }),
            offlineOcrService: offline,
            baseUrl: 'http://backend.example.invalid',
            scanMode: buildMode,
          );

          for (final ScanProcessingMode? mode in <ScanProcessingMode?>[
            null,
            ScanProcessingMode.online,
            ScanProcessingMode.onDevice,
          ]) {
            final ScanDocumentResult result = await ai.scanDocument(
              image,
              mode: mode,
            );
            expect(result.processingMode, ScanProcessingMode.onDevice);
          }

          expect(requests, isEmpty);
          expect(offline.scans, 3);
        },
      );
    }

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

      // A refusal with a reason is shown (with its own offer), not
      // switched silently.
      expect(quota, isA<AIServiceConnectionException>());
      expect(quota.code, 'hosted_ocr_quota');
      expect(quota.fallbackRecommended, isTrue);
      expect(offline.scans, 0);
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
  });

  group('automatic scan mode: no connection means on this device', () {
    setUp(signedIn);

    AIService withClient(
      Future<http.Response> Function(http.Request request) handler, {
      Duration requestTimeout = const Duration(minutes: 3),
      Duration reachabilityTimeout = const Duration(seconds: 8),
    }) {
      return AIService(
        client: MockClient((http.Request request) {
          if (request.method == 'POST') {
            requests.add(request);
          }
          return handler(request);
        }),
        offlineOcrService: offline,
        baseUrl: 'http://backend.example.invalid',
        scanMode: AIService.sessionMode,
        requestTimeout: requestTimeout,
        reachabilityTimeout: reachabilityTimeout,
      );
    }

    Future<void> expectScannedOnDevice(
      AIService ai, {
      required int onlineRequests,
    }) async {
      int switched = 0;
      final ScanDocumentResult result = await ai.scanDocument(
        image,
        onFallbackToDevice: () => switched++,
      );

      expect(result.processingMode, ScanProcessingMode.onDevice);
      expect(result.noConnection, isTrue);
      expect(result.fellBackFromOnline, isTrue);
      expect(offline.scans, 1);
      expect(switched, 1);
      expect(requests, hasLength(onlineRequests));
    }

    test('signed in with a connection: scanned online', () async {
      final ScanDocumentResult result = await withClient(
        (http.Request request) async => _success,
      ).scanDocument(image);

      expect(result.processingMode, ScanProcessingMode.online);
      expect(result.noConnection, isFalse);
      expect(requests, hasLength(1));
      expect(offline.scans, 0);
    });

    test('reports the real steps of an online scan, in order', () async {
      final AIService ai = withClient((http.Request request) async => _success);
      final List<ScanStage?> steps = <ScanStage?>[];
      ai.stage.addListener(() => steps.add(ai.stage.value));

      await ai.scanDocument(image);

      expect(steps, <ScanStage?>[
        ScanStage.checkingConnection,
        ScanStage.readingOnline,
      ]);
    });

    test('no connection: the online steps stop at the check', () async {
      final AIService ai = withClient((http.Request request) async {
        throw const SocketException('Network is unreachable');
      });
      final List<ScanStage?> steps = <ScanStage?>[];
      ai.stage.addListener(() => steps.add(ai.stage.value));

      await ai.scanDocument(image);

      // The device steps come from the on-device scanner (a fake here).
      expect(steps, <ScanStage?>[ScanStage.checkingConnection]);
    });

    test('guest: on this device, nothing is sent', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        SessionManager.guestModeKey: true,
      });
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      int calls = 0;

      final ScanDocumentResult result = await withClient((
        http.Request request,
      ) async {
        calls++;
        return _success;
      }).scanDocument(image);

      expect(result.processingMode, ScanProcessingMode.onDevice);
      expect(result.noConnection, isFalse);
      expect(calls, 0);
    });

    test(
      'no internet: scanned on this device, the image is not sent',
      () async {
        await expectScannedOnDevice(
          withClient((http.Request request) async {
            throw const SocketException('Network is unreachable');
          }),
          onlineRequests: 0,
        );
      },
    );

    test('the server does not answer the quick check in time', () async {
      await expectScannedOnDevice(
        withClient((http.Request request) async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          return _success;
        }, reachabilityTimeout: const Duration(milliseconds: 20)),
        onlineRequests: 0,
      );
    });

    test('the online scan times out: scanned on this device', () async {
      await expectScannedOnDevice(
        withClient((http.Request request) async {
          if (request.method == 'POST') {
            await Future<void>.delayed(const Duration(milliseconds: 200));
          }
          return _success;
        }, requestTimeout: const Duration(milliseconds: 20)),
        // Sent once and never again.
        onlineRequests: 1,
      );
    });

    test(
      'the connection drops during the scan: scanned on this device',
      () async {
        await expectScannedOnDevice(
          withClient((http.Request request) async {
            if (request.method == 'POST') {
              throw http.ClientException('Connection reset');
            }
            return _success;
          }),
          onlineRequests: 1,
        );
      },
    );

    for (final int status in <int>[502, 503, 504]) {
      test(
        'the AI server behind the backend does not answer ($status)',
        () async {
          await expectScannedOnDevice(
            withClient((http.Request request) async {
              return request.method == 'POST'
                  ? _json(status, <String, Object?>{'success': false})
                  : _success;
            }),
            onlineRequests: 1,
          );
        },
      );
    }

    test('the hosted OCR times out (504 with its code)', () async {
      await expectScannedOnDevice(
        withClient((http.Request request) async {
          return request.method == 'POST'
              ? _json(504, <String, Object?>{
                  'success': false,
                  'code': 'hosted_ocr_timeout',
                  'fallback_recommended': true,
                })
              : _success;
        }),
        onlineRequests: 1,
      );
    });

    test('a scan limit is reported, not switched to the device', () async {
      final AIServiceException error = await scanError(
        withClient((http.Request request) async {
          return request.method == 'POST'
              ? _json(429, <String, Object?>{
                  'success': false,
                  'message': 'Limit reached.',
                  'code': 'scan_hourly_limit',
                  'fallback_recommended': true,
                })
              : _success;
        }),
      );

      expect(error.isScanLimit, isTrue);
      expect(offline.scans, 0);
    });

    test('the server can turn the automatic switch off', () async {
      final AIServiceException error = await scanError(
        withClient((http.Request request) async {
          return request.method == 'POST'
              ? _json(503, <String, Object?>{
                  'success': false,
                  'fallback_recommended': false,
                })
              : _success;
        }),
      );

      expect(error.fallbackRecommended, isFalse);
      expect(offline.scans, 0);
    });
  });
}
