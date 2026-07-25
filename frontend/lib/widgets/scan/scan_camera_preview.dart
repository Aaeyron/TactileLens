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

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

    } catch (_) {

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    widget.cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if (_isLoading) {
      return Container(
        height: ScanWidgetStyles.previewHeight,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (!widget.cameraService.isInitialized) {
      return Container(
        height: ScanWidgetStyles.previewHeight,
        alignment: Alignment.center,
        child: const Text(
          "Unable to open camera.",
        ),
      );
    }

    return ClipRRect(
      borderRadius:
          ScanWidgetStyles.previewBorderRadius,
      child: SizedBox(
        height: ScanWidgetStyles.previewHeight,
        width: double.infinity,
        child: CameraPreview(
         widget.cameraService.controller!,
        ),
      ),
    );
  }
}