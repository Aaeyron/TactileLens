import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../models/ai/scan_document_result.dart';
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

      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      final List<DocumentBlock> blocks = <DocumentBlock>[];

      for (int index = 0; index < recognizedText.blocks.length; index++) {
        final TextBlock recognizedBlock = recognizedText.blocks[index];

        final String content = recognizedBlock.text.trim();

        if (content.isEmpty) {
          continue;
        }

        final OfflineBrailleResult brailleResult = await _brailleService
            .translateText(content);

        blocks.add(
          DocumentBlock(
            id: index,
            order: index,
            type: 'text',
            rawContent: content,
            normalizedContent: content,
            boundingBox: <double>[
              recognizedBlock.boundingBox.left,
              recognizedBlock.boundingBox.top,
              recognizedBlock.boundingBox.right,
              recognizedBlock.boundingBox.bottom,
            ],
            polygonPoints: recognizedBlock.cornerPoints
                .map(
                  (point) => <double>[point.x.toDouble(), point.y.toDouble()],
                )
                .toList(growable: false),
            isText: true,
            isFormula: false,
            isTable: false,
            tableRows: const <List<String>>[],
            brailleContent: brailleResult.content,
            brailleCode: brailleResult.code,
            brailleSuccess: brailleResult.success,
            brailleError: brailleResult.error ?? '',
          ),
        );
      }

      stopwatch.stop();

      final List<DocumentBlock> immutableBlocks =
          List<DocumentBlock>.unmodifiable(blocks);

      final DocumentPage page = DocumentPage(
        pageIndex: 0,
        width: 0,
        height: 0,
        blocks: immutableBlocks,
      );

      final int successfulBrailleBlocks = immutableBlocks
          .where((DocumentBlock block) => block.hasBraille)
          .length;

      debugPrint(
        'Offline OCR completed in '
        '${stopwatch.elapsedMilliseconds} ms with '
        '${immutableBlocks.length} text blocks and '
        '$successfulBrailleBlocks Braille blocks.',
      );

      return ScanDocumentResult(
        model:
            'google-ml-kit-text-recognition'
            '+liblouis-3.38.0',
        pipelineVersion: 'offline-v2',
        device: 'mobile',
        pageCount: 1,
        processingTimeMs: stopwatch.elapsedMicroseconds / 1000,
        blocks: immutableBlocks,
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

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    _disposed = true;
    await _textRecognizer.close();
  }
}

class OfflineOcrException implements Exception {
  const OfflineOcrException(this.message);

  final String message;

  @override
  String toString() => message;
}
