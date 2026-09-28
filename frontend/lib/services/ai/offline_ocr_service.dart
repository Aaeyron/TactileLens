import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../../models/ai/scan_document_result.dart';
import '../braille/offline_braille_service.dart';
import 'paddle_onnx_native_service.dart';

/// Offline scanning (no internet) for printed English text and
/// General Algebra:
///
///   PP-DocLayoutV3 (layout + reading order)
///   + PP-OCRv6 (text lines)
///   + PP-FormulaNet_plus-S (equations -> LaTeX)
///   on ONNX Runtime, then offline Braille via Liblouis.
///
/// Returns the same [ScanDocumentResult] shape as before, so the scan,
/// result and history screens work unchanged.
class OfflineOcrService {
  OfflineOcrService({
    PaddleOnnxNativeService? onnxService,
    OfflineBrailleService? brailleService,
    this.threadCount = 4,
  }) : _onnxService = onnxService ?? const PaddleOnnxNativeService(),
       _brailleService = brailleService ?? const OfflineBrailleService();

  final PaddleOnnxNativeService _onnxService;
  final OfflineBrailleService _brailleService;

  /// CPU threads for the ONNX models.
  final int threadCount;

  bool _modelsLoaded = false;
  bool _disposed = false;
  Future<void>? _loading;

  /// Whether the offline models are already loaded in memory.
  bool get isReady => _modelsLoaded;

  /// Loads the offline models ahead of time (call when the scan screen
  /// opens). The very first run also copies ~350 MB of models into the
  /// app's storage, so it can take a while. Safe to call repeatedly.
  Future<void> prepare() => _ensureModelsLoaded();

  Future<ScanDocumentResult> scanDocument(File imageFile) async {
    if (_disposed) {
      throw const OfflineOcrException(
        'The offline scanner is no longer available.',
      );
    }

    if (!await imageFile.exists()) {
      throw const OfflineOcrException('The selected image could not be found.');
    }

    if (!_onnxService.isSupported) {
      throw const OfflineOcrException(
        'Offline scanning is currently available only on Android.',
      );
    }

    final Stopwatch stopwatch = Stopwatch()..start();
    File? uprightCopy;

    try {
      await _ensureModelsLoaded();

      uprightCopy = await _uprightCopyIfRotated(imageFile);

      final OfflineDocumentResult result = await _onnxService
          .scanDocumentResult(
            imagePath: (uprightCopy ?? imageFile).path,
            threadCount: threadCount,
          );

      if (result.isEmpty) {
        throw const OfflineOcrException(
          'No printed text or equations were found. Keep the whole page in '
          'view, in good lighting, and try again.',
        );
      }

      final int pageWidth = math.max(result.imageWidth, 1);
      final int pageHeight = math.max(result.imageHeight, 1);
      final List<DocumentBlock> blocks = <DocumentBlock>[];

      for (final OfflineDocumentBlock source in result.blocks) {
        final String rawContent = source.content.trim();

        if (rawContent.isEmpty) {
          debugPrint(
            'Offline scan: skipped empty ${source.type} block '
            '${source.index}${source.error == null ? '' : ' (${source.error})'}',
          );
          continue;
        }

                final bool isFormula = source.isFormula;

        // OCR returns one entry per printed line; rejoin text into
        // flowing paragraphs so the result screen and Braille don't break
        // where the paper wrapped. Formulas are kept exactly as LaTeX.
        final String normalizedContent = _normalizeContent(
          isFormula ? rawContent : _reflowText(rawContent),
        );

        final OfflineBrailleResult brailleResult = await _brailleService
            .translateBlock(
              normalizedContent,
              isFormula: isFormula,
              isTable: false,
            );

        final int order = blocks.length;

        blocks.add(
          DocumentBlock(
            id: order,
            order: order,
            // Offline formula blocks are always equations on their own line
            // (inline math stays inside its text block), so they are display
            // formulas; DocumentLayoutView shows these on a separate line.
            type: isFormula ? 'display_formula' : 'text',
            rawContent: rawContent,
            normalizedContent: normalizedContent,
            boundingBox: <double>[
              source.left,
              source.top,
              source.right,
              source.bottom,
            ],
            polygonPoints: <List<double>>[
              <double>[source.left, source.top],
              <double>[source.right, source.top],
              <double>[source.right, source.bottom],
              <double>[source.left, source.bottom],
            ],
            isText: !isFormula,
            isFormula: isFormula,
            isTable: false,
            tableRows: const <List<String>>[],
            brailleContent: brailleResult.content,
            brailleCode: brailleResult.code,
            brailleSuccess: brailleResult.success,
            brailleError: brailleResult.error ?? '',
            needsReview: source.needsReview,
          ),
        );
      }

      if (blocks.isEmpty) {
        throw const OfflineOcrException(
          'No usable text or mathematical expressions were recognized.',
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
        'Offline ONNX scan: ${blocks.length} blocks '
        '(${result.formulaCount} formulas, '
        '${result.needsReviewCount} flagged for review) in '
        '${stopwatch.elapsedMilliseconds} ms '
        '[layout ${result.layoutTimeMs} ms, OCR ${result.ocrTimeMs} ms, '
        'formulas ${result.formulaTimeMs} ms].',
      );

      return ScanDocumentResult(
        model: 'PP-DocLayoutV3+PP-OCRv6+PP-FormulaNet_plus-S+liblouis-3.38.0',
        pipelineVersion: 'offline-onnx-v1',
        device: 'mobile-cpu',
        pageCount: 1,
        processingTimeMs: stopwatch.elapsedMicroseconds / 1000,
        blocks: List<DocumentBlock>.unmodifiable(blocks),
        pages: <DocumentPage>[page],
      );
    } on PaddleOnnxNativeException catch (error, stackTrace) {
      debugPrint('Offline ONNX scan failed: ${error.message}');
      debugPrintStack(stackTrace: stackTrace);
      throw OfflineOcrException(error.message);
    } on OfflineOcrException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('Offline scan or Braille translation failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw const OfflineOcrException(
        'Offline document recognition failed. Try scanning again with clearer '
        'lighting and keep the document in focus.',
      );
    } finally {
      if (stopwatch.isRunning) {
        stopwatch.stop();
      }

      if (uprightCopy != null) {
        try {
          await uprightCopy.delete();
        } catch (_) {
          // Temporary file; ignore cleanup failures.
        }
      }
    }
  }

