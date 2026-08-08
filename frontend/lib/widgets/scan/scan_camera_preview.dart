import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../services/scan/camera_service.dart';
import '../../styles/widgets/scan/scan_widget_styles.dart';

class ScanCameraPreview extends StatefulWidget {
  const ScanCameraPreview({
    super.key,
    required this.cameraService,
  });

  final CameraService cameraService;

  @override
  State<ScanCameraPreview> createState() =>
      _ScanCameraPreviewState();
}

class _ScanCameraPreviewState
    extends State<ScanCameraPreview> {
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

    if (!mounted) return;

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
    return Container(
      width: double.infinity,
      height: ScanWidgetStyles.previewHeight,
      alignment: Alignment.center,
      color: ScanWidgetStyles.previewBackgroundColor,
      child: const CircularProgressIndicator(
        color: ScanWidgetStyles.primaryBlue,
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      height: ScanWidgetStyles.previewHeight,
      alignment: Alignment.center,
      color: ScanWidgetStyles.previewBackgroundColor,
      child: const Text(
        ScanWidgetStyles.cameraErrorText,
        style: ScanWidgetStyles.previewPlaceholderStyle,
      ),
    );
  }

  Widget _buildCameraPreview() {
    final CameraController controller =
        widget.cameraService.controller!;

    final Size cameraPreviewSize =
        controller.value.previewSize!;

    return Container(
      width: double.infinity,
      height: ScanWidgetStyles.previewHeight,
      decoration: BoxDecoration(
        color: ScanWidgetStyles.previewBackgroundColor,
        borderRadius:
            ScanWidgetStyles.previewBorderRadius,
        border: Border.all(
          color: ScanWidgetStyles.previewBorderColor,
          width: ScanWidgetStyles.previewBorderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius:
            ScanWidgetStyles.previewBorderRadius,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _handleFocus,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              FittedBox(
                fit: ScanWidgetStyles.previewImageFit,
                alignment: Alignment.center,
                child: SizedBox(
                  width: cameraPreviewSize.height,
                  height: cameraPreviewSize.width,
                  child: CameraPreview(controller),
                ),
              ),
              if (_focusPoint != null)
                Positioned(
                  left: _focusPoint!.dx -
                      ScanWidgetStyles.focusIndicatorHalfSize,
                  top: _focusPoint!.dy -
                      ScanWidgetStyles.focusIndicatorHalfSize,
                  child: Container(
                    width:
                        ScanWidgetStyles.focusIndicatorSize,
                    height:
                        ScanWidgetStyles.focusIndicatorSize,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: ScanWidgetStyles
                            .focusIndicatorColor,
                        width: ScanWidgetStyles
                            .focusIndicatorBorderWidth,
                      ),
                      borderRadius: ScanWidgetStyles
                          .focusIndicatorRadius,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleFocus(
    TapDownDetails details,
  ) async {
    final RenderObject? renderObject =
        context.findRenderObject();

    if (renderObject is! RenderBox) return;

    final Offset localPoint =
        renderObject.globalToLocal(
      details.globalPosition,
    );

    setState(() {
      _focusPoint = localPoint;
    });

    try {
      await widget.cameraService.focusOnPoint(
        localPoint,
        renderObject.size,
      );
    } catch (error, stackTrace) {
      debugPrint('Camera focus failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    await Future<void>.delayed(
      ScanWidgetStyles.focusIndicatorDuration,
    );

    if (!mounted) return;

    setState(() {
      _focusPoint = null;
    });
  }
}