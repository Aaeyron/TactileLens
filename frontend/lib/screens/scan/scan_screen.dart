import 'dart:io';
import 'package:flutter/material.dart';

import '../../styles/screens/scan/scan_screen_styles.dart';
import '../../widgets/app_header.dart';
import '../../widgets/scan/scan_action_buttons.dart';
import '../../widgets/scan/scan_camera_preview.dart';
import '../../widgets/scan/scan_preview.dart';
import '../../services/scan/scan_service.dart';
import '../../services/scan/camera_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});


  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _selectedImage;
  Rect? _selectedRegion;

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
  final File? capturedImage =
      await _scanService.captureImage();

  if (capturedImage == null) {
    return;
  }

  setState(() {
    _selectedImage = capturedImage;
  });
}

  void _onRegionSelected(Rect selectedRegion) {
  setState(() {
    _selectedRegion = selectedRegion;
  });
}

 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScanScreenStyles.backgroundColor,

      body: Column(
        children: [

          const AppHeader(),

          Expanded(
            child: SingleChildScrollView(
              padding: ScanScreenStyles.contentPadding,

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  const SizedBox(
                    height: ScanScreenStyles.topContentSpacing,
                  ),

                  const Text(
                    "Scan Material",
                    style: ScanScreenStyles.pageTitleStyle,
                  ),

                  const SizedBox(
                      height: ScanScreenStyles.titleDescriptionSpacing,
                    ),

                  const Text(
                    "Upload or capture learning materials for OCR recognition and Nemeth Braille translation.",
                    style: ScanScreenStyles.pageDescriptionStyle,
                  ),

                  const SizedBox(
                    height: ScanScreenStyles.sectionSpacing,
                  ),

                  // ==============================
                  // Camera / Preview
                  // ==============================

                  _selectedImage == null
                      ? ScanCameraPreview(
                          cameraService: _cameraService,
                        )
                        : ScanPreview(
                          selectedImage: _selectedImage,
                          onRegionSelected: _onRegionSelected,
                        ),

                  // ==============================
                  // Buttons
                  // ==============================

                   ScanActionButtons(
                    onCameraPressed: _captureImage,
                    onUploadPressed: _pickFile,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}