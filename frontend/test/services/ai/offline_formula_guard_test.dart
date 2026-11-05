import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/ai/scan_document_result.dart';
import 'package:mobile/models/braille/braille_mode.dart';
import 'package:mobile/services/ai/offline_ocr_service.dart';
import 'package:mobile/services/ai/paddle_onnx_native_service.dart';
import 'package:mobile/services/braille/formula_braille_guard.dart';
import 'package:mobile/services/braille/offline_braille_service.dart';

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

class _RecordingBrailleService extends OfflineBrailleService {
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

Future<(ScanDocumentResult, _RecordingBrailleService)> _scan(
  List<Map<String, Object?>> blocks,
) async {
  final Directory directory = await Directory.systemTemp.createTemp(
    'offline_formula_guard_test',
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
  test(
    'offline holds what the online guard holds, with the same reason',
    () async {
      const List<String> held = <String>[
        r'x=2 when y=3', // English text
        r'Solve for x: 2x+3=7', // English text
        r'\hat{x}=2', // unsupported LaTeX
        r'\begin{cases}x=1\end{cases}', // unsupported environment
        r'x+1&=4', // alignment markup outside an environment
        r'Simplify \sqrt{8}', // English text and a root
      ];

      final (ScanDocumentResult result, _RecordingBrailleService braille) =
          await _scan(held.map(_formula).toList());

      expect(braille.calls, isEmpty, reason: 'nothing held reaches Liblouis');
      expect(result.blocks, hasLength(held.length));

      for (final DocumentBlock block in result.blocks) {
        final FormulaReview expected = FormulaBrailleGuard.review(
          block.rawContent,
        );

        expect(block.isHeldForReview, isTrue, reason: block.rawContent);
        expect(block.brailleContent, isEmpty);
        expect(block.brailleSuccess, isFalse);
        expect(block.reviewReason, expected.reason);
        expect(block.brailleError, 'Needs review: ${expected.reason}');
      }

      expect(
        result.blocks.first.reviewReason,
        'contains English text (1 words: when)',
      );
      expect(result.blocks[2].reviewReason, r'unsupported LaTeX: \hat');
    },
  );

  test('supported formulas and text are still translated', () async {
    final (
      ScanDocumentResult result,
      _RecordingBrailleService braille,
    ) = await _scan(<Map<String, Object?>>[
      _formula(r'x^{2}+5x+6=0'),
      _formula(r'\begin{aligned}x+1&=4\\x&=3\end{aligned}'),
      _formula(r'\text{area}=l\times w'),
      <String, Object?>{
        'type': 'text',
        'label': 'text',
        'content': 'Solve each equation when you are ready.',
        'box': <String, double>{
          'left': 0,
          'top': 20,
          'right': 50,
          'bottom': 30,
        },
      },
    ]);

    expect(braille.calls, hasLength(4));

    for (final DocumentBlock block in result.blocks) {
      expect(block.isHeldForReview, isFalse, reason: block.rawContent);
      expect(block.brailleSuccess, isTrue);
    }
  });
}
