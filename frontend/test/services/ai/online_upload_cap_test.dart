import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:mobile/models/ai/scan_document_result.dart';
import 'package:mobile/models/ai/scan_processing_mode.dart';
import 'package:mobile/services/ai/ai_service.dart';
import 'package:mobile/services/ai/offline_ocr_service.dart';

const String _serverService =
    '../ai_service/services/ocr/paddleocr_vl_service.py';

/// Records the file it was asked to scan.
class _RecordingOfflineService extends OfflineOcrService {
  String? scannedPath;

  @override
  Future<ScanDocumentResult> scanDocument(File imageFile) async {
    scannedPath = imageFile.path;
    return const ScanDocumentResult(
      model: 'offline',
      pipelineVersion: 'test',
      device: 'test',
      pageCount: 1,
      processingTimeMs: 1,
      blocks: <DocumentBlock>[],
      pages: <DocumentPage>[],
    );
  }
}

img.Image? _uploadedImage(http.Request request) {
  final List<int> body = request.bodyBytes;
  const List<int> pngSignature = <int>[0x89, 0x50, 0x4E, 0x47];

  for (int index = 0; index + 4 <= body.length; index++) {
    if (body[index] == pngSignature[0] &&
        body[index + 1] == pngSignature[1] &&
        body[index + 2] == pngSignature[2] &&
        body[index + 3] == pngSignature[3]) {
      return img.decodePng(Uint8List.fromList(body.sublist(index)));
    }
  }

  return null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'access_token': 'test-token',
    });
    directory = Directory.systemTemp.createTempSync('upload_cap');
  });

  tearDown(() => directory.deleteSync(recursive: true));

  File writePng(String name, int width, int height) {
    return File(
      '${directory.path}/$name',
    )..writeAsBytesSync(img.encodePng(img.Image(width: width, height: height)));
  }

  test('the cap matches the AI service default image size', () {
    final File server = File(_serverService);
    expect(server.existsSync(), isTrue, reason: 'run from frontend/');

    final RegExpMatch? match = RegExp(
      r'DEFAULT_MAX_IMAGE_DIMENSION\s*=\s*(\d+)',
    ).firstMatch(server.readAsStringSync());

    expect(match, isNotNull);
    expect(AIService.onlineUploadMaxDimension, int.parse(match!.group(1)!));
    expect(AIService.onlineUploadMaxDimension, 2000);
  });

  group('capForOnlineUpload', () {
    test(
      'a large landscape photo is scaled to 2000 px on its long side',
      () async {
        final File big = writePng('big.png', 3000, 1500);

        final File capped = await AIService.capForOnlineUpload(big);
        final img.Image result = img.decodePng(capped.readAsBytesSync())!;

        expect(capped.path, isNot(big.path));
        expect(result.width, 2000);
        expect(result.height, 1000);
      },
    );

    test('a large portrait photo too', () async {
      final File big = writePng('tall.png', 1200, 4000);

      final img.Image result = img.decodePng(
        (await AIService.capForOnlineUpload(big)).readAsBytesSync(),
      )!;

      expect(result.height, 2000);
      expect(result.width, 600);
    });

    test('an image within the cap is sent as it is', () async {
      final File small = writePng('small.png', 2000, 1200);

      expect((await AIService.capForOnlineUpload(small)).path, small.path);
    });

    test('a file that cannot be decoded is sent as it is', () async {
      final File broken = File('${directory.path}/broken.png')
        ..writeAsBytesSync(<int>[0x89, 0x50, 0x4e, 0x47]);

      expect((await AIService.capForOnlineUpload(broken)).path, broken.path);
    });
  });

  test('an online scan uploads the capped image', () async {
    final List<http.Request> requests = <http.Request>[];
    final AIService service = AIService(
      client: MockClient((http.Request request) async {
        requests.add(request);
        return http.Response(
          jsonEncode(<String, Object>{
            'success': false,
            'message': 'stop here',
            'code': 'invalid_image',
            'fallback_recommended': false,
          }),
          400,
        );
      }),
      baseUrl: 'http://backend.example.invalid',
      scanMode: AIService.remoteMode,
    );

    await expectLater(
      service.scanDocument(writePng('photo.png', 4000, 3000)),
      throwsA(isA<AIServiceException>()),
    );

    expect(requests, hasLength(1));
    final img.Image? uploaded = _uploadedImage(requests.single);
    expect(uploaded, isNotNull);
    expect(uploaded!.width, 2000);
    expect(uploaded.height, 1500);
  });

  test('an on-device scan gets the original image, not capped', () async {
    final _RecordingOfflineService offline = _RecordingOfflineService();
    final AIService service = AIService(
      client: MockClient((http.Request request) async {
        fail('on-device scans never upload');
      }),
      offlineOcrService: offline,
      baseUrl: 'http://backend.example.invalid',
      scanMode: AIService.offlineMode,
    );
    final File photo = writePng('photo.png', 4000, 3000);

    await service.scanDocument(photo, mode: ScanProcessingMode.onDevice);

    expect(offline.scannedPath, photo.path);
  });
}
