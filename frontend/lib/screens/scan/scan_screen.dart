import 'dart:io';
import 'package:flutter/material.dart';

import '../../styles/screens/scan/scan_screen_styles.dart';
import '../../widgets/scan/scan_action_button.dart';
import '../../widgets/scan/scan_camera_preview.dart';
import '../../widgets/scan/scan_preview.dart';
import '../../services/scan/scan_service.dart';
import '../../services/scan/camera_service.dart';
import '../../widgets/scan/scan_mode_selector.dart';

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

  ScanMode _selectedMode = ScanMode.ueb;

  final ScanService _scanService = ScanService();

  final CameraService _cameraService = CameraService();

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
    final File capturedImage = await _cameraService.captureImage();

    setState(() {
      _selectedImage = capturedImage;
    });
  } catch (e) {
    debugPrint('Camera capture failed: $e');
  }
}

  void _onRegionSelected(Rect selectedRegion) {
    setState(() {
      _selectedRegion = selectedRegion;
    });
  }

  void _onModeChanged(ScanMode mode) {
    setState(() {
      _selectedMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScanScreenStyles.backgroundColor,

      body: SafeArea(
        child: Column(
          children: [
            Expanded(

              child: SingleChildScrollView(
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
                                color: Colors.black.withOpacity(0.08),
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
                      onCameraPressed: _captureImage,
                      onUploadPressed: _pickFile,
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