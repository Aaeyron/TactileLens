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

  Future<void> _toggleFlash() async {
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
    final File? selectedFile = await _scanService.pickFile();

    if (selectedFile == null || !mounted) return;

    _setSelectedImage(selectedFile);
  }

  Future<void> _captureImage() async {
    try {
      final File capturedImage = await _cameraService.captureImage();

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
    });
  }

  Future<void> _scanImage() async {
    final File? selectedImage = _selectedImage;
    final Rect? selectedRegion = _selectedRegion;
    final Size? previewSize = _previewSize;

    if (selectedImage == null) return;

    if (selectedRegion == null || previewSize == null) {
      debugPrint('No region selected.');
      return;
    }

    try {
      final bytes = await selectedImage.readAsBytes();
      final img.Image? decodedImage = img.decodeImage(bytes);

      if (decodedImage == null) {
        throw const FormatException('Unable to decode image.');
      }

      final Rect actualRegion = _mapPreviewRegionToImage(
        selectedRegion: selectedRegion,
        previewSize: previewSize,
        imageSize: Size(
          decodedImage.width.toDouble(),
          decodedImage.height.toDouble(),
        ),
      );

      final File croppedImage = await _imageCropService.cropImage(
        imageFile: selectedImage,
        cropRect: actualRegion,
      );

      debugPrint('Cropped image: ${croppedImage.path}');

      final String recognizedLatex =
          await _aiService.recognizeEquation(croppedImage);

      if (!mounted) return;

      debugPrint('Recognized LaTeX: $recognizedLatex');
    } catch (error, stackTrace) {
      debugPrint('Scan failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Rect _mapPreviewRegionToImage({
    required Rect selectedRegion,
    required Size previewSize,
    required Size imageSize,
  }) {
    if (previewSize.isEmpty || imageSize.isEmpty) {
      throw const FormatException('Invalid image or preview dimensions.');
    }

    final double imageAspectRatio = imageSize.aspectRatio;
    final double previewAspectRatio = previewSize.aspectRatio;

    final Size displayedImageSize = imageAspectRatio > previewAspectRatio
        ? Size(previewSize.width, previewSize.width / imageAspectRatio)
        : Size(previewSize.height * imageAspectRatio, previewSize.height);

    final Offset displayedImageOffset = Offset(
      (previewSize.width - displayedImageSize.width) / 2,
      (previewSize.height - displayedImageSize.height) / 2,
    );

    final Rect displayedImageBounds =
        displayedImageOffset & displayedImageSize;
    final Rect clippedRegion = selectedRegion.intersect(displayedImageBounds);

    if (clippedRegion.isEmpty) {
      throw const FormatException(
        'The selected region is outside the displayed image.',
      );
    }

    final double scaleX = imageSize.width / displayedImageSize.width;
    final double scaleY = imageSize.height / displayedImageSize.height;

    return Rect.fromLTWH(
      ((clippedRegion.left - displayedImageOffset.dx) * scaleX)
          .roundToDouble(),
      ((clippedRegion.top - displayedImageOffset.dy) * scaleY)
          .roundToDouble(),
      (clippedRegion.width * scaleX).roundToDouble(),
      (clippedRegion.height * scaleY).roundToDouble(),
    );
  }

  void _onRegionSelected(Rect selectedRegion, Size previewSize) {
    setState(() {
      _selectedRegion = selectedRegion;
      _previewSize = previewSize;
    });
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(
                            height: ScanScreenStyles.backButtonTopSpacing,
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              decoration:
                                  ScanScreenStyles.backButtonDecoration,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: ScanScreenStyles.backButtonColor,
                                ),
                                onPressed: widget.onBack,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: ScanScreenStyles.backButtonBottomSpacing,
                          ),
                        ],
                      ),
                    ),
                    if (_selectedImage == null)
                      ScanCameraPreview(cameraService: _cameraService)
                    else
                      ScanPreview(
                        selectedImage: _selectedImage,
                        onRegionSelected: _onRegionSelected,
                      ),
                    const SizedBox(
                      height: ScanScreenStyles.cameraBottomSpacing,
                    ),
                    ScanActionButton(
                      hasCapturedImage: hasCapturedImage,
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
