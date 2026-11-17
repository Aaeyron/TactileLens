import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/braille/braille_mode.dart';
import 'package:mobile/services/ai/offline_ocr_service.dart';
import 'package:mobile/services/ai/paddle_onnx_native_service.dart';
import 'package:mobile/services/braille/offline_braille_service.dart';

/// The Braille checker in tools/braille_check reproduces the text the phone
/// sends to Liblouis (paths.py). This runs the real OfflineOcrService on
/// every case of its fixture and checks the text that reaches Liblouis.
const String _fixturePath =
    '../tools/braille_check/offline_text_prep_cases.json';

class _TextBlocks extends PaddleOnnxNativeService {
  const _TextBlocks(this.texts);

  final List<String> texts;

  @override
  bool get isSupported => true;

  @override
  Future<Map<String, dynamic>> initializeDocumentPipeline({
    int threadCount = 4,
  }) async => <String, dynamic>{'success': true};

  @override
  Future<OfflineDocumentResult> scanDocumentResult({
    required String imagePath,
    int threadCount = 4,
    double layoutThreshold = 0.5,
  }) async {
    return OfflineDocumentResult.fromMap(<String, dynamic>{
      'success': true,
      'image_width': 100,
      'image_height': 100,
      'blocks': <Map<String, Object?>>[
        for (int i = 0; i < texts.length; i++)
          <String, Object?>{
            'type': 'text',
            'label': 'text',
            'content': texts[i],
            'confidence': 0.99,
            'box': <String, double>{
              'left': 0,
              'top': i * 10.0,
              'right': 50,
              'bottom': i * 10.0 + 9,
            },
          },
      ],
    });
  }
}

class _Recording extends OfflineBrailleService {
  final List<String> sent = <String>[];

  @override
  Future<OfflineBrailleResult> translateBlock(
    String content, {
    required bool isFormula,
    bool isTable = false,
    BrailleMode mode = BrailleMode.defaultMode,
  }) async {
    sent.add(content);
    return const OfflineBrailleResult(
      success: true,
      code: 'ueb',
      content: '⠃',
      error: null,
    );
  }
}

void main() {
  test('the checker sends Liblouis the same text as the app', () async {
    final File file = File(_fixturePath);
    expect(file.existsSync(), isTrue, reason: 'Run from frontend/.');

    final List<dynamic> cases =
        (jsonDecode(file.readAsStringSync()) as Map<String, dynamic>)['cases']
            as List<dynamic>;

    final Directory directory = await Directory.systemTemp.createTemp('prep');
    addTearDown(() => directory.delete(recursive: true));
    final File image = File('${directory.path}/page.png')
      ..writeAsBytesSync(<int>[0x89, 0x50, 0x4E, 0x47]);

    final List<String> inputs = <String>[
      for (final dynamic item in cases)
        (item as Map<String, dynamic>)['input'] as String,
    ];
    final _Recording braille = _Recording();

    await OfflineOcrService(
      onnxService: _TextBlocks(inputs),
      brailleService: braille,
    ).scanDocument(image);

    expect(braille.sent, <String>[
      for (final dynamic item in cases)
        (item as Map<String, dynamic>)['sent'] as String,
    ]);
    expect(braille.sent, hasLength(cases.length));
  });
}
