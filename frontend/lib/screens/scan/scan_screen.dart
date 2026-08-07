import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../services/ai/ai_service.dart';
import '../../services/scan/camera_service.dart';
import '../../services/scan/image_crop_service.dart';
import '../../services/scan/scan_service.dart';
import '../../styles/screens/scan/scan_screen_styles.dart';
import '../../widgets/scan/scan_action_button.dart';
import '../../widgets/scan/scan_camera_preview.dart';
import '../../widgets/scan/scan_preview.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({
    super.key,
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ScanService _scanService = ScanService();
  final CameraService _cameraService = CameraService();
  final AIService _aiService = AIService();
  final ImageCropService _imageCropService = ImageCropService();

  File? _selectedImage;
  Rect? _selectedRegion;
  Size? _previewSize;

  bool _flashEnabled = false;
  bool _isProcessing = false;

  Future<void> _toggleFlash() async {
    if (_selectedImage != null || _isProcessing) return;

    try {
      await _cameraService.toggleFlash();

      if (!mounted) return;

      setState(() {
        _flashEnabled = !_flashEnabled;
      });
    } catch (error, stackTrace) {
      debugPrint('Flash toggle failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _pickFile() async {
    if (_isProcessing) return;

    try {
      final File? selectedFile = await _scanService.pickFile();

      if (selectedFile == null || !mounted) return;

      _setSelectedImage(selectedFile);
    } catch (error, stackTrace) {
      debugPrint('Image selection failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _captureImage() async {
    if (_isProcessing) return;

    try {
      final File capturedImage =
          await _cameraService.captureImage();

      if (!mounted) return;

      _setSelectedImage(capturedImage);
    } catch (error, stackTrace) {
      debugPrint('Camera capture failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _setSelectedImage(File imageFile) {
    setState(() {
      _selectedImage = imageFile;
      _selectedRegion = null;
      _previewSize = null;
      _flashEnabled = false;
    });
  }

  Future<void> _scanImage() async {
  final File? selectedImage = _selectedImage;

  if (selectedImage == null || _isProcessing) return;

  setState(() {
    _isProcessing = true;
  });

  try {
    final File imageToScan =
        await _prepareImageForScanning(selectedImage);

    if (!mounted) return;

    final bool shouldSendToAI =
        await _confirmImageToScan(imageToScan);

    if (!shouldSendToAI || !mounted) return;

    debugPrint(
      'Sending image to PaddleOCR-VL: ${imageToScan.path}',
    );

    final scanResult =
        await _aiService.scanDocument(imageToScan);

    if (!mounted) return;

    debugPrint(
      'PaddleOCR-VL scan completed successfully.',
    );

    debugPrint(
      'AI processing time: '
      '${scanResult.processingTimeMs} ms',
    );

    debugPrint(
      'Detected blocks: ${scanResult.blocks.length}',
    );

    for (final block in scanResult.blocks) {
      debugPrint(
        '[${block.type}] ${block.content}',
      );
    }

    // The result screen will be opened here later.
  } on AIServiceException catch (error, stackTrace) {
    debugPrint('AI service error: ${error.message}');
    debugPrintStack(stackTrace: stackTrace);

    if (!mounted) return;

    _showScanError(error.message);
  } catch (error, stackTrace) {
    debugPrint('Document scan failed: $error');
    debugPrintStack(stackTrace: stackTrace);

    if (!mounted) return;

    _showScanError(
      'Unable to scan the document. Please try again.',
    );
  } finally {
    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}

Future<bool> _confirmImageToScan(
  File imageToScan,
) async {
  final bool? shouldContinue = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Preview Image to Scan'),
        content: SizedBox(
          width: double.maxFinite,
          child: Image.file(
            imageToScan,
            fit: BoxFit.contain,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('Send to AI'),
          ),
        ],
      );
    },
  );

  return shouldContinue ?? false;
}

  Future<File> _prepareImageForScanning(
    File selectedImage,
  ) async {
    final Rect? selectedRegion = _selectedRegion;
    final Size? previewSize = _previewSize;

    // No selected crop means the complete image is sent.
    if (selectedRegion == null || previewSize == null) {
      return selectedImage;
    }

    final bytes = await selectedImage.readAsBytes();
    final img.Image? decodedImage = img.decodeImage(bytes);

    if (decodedImage == null) {
      throw const FormatException(
        'Unable to decode the selected image.',
      );
    }

    final Rect actualRegion = _mapPreviewRegionToImage(
      selectedRegion: selectedRegion,
      previewSize: previewSize,
      imageSize: Size(
        decodedImage.width.toDouble(),
        decodedImage.height.toDouble(),
      ),
    );

    return _imageCropService.cropImage(
      imageFile: selectedImage,
      cropRect: actualRegion,
    );
  }

  Rect _mapPreviewRegionToImage({
    required Rect selectedRegion,
    required Size previewSize,
    required Size imageSize,
  }) {
    if (previewSize.isEmpty || imageSize.isEmpty) {
      throw const FormatException(
        'Invalid image or preview dimensions.',
      );
    }

    /*
     * ScanPreview displays the image using BoxFit.cover.
     *
     * BoxFit.cover may crop the displayed image around its edges.
     * We therefore calculate its scale and offset before mapping
     * the user's selection back to the original image.
     */
    final double widthScale =
        previewSize.width / imageSize.width;

    final double heightScale =
        previewSize.height / imageSize.height;

    final double coverScale =
        widthScale > heightScale ? widthScale : heightScale;

    final Size displayedImageSize = Size(
      imageSize.width * coverScale,
      imageSize.height * coverScale,
    );

    final Offset displayedImageOffset = Offset(
      (previewSize.width - displayedImageSize.width) / 2,
      (previewSize.height - displayedImageSize.height) / 2,
    );

    final Rect previewBounds = Offset.zero & previewSize;
    final Rect clippedRegion =
        selectedRegion.intersect(previewBounds);

    if (clippedRegion.isEmpty) {
      throw const FormatException(
        'The selected crop area is invalid.',
      );
    }

    final double left =
        ((clippedRegion.left - displayedImageOffset.dx) /
                coverScale)
            .clamp(0.0, imageSize.width)
            .toDouble();

    final double top =
        ((clippedRegion.top - displayedImageOffset.dy) /
                coverScale)
            .clamp(0.0, imageSize.height)
            .toDouble();

    final double right =
        ((clippedRegion.right - displayedImageOffset.dx) /
                coverScale)
            .clamp(0.0, imageSize.width)
            .toDouble();

    final double bottom =
        ((clippedRegion.bottom - displayedImageOffset.dy) /
                coverScale)
            .clamp(0.0, imageSize.height)
            .toDouble();

    if (right <= left || bottom <= top) {
      throw const FormatException(
        'The selected crop area is too small.',
      );
    }

    return Rect.fromLTRB(
      left.roundToDouble(),
      top.roundToDouble(),
      right.roundToDouble(),
      bottom.roundToDouble(),
    );
  }

  void _onRegionSelected(
    Rect selectedRegion,
    Size previewSize,
  ) {
    if (_isProcessing) return;

    setState(() {
      _selectedRegion = selectedRegion;
      _previewSize = previewSize;
    });
  }

  void _clearSelectedRegion() {
  if (_isProcessing) return;

  setState(() {
    _selectedRegion = null;
    _previewSize = null;
  });
}

  

  void _showScanError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  @override
  void dispose() {
    _aiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCapturedImage = _selectedImage != null;

    return Scaffold(
      backgroundColor: ScanScreenStyles.backgroundColor,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: ScanScreenStyles.contentPadding,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(
                            height:
                                ScanScreenStyles.backButtonTopSpacing,
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              decoration:
                                  ScanScreenStyles.backButtonDecoration,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color:
                                      ScanScreenStyles.backButtonColor,
                                ),
                                onPressed:
                                    _isProcessing ? null : widget.onBack,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: ScanScreenStyles
                                .backButtonBottomSpacing,
                          ),
                        ],
                      ),
                    ),
                    if (_selectedImage == null)
                      ScanCameraPreview(
                        cameraService: _cameraService,
                      )
                    else
                    ScanPreview(
                      selectedImage: _selectedImage!,
                      onRegionSelected: _onRegionSelected,
                      onSelectionCleared: _clearSelectedRegion,
                    ),
                    const SizedBox(
                      height:
                          ScanScreenStyles.cameraBottomSpacing,
                    ),
                    ScanActionButton(
                      hasCapturedImage: hasCapturedImage,
                      isProcessing: _isProcessing,
                      flashAvailable: !hasCapturedImage,
                      onCameraPressed: _captureImage,
                      onScanPressed: _scanImage,
                      onUploadPressed: _pickFile,
                      onFlashPressed: _toggleFlash,
                      flashEnabled: _flashEnabled,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}