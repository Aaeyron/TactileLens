import '../../models/ai/scan_document_result.dart';
import '../../models/braille/braille_mode.dart';
import 'braille_mode_translator.dart';

/// The Braille a scan saves.
///
/// Each block's Braille always stays Braille 2. Only the record's combined
/// Braille string follows a mode, which every block records as
/// `saved_braille_mode` (missing means Braille 2).
class BrailleSavePayload {
  const BrailleSavePayload({
    required this.brailleContent,
    required this.documentBlocks,
    required this.documentPages,
  });

  /// History always saves Braille 2, whatever mode is on screen or set as
  /// the default.
  factory BrailleSavePayload.forHistory(ScanDocumentResult result) {
    return BrailleSavePayload(
      brailleContent: result.combinedBraille,
      documentBlocks: result.blocks
          .map((DocumentBlock block) => block.toJson())
          .toList(growable: false),
      documentPages: result.pages
          .map((DocumentPage page) => page.toJson())
          .toList(growable: false),
    );
  }

  /// Materials save the combined Braille of the mode on screen, [view].
  factory BrailleSavePayload.forMaterial(
    ScanDocumentResult result,
    BrailleModeView view,
  ) {
    final BrailleMode mode = view.mode;

    Map<String, dynamic> blockJson(DocumentBlock block) {
      // The stored block keeps its Braille 2; only the mode is recorded.
      return block.withSavedBrailleMode(mode).toJson();
    }

    return BrailleSavePayload(
      brailleContent: mode == BrailleMode.contracted
          ? result.combinedBraille
          : view.combinedBraille,
      documentBlocks: result.blocks.map(blockJson).toList(growable: false),
      documentPages: result.pages
          .map((DocumentPage page) {
            return <String, dynamic>{
              ...page.toJson(),
              'blocks': page.blocks.map(blockJson).toList(growable: false),
            };
          })
          .toList(growable: false),
    );
  }

  final String brailleContent;
  final List<Map<String, dynamic>> documentBlocks;
  final List<Map<String, dynamic>> documentPages;
}
