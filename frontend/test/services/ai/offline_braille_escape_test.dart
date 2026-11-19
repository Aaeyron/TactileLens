import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/ai/scan_document_result.dart';
import 'package:mobile/models/braille/braille_mode.dart';
import 'package:mobile/services/ai/offline_ocr_service.dart';
import 'package:mobile/services/ai/paddle_onnx_native_service.dart';
import 'package:mobile/services/braille/braille_mode_translator.dart';
import 'package:mobile/services/braille/formula_braille_guard.dart';
import 'package:mobile/services/braille/offline_braille_service.dart';

/// "Find ∛27" in UEB: Liblouis's escape '\x221b' with its 8-dot ⡳.
const String _escaped = '⠠⠋⠔⠙⠀⠄⡳⠭⠆⠆⠂⠃⠄⠼⠃⠛';
const String _clean = '⠠⠋⠔⠙⠀⠼⠃⠛';

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

/// Returns an escape for any content containing "∛", clean Braille
/// otherwise, like Liblouis does.
class _EscapingBrailleService extends OfflineBrailleService {
  @override
  Future<OfflineBrailleResult> translateBlock(
    String content, {
    required bool isFormula,
    bool isTable = false,
    BrailleMode mode = BrailleMode.defaultMode,
  }) async {
    return OfflineBrailleResult(
      success: true,
      code: isFormula ? 'nemeth' : 'ueb',
      content: content.contains('∛') || content.contains('@')
          ? _escaped
          : _clean,
      error: null,
    );
  }
}

Map<String, Object?> _block(String type, String content) => <String, Object?>{
  'type': type,
  'label': type == 'formula' ? 'display_formula' : 'text',
  'content': content,
  'latex': content,
  'box': <String, double>{'left': 0, 'top': 0, 'right': 50, 'bottom': 10},
};

Future<ScanDocumentResult> _scan(List<Map<String, Object?>> blocks) async {
  final Directory directory = await Directory.systemTemp.createTemp(
    'offline_braille_escape_test',
  );
  addTearDown(() => directory.delete(recursive: true));

  final File image = File('${directory.path}/page.png')
    ..writeAsBytesSync(<int>[0x89, 0x50, 0x4E, 0x47]);

  return OfflineOcrService(
    onnxService: _FakeOnnxService(blocks),
    brailleService: _EscapingBrailleService(),
  ).scanDocument(image);
}

void main() {
  test('a text block whose Braille has an escape is held', () async {
    final ScanDocumentResult result = await _scan(<Map<String, Object?>>[
      _block('text', 'Find ∛27 now.'),
      _block('text', 'Find the answer.'),
    ]);

    final DocumentBlock held = result.blocks.first;
    expect(held.isHeldForReview, isTrue);
    expect(held.reviewReason, FormulaBrailleGuard.unsupportedSymbolReason);
    expect(held.brailleContent, isEmpty);
    expect(held.brailleSuccess, isFalse);
    expect(held.brailleCode, 'ueb');
    expect(
      held.brailleError,
      'Needs review: ${FormulaBrailleGuard.unsupportedSymbolReason}',
    );

    final DocumentBlock kept = result.blocks.last;
    expect(kept.isHeldForReview, isFalse);
    expect(kept.brailleContent, _clean);
  });

  test('a formula whose Braille has an escape is held', () async {
    // Passes the formula guard (no root, no words), but Liblouis escapes it.
    final ScanDocumentResult result = await _scan(<Map<String, Object?>>[
      _block('formula', 'x@2=5'),
    ]);

    final DocumentBlock held = result.blocks.single;
    expect(held.isHeldForReview, isTrue);
    expect(held.reviewReason, FormulaBrailleGuard.unsupportedSymbolReason);
    expect(held.brailleContent, isEmpty);
    expect(held.brailleCode, 'nemeth');
  });

  test('Braille 1 falls back to Braille 2 when a line has an escape', () async {
    final DocumentBlock block = DocumentBlock.fromJson(
      <String, dynamic>{
        'id': 0,
        'order': 0,
        'type': 'text',
        'raw_content': 'Read the page.',
        'normalized_content': 'Read the page.',
        'is_text': true,
        'is_formula': false,
        'is_table': false,
        'braille_content': _clean,
        'braille_code': 'ueb',
        'braille_success': true,
        'braille_error': '',
      },
      fallbackId: 0,
      fallbackOrder: 0,
    );

    final BrailleModeTranslator translator = BrailleModeTranslator(
      isSupported: () => true,
      translateLines: (List<String> lines, BrailleMode mode) async {
        return lines
            .map(
              (String line) => const OfflineBrailleResult(
                success: true,
                code: 'ueb',
                content: _escaped,
                error: null,
              ),
            )
            .toList();
      },
    );

    final BrailleModeView view = await translator.viewFor(<DocumentPage>[
      DocumentPage(
        pageIndex: 0,
        width: 1,
        height: 1,
        blocks: <DocumentBlock>[block],
      ),
    ], BrailleMode.uncontracted);

    expect(view.fellBack, isTrue);
    expect(view.mode, BrailleMode.contracted);
    expect(view.combinedBraille, isNot(contains('⡳')));
  });
}
