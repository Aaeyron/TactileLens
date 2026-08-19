import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../services/scan/camera_service.dart';
import '../../styles/widgets/scan/scan_camera_preview_styles.dart';

class ScanCameraPreview extends StatefulWidget {
  const ScanCameraPreview({super.key, required this.cameraService});

  final CameraService cameraService;

  @override
  State<ScanCameraPreview> createState() {
    return _ScanCameraPreviewState();
  }
}

class _ScanCameraPreviewState extends State<ScanCameraPreview> {
  bool _isLoading = true;
  Offset? _focusPoint;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      await widget.cameraService.initialize();
    } catch (error, stackTrace) {
      debugPrint('Camera initialization failed: $error');

      debugPrintStack(stackTrace: stackTrace);
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

  Widget _buildLoadingState() {
    return const ColoredBox(
      color: ScanCameraPreviewStyles.backgroundColor,
      child: Center(
        child: SizedBox.square(
          dimension: ScanCameraPreviewStyles.loadingIndicatorSize,
          child: CircularProgressIndicator(
            strokeWidth: ScanCameraPreviewStyles.loadingIndicatorStrokeWidth,
            color: ScanCameraPreviewStyles.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return const ColoredBox(
      color: ScanCameraPreviewStyles.backgroundColor,
      child: Center(
        child: Text(
          ScanCameraPreviewStyles.cameraErrorText,
          textAlign: TextAlign.center,
          style: ScanCameraPreviewStyles.placeholderStyle,
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    final CameraController controller = widget.cameraService.controller!;

    final Size cameraPreviewSize = controller.value.previewSize!;

    return Container(
      width: double.infinity,
      height: ScanCameraPreviewStyles.previewHeight,
      decoration: BoxDecoration(
        color: ScanCameraPreviewStyles.backgroundColor,
        borderRadius: ScanCameraPreviewStyles.previewBorderRadius,
        border: Border.all(
          color: ScanCameraPreviewStyles.previewBorderColor,
          width: ScanCameraPreviewStyles.previewBorderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: ScanCameraPreviewStyles.previewBorderRadius,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _handleFocus,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              FittedBox(
                fit: ScanCameraPreviewStyles.previewImageFit,
                alignment: Alignment.center,
                child: SizedBox(
                  width: cameraPreviewSize.height,
                  height: cameraPreviewSize.width,
                  child: CameraPreview(controller),
                ),
              ),
              if (_focusPoint != null)
                Positioned(
                  left:
                      _focusPoint!.dx -
                      ScanCameraPreviewStyles.focusIndicatorHalfSize,
                  top:
                      _focusPoint!.dy -
                      ScanCameraPreviewStyles.focusIndicatorHalfSize,
                  child: Container(
                    width: ScanCameraPreviewStyles.focusIndicatorSize,
                    height: ScanCameraPreviewStyles.focusIndicatorSize,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: ScanCameraPreviewStyles.focusIndicatorColor,
                        width:
                            ScanCameraPreviewStyles.focusIndicatorBorderWidth,
                      ),
                      borderRadius:
                          ScanCameraPreviewStyles.focusIndicatorRadius,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleFocus(TapDownDetails details) async {
    final RenderObject? renderObject = context.findRenderObject();

    if (renderObject is! RenderBox) {
      return;
    }

    final Offset localPoint = renderObject.globalToLocal(
      details.globalPosition,
    );

    setState(() {
      _focusPoint = localPoint;
    });

    try {
      await widget.cameraService.focusOnPoint(localPoint, renderObject.size);
    } catch (error, stackTrace) {
      debugPrint('Camera focus failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    await Future<void>.delayed(ScanCameraPreviewStyles.focusIndicatorDuration);

    if (!mounted) {
      return;
    }

    setState(() {
      _focusPoint = null;
    });
  }
}
