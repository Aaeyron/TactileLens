import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/ai/ai_service.dart';
import 'package:mobile/services/ai/offline_ocr_service.dart';
import 'package:mobile/services/ai/paddle_onnx_native_service.dart';

/// Counts model loads and releases on the Android side.
class _CountingOnnxService extends PaddleOnnxNativeService {
  _CountingOnnxService();

  int loads = 0;
  int releases = 0;

  @override
  bool get isSupported => true;

  @override
  Future<Map<String, dynamic>> initializeDocumentPipeline({
    int threadCount = 4,
  }) async {
    loads++;
    return <String, dynamic>{'success': true};
  }

  @override
  Future<Map<String, dynamic>> releaseDocumentPipeline() async {
    releases++;
    return <String, dynamic>{'success': true};
  }
}

void main() {
  late OfflineOcrService previousShared;

  setUp(() => previousShared = OfflineOcrService.shared);
  tearDown(() => OfflineOcrService.shared = previousShared);

  test('leaving the Scan screen keeps the on-device models loaded', () async {
    final _CountingOnnxService native = _CountingOnnxService();
    OfflineOcrService.shared = OfflineOcrService(onnxService: native);

    // Each visit to the Scan tab creates an AIService and disposes it when
    // the tab is left. Ten visits, each loading before a scan:
    for (int visit = 0; visit < 10; visit++) {
      final AIService ai = AIService(scanMode: AIService.sessionMode);
      await OfflineOcrService.shared.prepare();
      ai.dispose();
      await Future<void>.delayed(Duration.zero);
    }

    expect(native.loads, 1, reason: 'loaded once, then kept');
    expect(native.releases, 0, reason: 'never freed by leaving the tab');
  });

  test('a scanner passed in is still disposed with its AIService', () async {
    final _CountingOnnxService native = _CountingOnnxService();
    final OfflineOcrService own = OfflineOcrService(onnxService: native);

    await own.prepare();
    AIService(offlineOcrService: own, scanMode: AIService.sessionMode)
        .dispose();
    await Future<void>.delayed(Duration.zero);

    expect(native.releases, 1);
  });
}