  Future<void> _ensureModelsLoaded() {
    if (_modelsLoaded) {
      return Future<void>.value();
    }

    return _loading ??= _loadModels().whenComplete(() => _loading = null);
  }

  Future<void> _loadModels() async {
    try {
      final Stopwatch stopwatch = Stopwatch()..start();
      final Map<String, dynamic> result = await _onnxService
          .initializeDocumentPipeline(threadCount: threadCount);
      stopwatch.stop();

      if (result['success'] != true) {
        throw const OfflineOcrException(
          'The offline scanning models could not be loaded.',
        );
      }

      _modelsLoaded = true;

      debugPrint(
        'Offline models ready in ${stopwatch.elapsedMilliseconds} ms '
        '[OCR ${result['ocr_cold_load_time_ms']} ms, '
        'layout ${result['layout_cold_load_time_ms']} ms, '
        'formula ${result['formula_cold_load_time_ms']} ms].',
      );
    } on PaddleOnnxNativeException catch (error) {
      throw OfflineOcrException(
        'The offline scanning models could not be loaded: ${error.message}',
      );
    }
  }

  /// Camera photos often store rotation in EXIF instead of rotating pixels.
  /// The native models read raw pixels, so give them an upright copy when
  /// the photo is rotated. Returns null when no copy is needed.
  Future<File?> _uprightCopyIfRotated(File imageFile) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();
      final img.ExifData? exif = img.decodeJpgExif(bytes);
      final int orientation = exif?.imageIfd.orientation ?? 1;

      if (orientation == 1) {
        return null;
      }

      final String outputPath =
          '${Directory.systemTemp.path}/tactilelens_offline_scan_'
          '${DateTime.now().microsecondsSinceEpoch}.jpg';

      final bool written = await compute(
        _writeUprightJpeg,
        <String, Object>{'bytes': bytes, 'path': outputPath},
      );

      return written ? File(outputPath) : null;
    } catch (error) {
      // Not a JPEG or no EXIF: scan the original file.
      debugPrint('Offline scan: orientation check skipped ($error).');
      return null;
    }
  }

    static final RegExp _listItemStart = RegExp(
    r'^(?:\(?\d{1,3}[.)]|\(?[a-zA-Z][.)]|[•\-–*])\s',
  );

  static final RegExp _startsLowercase = RegExp(r'^[a-z]');

  /// Joins OCR lines into paragraphs:
  /// - "equa-" + "tion" -> "equation"
  /// - numbered or lettered items and bullets keep their own line
  /// - every other line break becomes a space
  String _reflowText(String content) {
    final List<String> lines = content
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList(growable: false);

    if (lines.length < 2) {
      return content.trim();
    }

    String result = lines.first;

    for (int index = 1; index < lines.length; index++) {
      final String line = lines[index];

      if (_listItemStart.hasMatch(line)) {
        result = '$result\n$line';
      } else if (result.endsWith('-') && _startsLowercase.hasMatch(line)) {
        result = result.substring(0, result.length - 1) + line;
      } else {
        result = '$result $line';
      }
    }

    return result;
  }

  String _normalizeContent(String content) {
    return content
        .replaceAll('−', '-')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .trim();
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    _disposed = true;

    if (_modelsLoaded) {
      try {
        await _onnxService.releaseDocumentPipeline();
      } catch (error) {
        debugPrint('Unable to release the offline models: $error');
      }
    }

    _modelsLoaded = false;
  }
}

/// Runs in a background isolate: decode, apply EXIF rotation, re-encode.
bool _writeUprightJpeg(Map<String, Object> job) {
  final img.Image? decoded = img.decodeImage(job['bytes']! as Uint8List);

  if (decoded == null) {
    return false;
  }

  final img.Image upright = img.bakeOrientation(decoded);

  File(job['path']! as String).writeAsBytesSync(
    img.encodeJpg(upright, quality: 95),
  );

  return true;
}

class OfflineOcrException implements Exception {
  const OfflineOcrException(this.message);

  final String message;

  @override
  String toString() => message;
}