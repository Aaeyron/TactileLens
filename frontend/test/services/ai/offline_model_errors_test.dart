import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/ai/offline_ocr_service.dart';
import 'package:mobile/services/ai/paddle_onnx_native_service.dart';
import 'package:mobile/widgets/scan/scan_mode_widgets.dart';

/// Fails the way the Android side does: model loading or the scan throws
/// [error]; checkModels returns [status] or throws.
class _FailingOnnxService extends PaddleOnnxNativeService {
  const _FailingOnnxService({
    this.loadError,
    this.scanError,
    this.status,
  });

  final PaddleOnnxNativeException? loadError;
  final PaddleOnnxNativeException? scanError;
  final Map<String, dynamic>? status;

  @override
  bool get isSupported => true;

  @override
  Future<Map<String, dynamic>> initializeDocumentPipeline({
    int threadCount = 4,
  }) async {
    if (loadError != null) {
      throw loadError!;
    }
    return <String, dynamic>{'success': true};
  }

  @override
  Future<OfflineDocumentResult> scanDocumentResult({
    required String imagePath,
    int threadCount = 4,
    double layoutThreshold = 0.5,
  }) async {
    throw scanError!;
  }

  @override
  Future<OfflineModelStatus> checkModels() async {
    if (status == null) {
      throw const PaddleOnnxNativeException('channel broke');
    }
    return OfflineModelStatus.fromMap(status!);
  }
}

const String _missingLayout =
    "On-device scanning can't start: the page layout model is missing from "
    'this copy of TactileLens. Reinstall the app to fix this.';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;
  late File image;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('offline_errors_test');
    image = File('${directory.path}/page.png')
      ..writeAsBytesSync(<int>[0x89, 0x50, 0x4e, 0x47]);
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  Future<String> scanMessage(_FailingOnnxService native) async {
    try {
      await OfflineOcrService(onnxService: native).scanDocument(image);
    } on OfflineOcrException catch (error) {
      return error.message;
    }
    fail('expected an OfflineOcrException');
  }

  group('model problems reach the teacher in plain words', () {
    for (final String code in <String>[
      PaddleOnnxNativeException.modelMissing,
      PaddleOnnxNativeException.modelDamaged,
      PaddleOnnxNativeException.storageFull,
    ]) {
      test('$code: the message from the model check is shown as it is', () async {
        final String message = await scanMessage(
          _FailingOnnxService(
            loadError: PaddleOnnxNativeException(_missingLayout, code: code),
          ),
        );

        expect(message, _missingLayout);
      });
    }

    test('any other load failure: a plain message, no technical detail', () async {
      final String message = await scanMessage(
        const _FailingOnnxService(
          loadError: PaddleOnnxNativeException(
            'ai.onnxruntime.OrtException: Error code - ORT_INVALID_PROTOBUF',
            code: 'PADDLE_ONNX_ERROR',
          ),
        ),
      );

      expect(message, OfflineOcrService.modelsUnavailableMessage);
      expect(message, isNot(contains('Ort')));
    });

    test('a failed page read: a plain message, no file paths', () async {
      final String message = await scanMessage(
        const _FailingOnnxService(
          scanError: PaddleOnnxNativeException(
            'The image does not exist: /data/user/0/com.tactilelens.app/x.jpg',
            code: 'PADDLE_ONNX_ERROR',
          ),
        ),
      );

      expect(message, OfflineOcrService.scanFailedMessage);
      expect(message, isNot(contains('/data/')));
    });
  });

  group('checkModels', () {
    test('reads the status from the Android side', () async {
      final OfflineModelStatus? status = await OfflineOcrService(
        onnxService: const _FailingOnnxService(
          status: <String, dynamic>{
            'ok': false,
            'needs_install': true,
            'install_megabytes': 349,
            'problems': <Object>[
              <String, Object>{
                'model': 'page layout',
                'code': 'model_missing',
                'message': _missingLayout,
              },
            ],
          },
        ),
      ).checkModels();

      expect(status, isNotNull);
      expect(status!.ok, isFalse);
      expect(status.needsInstall, isTrue);
      expect(status.installMegabytes, 349);
      expect(status.problems, <String>[_missingLayout]);
    });

    test('never throws: a failed check gives null', () async {
      final OfflineModelStatus? status = await OfflineOcrService(
        onnxService: const _FailingOnnxService(),
      ).checkModels();

      expect(status, isNull);
    });
  });

  testWidgets('the model problem banner shows each message once and is '
      'announced', (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OnDeviceModelProblem(
            title: 'On-device scanning is not ready',
            problems: <String>[_missingLayout, _missingLayout],
          ),
        ),
      ),
    );

    expect(find.text('On-device scanning is not ready'), findsOneWidget);
    expect(find.text(_missingLayout), findsOneWidget);

    expect(
      tester.getSemantics(find.byType(OnDeviceModelProblem)),
      containsSemantics(isLiveRegion: true),
    );

    semantics.dispose();
  });
}
