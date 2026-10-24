import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/services/ai/ai_service.dart';

/// A scan is sent to the server exactly once. After a 502/503, or a
/// connection that drops mid-request, the image may already have reached
/// the hosted OCR service, so it is never sent again.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;
  late File image;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'access_token': 'test-token',
    });

    directory = await Directory.systemTemp.createTemp('ai_service_test');
    image = File('${directory.path}/page.png')
      ..writeAsBytesSync(<int>[0x89, 0x50, 0x4e, 0x47]);
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  ({AIService service, List<http.Request> requests}) remoteService(
    Future<http.Response> Function(http.Request request) respond,
  ) {
    final List<http.Request> requests = <http.Request>[];

    final AIService service = AIService(
      client: MockClient((http.Request request) {
        requests.add(request);
        return respond(request);
      }),
      baseUrl: 'http://backend.example.invalid',
      scanMode: AIService.remoteMode,
    );

    return (service: service, requests: requests);
  }

  for (final int status in <int>[502, 503]) {
    test('a $status is reported and the image is not sent again', () async {
      final (:AIService service, :List<http.Request> requests) = remoteService(
        (http.Request request) async => http.Response(
          jsonEncode(<String, Object>{
            'success': false,
            'message': 'The online OCR service is unavailable.',
            'code': 'hosted_ocr_unavailable',
            'fallback_recommended': true,
          }),
          status,
        ),
      );

      await expectLater(
        service.scanDocument(image),
        throwsA(
          isA<AIServiceConnectionException>().having(
            (AIServiceConnectionException error) => error.message,
            'message',
            'The online OCR service is unavailable.',
          ),
        ),
      );

      expect(requests, hasLength(1));
    });
  }

  test('a connection that drops is not retried', () async {
    final (:AIService service, :List<http.Request> requests) = remoteService(
      (http.Request request) async =>
          throw http.ClientException('Connection closed before full header'),
    );

    await expectLater(
      service.scanDocument(image),
      throwsA(isA<AIServiceConnectionException>()),
    );

    expect(requests, hasLength(1));
  });

  test('a successful scan is sent once with the login token', () async {
    final (:AIService service, :List<http.Request> requests) = remoteService(
      (http.Request request) async => http.Response(
        jsonEncode(<String, Object>{
          'success': true,
          'model': 'PaddleOCR-VL-1.6',
          'blocks': <Object>[],
          'pages': <Object>[],
        }),
        200,
      ),
    );

    await service.scanDocument(image);

    expect(requests, hasLength(1));
    expect(requests.single.headers['Authorization'], 'Bearer test-token');
    expect(
      requests.single.url.toString(),
      'http://backend.example.invalid/api/scan-document',
    );
  });
}
