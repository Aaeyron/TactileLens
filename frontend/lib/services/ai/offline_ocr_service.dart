import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

import '../../models/ai/scan_document_result.dart';
import '../../utils/document_reading_order.dart';
import '../braille/offline_braille_service.dart';

class OfflineOcrService {
  OfflineOcrService({OfflineBrailleService? brailleService})
    : _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin),
      _brailleService = brailleService ?? const OfflineBrailleService();

  final TextRecognizer _textRecognizer;
  final OfflineBrailleService _brailleService;

  bool _disposed = false;

  Future<ScanDocumentResult> scanDocument(File imageFile) async {
    if (_disposed) {
      throw const OfflineOcrException(
        'The offline text recognizer is no longer available.',
      );
    }

    if (!await imageFile.exists()) {
      throw const OfflineOcrException('The selected image could not be found.');
    }

    final Stopwatch stopwatch = Stopwatch()..start();

    try {
      final InputImage inputImage = InputImage.fromFile(imageFile);

      final Future<RecognizedText> recognitionFuture = _textRecognizer
          .processImage(inputImage);

      final Future<img.Image?> imageFuture = _decodeImage(imageFile);

      final RecognizedText recognizedText = await recognitionFuture;

      final img.Image? decodedImage = await imageFuture;

      final List<DocumentBlock> detectedBlocks = <DocumentBlock>[];

      int nextBlockId = 0;

      for (final TextBlock recognizedBlock in recognizedText.blocks) {
        for (final TextLine recognizedLine in recognizedBlock.lines) {
          final String rawContent = recognizedLine.text.trim();

          if (rawContent.isEmpty) {
            continue;
          }

          final String content = _normalizeRecognizedContent(rawContent);

          final bool isFormula = _looksLikeFormula(content);

          final OfflineBrailleResult brailleResult = await _brailleService
              .translateBlock(content, isFormula: isFormula, isTable: false);

          detectedBlocks.add(
            DocumentBlock(
              id: nextBlockId,
              order: nextBlockId,
              type: isFormula ? 'formula' : 'text',
              rawContent: rawContent,
              normalizedContent: content,
              boundingBox: <double>[
                recognizedLine.boundingBox.left,
                recognizedLine.boundingBox.top,
                recognizedLine.boundingBox.right,
                recognizedLine.boundingBox.bottom,
              ],
              polygonPoints: recognizedLine.cornerPoints
                  .map(
                    (point) => <double>[point.x.toDouble(), point.y.toDouble()],
                  )
                  .toList(growable: false),
              isText: !isFormula,
              isFormula: isFormula,
              isTable: false,
              tableRows: const <List<String>>[],
              brailleContent: brailleResult.content,
              brailleCode: brailleResult.code,
              brailleSuccess: brailleResult.success,
              brailleError: brailleResult.error ?? '',
            ),
          );

          nextBlockId++;
        }
      }

      final _PageDimensions pageDimensions = _resolvePageDimensions(
        decodedImage: decodedImage,
        blocks: detectedBlocks,
      );

      final List<DocumentBlock> sortedBlocks =
          DocumentReadingOrder.sort<DocumentBlock>(
            blocks: detectedBlocks,
            pageWidth: pageDimensions.width.toDouble(),
            boundingBoxOf: (DocumentBlock block) => block.boundingBox,
          );

      final List<DocumentBlock> orderedBlocks =
          List<DocumentBlock>.unmodifiable(<DocumentBlock>[
            for (int index = 0; index < sortedBlocks.length; index++)
              _withOrder(sortedBlocks[index], index),
          ]);

      stopwatch.stop();

      final DocumentPage page = DocumentPage(
        pageIndex: 0,
        width: pageDimensions.width,
        height: pageDimensions.height,
        blocks: orderedBlocks,
      );

      final int successfulBrailleBlocks = orderedBlocks
          .where((DocumentBlock block) => block.hasBraille)
          .length;

      debugPrint(
        'Offline OCR completed in '
        '${stopwatch.elapsedMilliseconds} ms with '
        '${orderedBlocks.length} text blocks and '
        '$successfulBrailleBlocks Braille blocks. '
        'Page: ${pageDimensions.width}x'
        '${pageDimensions.height}.',
      );

      return ScanDocumentResult(
        model:
            'google-ml-kit-text-recognition'
            '+liblouis-3.38.0',
        pipelineVersion: 'offline-v6-superscript-normalization',
        device: 'mobile',
        pageCount: 1,
        processingTimeMs: stopwatch.elapsedMicroseconds / 1000,
        blocks: orderedBlocks,
        pages: <DocumentPage>[page],
      );
    } catch (error, stackTrace) {
      stopwatch.stop();

      if (error is OfflineOcrException) {
        rethrow;
      }

      debugPrint(
        'Offline OCR or Braille translation failed: '
        '$error',
      );

      debugPrintStack(stackTrace: stackTrace);

      throw const OfflineOcrException(
        'Offline document recognition failed. '
        'Try scanning again with clearer lighting '
        'and keep the document in focus.',
      );
    }
  }

  String _normalizeUnicodeSuperscripts(String content) {
    const Map<String, String> superscriptCharacters = <String, String>{
      '⁰': '0',
      '¹': '1',
      '²': '2',
      '³': '3',
      '⁴': '4',
      '⁵': '5',
      '⁶': '6',
      '⁷': '7',
      '⁸': '8',
      '⁹': '9',
      '⁺': '+',
      '⁻': '-',
    };

    return content.replaceAllMapped(RegExp(r'[⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻]+'), (Match match) {
      final String source = match.group(0) ?? '';

      final String exponent = source.split('').map((String character) {
        return superscriptCharacters[character] ?? character;
      }).join();

      if (exponent.isEmpty) {
        return source;
      }

      return exponent.length == 1 ? '^$exponent' : '^{$exponent}';
    });
  }

  String _normalizeRecognizedContent(String content) {
    String value = _normalizeUnicodeSuperscripts(
      content,
    ).replaceAll('−', '-').replaceAll('–', '-').replaceAll('—', '-').trim();

    final bool hasMathContext =
        RegExp(r'[=+\-*/^()]').hasMatch(value) && RegExp(r'\d').hasMatch(value);

    if (!hasMathContext) {
      return value;
    }

    // ML Kit may confuse an italic mathematical x with r, especially
    // after a coefficient: 2r - 4 becomes 2x - 4.
    value = value.replaceAllMapped(RegExp(r'(\d)[rR](\s*[+\-=])'), (
      Match match,
    ) {
      return '${match.group(1)}x${match.group(2)}';
    });

    // Correct a common radical misread inside parentheses:
    // (V2x - 4) becomes (\sqrt{2x - 4}).
    value = value.replaceAllMapped(RegExp(r'\(\s*[Vv]\s*([^()]*)\)'), (
      Match match,
    ) {
      final String radicand = match.group(1)?.trim() ?? '';

      final bool looksLikeRadicand =
          radicand.isNotEmpty &&
          RegExp(r'\d').hasMatch(radicand) &&
          RegExp(r'[+\-*/]').hasMatch(radicand);

      if (!looksLikeRadicand) {
        return match.group(0) ?? '';
      }

      return r'(\sqrt{' + radicand + '})';
    });

    // Correct a simple radical such as V16 only when it appears at the
    // beginning or immediately after an equation delimiter.
    value = value.replaceAllMapped(
      RegExp(r'(^|[=(])\s*[Vv]\s*(\d+(?:\.\d+)?)'),
      (Match match) {
        final String prefix = match.group(1) ?? '';
        final String radicand = match.group(2) ?? '';

        return prefix + r'\sqrt{' + radicand + '}';
      },
    );

    // A superscript 2 is sometimes recognized as an apostrophe after a
    // closing parenthesis: (x - 2)' = becomes (x - 2)^2 =.
    value = value.replaceAllMapped(RegExp(r"(\))\s*['’](\s*=)"), (Match match) {
      return '${match.group(1)}^2${match.group(2)}';
    });

    return value;
  }

  bool _looksLikeFormula(String content) {
    final String value = content.trim();

    if (value.isEmpty) {
      return false;
    }

    // Common mathematical symbols strongly indicate an equation.
    if (RegExp(r'[=≤≥≠≈±√∑∫∞]').hasMatch(value)) {
      return true;
    }

    // Detect expressions such as:
    // 2 + 3, x - 4, 3x / 2, A × B, and y^2.
    if (RegExp(
      r'(?:\d+(?:\.\d+)?|[A-Za-z])'
      r'\s*[+\-×÷*/^<>]\s*'
      r'(?:\d+(?:\.\d+)?|[A-Za-z])',
    ).hasMatch(value)) {
      return true;
    }

    // Detect common LaTeX-like output if OCR preserves it.
    if (RegExp(
      r'\\(?:frac|sqrt|sum|int|left|right|begin|end)',
    ).hasMatch(value)) {
      return true;
    }

    // Detect isolated parenthesized or bracketed numeric expressions.
    if (RegExp(
      r'^[\[(]?\s*'
      r'(?:\d+(?:\.\d+)?|[A-Za-z])'
      r'(?:\s*[+\-×÷*/^]\s*'
      r'(?:\d+(?:\.\d+)?|[A-Za-z]))+'
      r'\s*[\])]?$',
    ).hasMatch(value)) {
      return true;
    }

    return false;
  }

  Future<img.Image?> _decodeImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();

      final img.Image? decodedImage = img.decodeImage(bytes);

      if (decodedImage == null) {
        return null;
      }

      return img.bakeOrientation(decodedImage);
    } catch (error) {
      debugPrint(
        'Unable to decode offline page dimensions: '
        '$error',
      );

      return null;
    }
  }

  _PageDimensions _resolvePageDimensions({
    required img.Image? decodedImage,
    required List<DocumentBlock> blocks,
  }) {
    double maximumRight = 0;
    double maximumBottom = 0;

    for (final DocumentBlock block in blocks) {
      if (block.boundingBox.length < 4) {
        continue;
      }

      maximumRight = math.max(
        maximumRight,
        math.max(block.boundingBox[0], block.boundingBox[2]),
      );

      maximumBottom = math.max(
        maximumBottom,
        math.max(block.boundingBox[1], block.boundingBox[3]),
      );
    }

    final int decodedWidth = decodedImage?.width ?? 0;
    final int decodedHeight = decodedImage?.height ?? 0;

    final int width = math.max(decodedWidth, maximumRight.ceil());

    final int height = math.max(decodedHeight, maximumBottom.ceil());

    return _PageDimensions(
      width: math.max(width, 1),
      height: math.max(height, 1),
    );
  }

  DocumentBlock _withOrder(DocumentBlock block, int order) {
    return DocumentBlock(
      id: block.id,
      order: order,
      type: block.type,
      rawContent: block.rawContent,
      normalizedContent: block.normalizedContent,
      boundingBox: block.boundingBox,
      polygonPoints: block.polygonPoints,
      isText: block.isText,
      isFormula: block.isFormula,
      isTable: block.isTable,
      tableRows: block.tableRows,
      brailleContent: block.brailleContent,
      brailleCode: block.brailleCode,
      brailleSuccess: block.brailleSuccess,
      brailleError: block.brailleError,
    );
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    _disposed = true;
    await _textRecognizer.close();
  }
}

class _PageDimensions {
  const _PageDimensions({required this.width, required this.height});

  final int width;
  final int height;
}

class OfflineOcrException implements Exception {
  const OfflineOcrException(this.message);

  final String message;

  @override
  String toString() => message;
}
