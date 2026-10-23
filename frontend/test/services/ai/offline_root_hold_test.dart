import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/ai/scan_document_result.dart';
import 'package:mobile/models/braille/braille_mode.dart';
import 'package:mobile/services/ai/offline_ocr_service.dart';
import 'package:mobile/services/ai/paddle_onnx_native_service.dart';
import 'package:mobile/services/braille/offline_braille_service.dart';

/// Returns the given blocks as if the ONNX models had read them.
class _FakeOnnxService extends PaddleOnnxNativeService {
  const _FakeOnnxService(this.blocks);

  final List<Map<String, Object?>> blocks;

  @override
  bool get isSupported => true;

  @override
  Future<Map<String, dynamic>> initializeDocumentPipeline({
    int threadCount = 4,
  }) async {
    return <String, dynamic>{'success': true};
  }

  @override
  Future<OfflineDocumentResult> scanDocumentResult({
    required String imagePath,
    int threadCount = 4,
    double layoutThreshold = 0.5,
  }) async {
    return OfflineDocumentResult.fromMap(<String, dynamic>{
      'success': true,
      'blocks': blocks,
      'image_width': 100,
      'image_height': 100,
    });
  }
}

/// Records what would have been sent to Liblouis.
class _RecordingBrailleService extends OfflineBrailleService {
  _RecordingBrailleService();

  final List<String> calls = <String>[];

  @override
  Future<OfflineBrailleResult> translateBlock(
    String content, {
    required bool isFormula,
    bool isTable = false,
    BrailleMode mode = BrailleMode.defaultMode,
  }) async {
    calls.add(content);
    return OfflineBrailleResult(
      success: true,
      code: isFormula ? 'nemeth' : 'ueb',
      content: '⠃⠗⠇',
      error: null,
    );
  }
}

Map<String, Object?> _formula(String latex) => <String, Object?>{
  'type': 'formula',
  'label': 'display_formula',
  'content': latex,
  'latex': latex,
  'box': <String, double>{'left': 0, 'top': 0, 'right': 50, 'bottom': 10},
};

/// Every root case, LaTeX and Unicode, as in the AI service tests.
const List<String> _rootCases = <String>[
  r'\sqrt{9}=3',
  r'\sqrt[3]{8}=2',
  r'x=\frac{-b\pm\sqrt{b^{2}-4ac}}{2a}',
  r'2\sqrt{5}',
  '∛27 = 3',
  '∜16 = 2',
  r'\frac{x+1}{2}\leq\sqrt{9}',
];

Future<(ScanDocumentResult, _RecordingBrailleService)> _scan(
  List<Map<String, Object?>> blocks,
) async {
  final Directory directory = await Directory.systemTemp.createTemp(
    'offline_root_hold_test',
  );
  addTearDown(() => directory.delete(recursive: true));

  final File image = File('${directory.path}/page.png')
    ..writeAsBytesSync(<int>[0x89, 0x50, 0x4E, 0x47]);

  final _RecordingBrailleService braille = _RecordingBrailleService();
  final OfflineOcrService service = OfflineOcrService(
    onnxService: _FakeOnnxService(blocks),
    brailleService: braille,
  );

  return (await service.scanDocument(image), braille);
}

void main() {
  test('the reason matches the AI service guard', () {
    expect(
      OfflineOcrService.rootReviewReason,
      'contains a root (√): Nemeth radical not yet confirmed',
    );
  });

  test('a formula with a root is never sent to Liblouis and is held', () async {
    final (ScanDocumentResult result, _RecordingBrailleService braille) =
        await _scan(<Map<String, Object?>>[_formula(r'\sqrt{9}=3')]);

    expect(braille.calls, isEmpty);

    final DocumentBlock block = result.blocks.single;
    expect(block.isHeldForReview, isTrue);
    expect(block.reviewReason, OfflineOcrService.rootReviewReason);
    expect(block.brailleSuccess, isFalse);
    expect(block.brailleContent, isEmpty);
    expect(block.brailleCode, 'nemeth');
    expect(
      block.brailleError,
      'Needs review: ${OfflineOcrService.rootReviewReason}',
    );
    expect(block.normalizedContent, isNot(contains(r'\sqrt')));
    expect(block.rawContent, r'\sqrt{9}=3');
  });

  test('no root case reaches Braille as an escape', () async {
    final (ScanDocumentResult result, _RecordingBrailleService braille) =
        await _scan(_rootCases.map(_formula).toList());

    expect(braille.calls, isEmpty);
    expect(result.blocks, hasLength(_rootCases.length));

    for (final DocumentBlock block in result.blocks) {
      expect(block.isHeldForReview, isTrue, reason: block.rawContent);

      for (final String escape in <String>['⡳', r"'\x", r'\x']) {
        expect(block.brailleContent, isNot(contains(escape)));
      }
    }
  });

  test('formulas without a root and text are still translated', () async {
    final (
      ScanDocumentResult result,
      _RecordingBrailleService braille,
    ) = await _scan(<Map<String, Object?>>[
      _formula(r'x^{2}+1=5'),
      <String, Object?>{
        'type': 'text',
        'label': 'text',
        'content': 'Solve each equation.',
        'box': <String, double>{
          'left': 0,
          'top': 20,
          'right': 50,
          'bottom': 30,
        },
      },
    ]);

    expect(braille.calls, hasLength(2));

    for (final DocumentBlock block in result.blocks) {
      expect(block.isHeldForReview, isFalse);
      expect(block.brailleSuccess, isTrue);
      expect(block.reviewReason, isEmpty);
    }
  });

  test('root detection', () {
    for (final String latex in _rootCases) {
      expect(OfflineOcrService.containsRoot(latex), isTrue, reason: latex);
    }

    for (final String latex in <String>[r'x^{2}+1=5', r'\sqrtx', 'square']) {
      expect(OfflineOcrService.containsRoot(latex), isFalse, reason: latex);
    }
  });
}
