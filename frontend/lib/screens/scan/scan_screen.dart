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
import '../../widgets/scan/scan_mode_selector.dart';
import '../../widgets/scan/scan_preview.dart';

class ScanScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ScanScreen({
    super.key,
    required this.onBack,
  });

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _selectedImage;
  Rect? _selectedRegion;
  Size? _previewSize;
  String? _recognizedLatex;
  ScanMode _selectedMode = ScanMode.ueb;
  bool _flashEnabled = false;

  final ScanService _scanService = ScanService();
  final CameraService _cameraService = CameraService();
  final AIService _aiService = AIService();
  final ImageCropService _imageCropService =
    ImageCropService();
  
  Future<void> _toggleFlash() async {
  await _cameraService.toggleFlash();

  setState(() {
    _flashEnabled = !_flashEnabled;
  });
}

  Future<void> _pickFile() async {
    final File? selectedFile = await _scanService.pickFile();

    if (selectedFile == null) {
      return;
    }

    setState(() {
      _selectedImage = selectedFile;
    });
  }

  Future<void> _captureImage() async {
  try {
    final File capturedImage =
        await _cameraService.captureImage();

    setState(() {
      _selectedImage = capturedImage;
    });
  } catch (e) {
    debugPrint('Camera capture failed: $e');
  }
}

Future<void> _scanImage() async {
  if (_selectedImage == null) {
    return;
  }

  if (_selectedRegion == null || _previewSize == null) {
    debugPrint("No region selected.");
    return;
  }

  try {
    final bytes = await _selectedImage!.readAsBytes();

    final decodedImage = img.decodeImage(bytes);

    if (decodedImage == null) {
      throw Exception("Unable to decode image.");
    }

    // Original image size
    final imageWidth = decodedImage.width.toDouble();
    final imageHeight = decodedImage.height.toDouble();

    // Preview size
    final previewWidth = _previewSize!.width;
    final previewHeight = _previewSize!.height;

    // Image aspect ratios
    final imageAspect = imageWidth / imageHeight;
    final previewAspect = previewWidth / previewHeight;

    // Actual displayed image size
    double displayedWidth;
    double displayedHeight;

    if (imageAspect > previewAspect) {
      displayedWidth = previewWidth;
      displayedHeight = previewWidth / imageAspect;
    } else {
      displayedHeight = previewHeight;
      displayedWidth = previewHeight * imageAspect;
    }

    // Empty margins introduced by BoxFit.contain
    final offsetX = (previewWidth - displayedWidth) / 2;
    final offsetY = (previewHeight - displayedHeight) / 2;

    // Remove margins
    double cropLeft = (_selectedRegion!.left - offsetX);
    double cropTop = (_selectedRegion!.top - offsetY);
    double cropWidth = _selectedRegion!.width;
    double cropHeight = _selectedRegion!.height;

    // Clamp so it never goes outside
    cropLeft = cropLeft.clamp(0.0, displayedWidth);
    cropTop = cropTop.clamp(0.0, displayedHeight);

    cropWidth = cropWidth.clamp(
      1.0,
      displayedWidth - cropLeft,
    );

    cropHeight = cropHeight.clamp(
      1.0,
      displayedHeight - cropTop,
    );

    // Convert to original image coordinates
    final scaleX = imageWidth / displayedWidth;
    final scaleY = imageHeight / displayedHeight;

  final Rect actualRegion = Rect.fromLTWH(
  (cropLeft * scaleX).roundToDouble(),
  (cropTop * scaleY).roundToDouble(),
  (cropWidth * scaleX).roundToDouble(),
  (cropHeight * scaleY).roundToDouble(),
);

    final File croppedImage =
        await _imageCropService.cropImage(
      imageFile: _selectedImage!,
      cropRect: actualRegion,
    );

    debugPrint("====== CROPPED IMAGE ======");
  debugPrint(croppedImage.path);

    final latex =
        await _aiService.recognizeEquation(croppedImage);

    setState(() {
      _recognizedLatex = latex;
    });

    debugPrint("Recognized LaTeX:");
    debugPrint(latex);

  } catch (e) {
    debugPrint("AI Error: $e");
  }
}

  void _onRegionSelected(
    Rect selectedRegion,
    Size previewSize,
  ) {
  setState(() {
    _selectedRegion = selectedRegion;
    _previewSize = previewSize;
  });
}

  void _onModeChanged(ScanMode mode) {
    setState(() {
      _selectedMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {

    final bool hasCapturedImage = _selectedImage != null;

    return Scaffold(
      backgroundColor: ScanScreenStyles.backgroundColor,

      body: SafeArea(
        child: Column(
          children: [
            Expanded(

             child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                      Padding(
                        padding: ScanScreenStyles.contentPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            const SizedBox(
                              height: ScanScreenStyles.backButtonTopSpacing,
                            ),

                            // ==============================
                            // Back Button
                            // ==============================

                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Color(0xFF0D47A1),
                                  ),
                                  onPressed: widget.onBack,
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: ScanScreenStyles.backButtonBottomSpacing,
                            ),

                            // ==============================
                            // Scan Mode Selector
                            // ==============================

                            ScanModeSelector(
                              selectedMode: _selectedMode,
                              onModeChanged: _onModeChanged,
                            ),

                            const SizedBox(
                              height: ScanScreenStyles.toggleBottomSpacing,
                            ),

                          ],
                        ),
                      ),

                    // ==============================
                    // Camera / Preview
                    // ==============================
                    _selectedImage == null
                        ? ScanCameraPreview(cameraService: _cameraService)
                        : ScanPreview(
                            selectedImage: _selectedImage,
                            onRegionSelected: _onRegionSelected,
                          ),

                    const SizedBox(
                      height: ScanScreenStyles.cameraBottomSpacing,
                    ),

                    // ==============================
                    // Buttons
                    // ==============================
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