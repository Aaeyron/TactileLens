import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../../models/ai/scan_document_result.dart';
import '../braille/offline_braille_service.dart';
import 'paddleocr_vl_native_service.dart';

class OfflineOcrService {
  OfflineOcrService({
    PaddleOcrVlNativeService? paddleOcrVlService,
    OfflineBrailleService? brailleService,
  }) : _paddleOcrVlService =
           paddleOcrVlService ?? const PaddleOcrVlNativeService(),
       _brailleService = brailleService ?? const OfflineBrailleService();

  final PaddleOcrVlNativeService _paddleOcrVlService;
  final OfflineBrailleService _brailleService;

  bool _initialized = false;
  bool _modelsLoaded = false;
  bool _disposed = false;

  Future<ScanDocumentResult> scanDocument(File imageFile) async {
    if (_disposed) {
      throw const OfflineOcrException(
        'The offline PaddleOCR-VL service is no longer available.',
      );
    }

    if (!await imageFile.exists()) {
      throw const OfflineOcrException('The selected image could not be found.');
    }

    if (!_paddleOcrVlService.isSupported) {
      throw const OfflineOcrException(
        'Offline PaddleOCR-VL is currently available only on Android.',
      );
    }

    final Stopwatch stopwatch = Stopwatch()..start();

    try {
      await _ensureModelsLoaded();

      final PaddleOcrVlScanResult scanResult = await _paddleOcrVlService
          .scanImage(
            imagePath: imageFile.path,
            prompt: 'OCR:',
            maximumTokens: 512,
            threadCount: 4,
          );

      if (!scanResult.success || scanResult.content.trim().isEmpty) {
        throw OfflineOcrException(
          scanResult.error ?? 'PaddleOCR-VL returned no recognized content.',
        );
      }

      final img.Image? decodedImage = await _decodeImage(imageFile);
      final int pageWidth = math.max(decodedImage?.width ?? 0, 1);
      final int pageHeight = math.max(decodedImage?.height ?? 0, 1);
      final List<String> recognizedSections = _splitRecognizedContent(
        scanResult.content,
      );
      final List<DocumentBlock> blocks = <DocumentBlock>[];

      for (int index = 0; index < recognizedSections.length; index++) {
        final String rawContent = recognizedSections[index].trim();

        if (rawContent.isEmpty) {
          continue;
        }

        final String normalizedContent = _normalizeContent(rawContent);
        final bool isFormula = _looksLikeFormula(normalizedContent);
        final OfflineBrailleResult brailleResult = await _brailleService
            .translateBlock(
              normalizedContent,
              isFormula: isFormula,
              isTable: false,
            );

        final double top = pageHeight * index / recognizedSections.length;
        final double bottom =
            pageHeight * (index + 1) / recognizedSections.length;

        blocks.add(
          DocumentBlock(
            id: index,
            order: index,
            type: isFormula ? 'formula' : 'text',
            rawContent: rawContent,
            normalizedContent: normalizedContent,
            boundingBox: <double>[0, top, pageWidth.toDouble(), bottom],
            polygonPoints: <List<double>>[
              <double>[0, top],
              <double>[pageWidth.toDouble(), top],
              <double>[pageWidth.toDouble(), bottom],
              <double>[0, bottom],
            ],
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
      }

      if (blocks.isEmpty) {
        throw const OfflineOcrException(
          'PaddleOCR-VL returned no usable text or mathematical expressions.',
        );
      }

      stopwatch.stop();

      final DocumentPage page = DocumentPage(
        pageIndex: 0,
        width: pageWidth,
        height: pageHeight,
        blocks: List<DocumentBlock>.unmodifiable(blocks),
      );

      debugPrint(
        'Offline PaddleOCR-VL completed in '
        '${stopwatch.elapsedMilliseconds} ms with '
        '${blocks.length} document blocks. Native inference: '
        '${scanResult.scanTimeMs} ms.',
      );

      return ScanDocumentResult(
        model: 'PaddleOCR-VL-1.6-GGUF+liblouis-3.38.0',
        pipelineVersion: 'offline-paddleocr-vl-v1',
        device: 'mobile-cpu',
        pageCount: 1,
        processingTimeMs: stopwatch.elapsedMicroseconds / 1000,
        blocks: List<DocumentBlock>.unmodifiable(blocks),
        pages: <DocumentPage>[page],
      );
    } on PaddleOcrVlNativeException catch (error, stackTrace) {
      stopwatch.stop();
      debugPrint('Offline PaddleOCR-VL failed: ${error.message}');
      debugPrintStack(stackTrace: stackTrace);
      throw OfflineOcrException(error.message);
    } on OfflineOcrException {
      stopwatch.stop();
      rethrow;
    } catch (error, stackTrace) {
      stopwatch.stop();
      debugPrint('Offline PaddleOCR-VL or Braille translation failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw const OfflineOcrException(
        'Offline document recognition failed. Try scanning again with clearer '
        'lighting and keep the document in focus.',
      );
    }
  }

  Future<void> _ensureModelsLoaded() async {
    if (!_initialized) {
      await _paddleOcrVlService.initialize();
      _initialized = true;
    }

    if (_modelsLoaded) {
      final PaddleOcrVlModelStatus status = await _paddleOcrVlService
          .modelStatus();

      if (status.loaded) {
        return;
      }

      _modelsLoaded = false;
    }

    final PaddleOcrVlModelLoadResult loadResult = await _paddleOcrVlService
        .loadModels(threadCount: 4);

    if (!loadResult.success || !loadResult.loaded) {
      throw OfflineOcrException(
        loadResult.error ??
            'The offline PaddleOCR-VL model files could not be loaded.',
      );
    }

    _modelsLoaded = true;
  }

  List<String> _splitRecognizedContent(String content) {
    final String cleaned = content
        .replaceAll(RegExp(r'^```(?:latex|tex|text)?\s*'), '')
        .replaceAll(RegExp(r'\s*```$'), '')
        .trim();

    if (cleaned.isEmpty) {
      return const <String>[];
    }

    final List<String> lines = cleaned
        .split(RegExp(r'\r?\n'))
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList(growable: false);

    return lines.isEmpty ? <String>[cleaned] : lines;
  }

  String _normalizeContent(String content) {
    return content
        .replaceAll('−', '-')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .trim();
  }

  bool _looksLikeFormula(String content) {
    final String value = content.trim();

    if (value.isEmpty) {
      return false;
    }

    if (RegExp(
      r'\\(?:frac|sqrt|sum|int|left|right|begin|end)',
    ).hasMatch(value)) {
      return true;
    }

    if (value.startsWith(r'\[') ||
        value.startsWith(r'$$') ||
        value.startsWith(r'\(')) {
      return true;
    }

    if (RegExp(r'[=≤≥≠≈±√∑∫∞]').hasMatch(value)) {
      return true;
    }

    return RegExp(
      r'(?:\d+(?:\.\d+)?|[A-Za-z])'
      r'\s*[+\-×÷*/^<>]'
      r'\s*(?:\d+(?:\.\d+)?|[A-Za-z])',
    ).hasMatch(value);
  }

  Future<img.Image?> _decodeImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final img.Image? decodedImage = img.decodeImage(bytes);

      return decodedImage == null ? null : img.bakeOrientation(decodedImage);
    } catch (error) {
      debugPrint('Unable to decode offline page dimensions: $error');
      return null;
    }
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    _disposed = true;

    if (_modelsLoaded) {
      try {
        await _paddleOcrVlService.unloadModels();
      } catch (error) {
        debugPrint('Unable to unload offline PaddleOCR-VL models: $error');
      }
    }

    _modelsLoaded = false;
  }
}

class OfflineOcrException implements Exception {
  const OfflineOcrException(this.message);

  final String message;

  @override
  String toString() => message;
}
