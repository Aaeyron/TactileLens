import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../services/scan/camera_service.dart';
import '../../styles/widgets/scan/scan_widget_styles.dart';

class ScanCameraPreview extends StatefulWidget {
  final CameraService cameraService;

  const ScanCameraPreview({
    super.key,
    required this.cameraService,
  });

  @override
  State<ScanCameraPreview> createState() =>
      _ScanCameraPreviewState();
}

class _ScanCameraPreviewState
    extends State<ScanCameraPreview> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      await widget.cameraService.initialize();
    } catch (_) {
      // Camera initialization failed.
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    widget.cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (!widget.cameraService.isInitialized) {
      return _buildErrorState();
    }

    return _buildCameraPreview();
  }

  // ============================================================
  // Loading State
  // ============================================================

  Widget _buildLoadingState() {
    return Container(
      height: ScanWidgetStyles.previewHeight,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }

  // ============================================================
  // Error State
  // ============================================================

  Widget _buildErrorState() {
    return Container(
      height: ScanWidgetStyles.previewHeight,
      alignment: Alignment.center,
      child: const Text(
        ScanWidgetStyles.cameraErrorText,
      ),
    );
  }

  // ============================================================
  // Camera Preview
  // ============================================================

  Widget _buildCameraPreview() {
    return Container(
      width: double.infinity,
      height: ScanWidgetStyles.previewHeight,
      decoration: BoxDecoration(
        color: ScanWidgetStyles.previewBackgroundColor,
        borderRadius: ScanWidgetStyles.previewBorderRadius,
        border: Border.all(
          color: ScanWidgetStyles.previewBorderColor,
          width: ScanWidgetStyles.previewBorderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: ScanWidgetStyles.previewBorderRadius,
        child: CameraPreview(
          widget.cameraService.controller!,
        ),
      ),
    );
  }
}