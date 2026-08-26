import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../services/scan/camera_service.dart';
import '../../styles/widgets/scan/scan_camera_preview_styles.dart';

abstract final class _ScanCameraPreviewText {
  static const String cameraError = 'Unable to open camera.';
}

class ScanCameraPreview extends StatefulWidget {
  const ScanCameraPreview({
    super.key,
    required this.cameraService,
    this.onOrientationChanged,
  });

  final CameraService cameraService;

  final ValueChanged<DeviceOrientation>? onOrientationChanged;

  @override
  State<ScanCameraPreview> createState() {
    return _ScanCameraPreviewState();
  }
}

class _ScanCameraPreviewState extends State<ScanCameraPreview> {
  bool _isLoading = true;

  Offset? _focusPoint;

  DeviceOrientation? _lastReportedOrientation;

  StreamSubscription<AccelerometerEvent>? _orientationSubscription;

  CameraController? get _controller {
    return widget.cameraService.controller;
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _startPhysicalOrientationDetection() {
    _orientationSubscription?.cancel();

    _orientationSubscription =
        accelerometerEventStream(
          samplingPeriod: SensorInterval.normalInterval,
        ).listen(
          _handleAccelerometerEvent,
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('Physical orientation sensor failed: $error');
            debugPrintStack(stackTrace: stackTrace);
          },
        );
  }

  void _handleAccelerometerEvent(AccelerometerEvent event) {
    if (!mounted) {
      return;
    }

    final double horizontalGravity = event.x.abs();
    final double verticalGravity = event.y.abs();

    // Ignore readings while the phone is nearly flat or being moved.
    if (horizontalGravity < 4 && verticalGravity < 4) {
      return;
    }

    DeviceOrientation detectedOrientation;

    if (horizontalGravity > verticalGravity) {
      detectedOrientation = event.x >= 0
          ? DeviceOrientation.landscapeLeft
          : DeviceOrientation.landscapeRight;
    } else {
      detectedOrientation = event.y >= 0
          ? DeviceOrientation.portraitUp
          : DeviceOrientation.portraitDown;
    }

    _reportPhysicalOrientation(detectedOrientation);
  }

  void _reportPhysicalOrientation(DeviceOrientation orientation) {
    if (_lastReportedOrientation == orientation) {
      return;
    }

    _lastReportedOrientation = orientation;

    debugPrint('Physical device orientation: $orientation');

    widget.onOrientationChanged?.call(orientation);
  }

  Future<void> _initializeCamera() async {
    try {
      await widget.cameraService.initialize();

      _startPhysicalOrientationDetection();
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
    _orientationSubscription?.cancel();
    _orientationSubscription = null;

    widget.cameraService.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return _buildErrorState();
    }

    return _buildCameraPreview(cameraController);
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
          _ScanCameraPreviewText.cameraError,
          textAlign: TextAlign.center,
          style: ScanCameraPreviewStyles.placeholderStyle,
        ),
      ),
    );
  }

  Widget _buildCameraPreview(CameraController cameraController) {
    final Size? rawPreviewSize = cameraController.value.previewSize;

    if (rawPreviewSize == null || rawPreviewSize.isEmpty) {
      return _buildLoadingState();
    }

    /*
     * Keep the live camera preview exactly as it originally was.
     * It follows the application layout rather than being manually
     * rotated using the physical camera orientation.
     */
    final Orientation screenOrientation = MediaQuery.orientationOf(context);

    final bool screenIsPortrait = screenOrientation == Orientation.portrait;

    final Size orientedPreviewSize = screenIsPortrait
        ? Size(rawPreviewSize.height, rawPreviewSize.width)
        : Size(rawPreviewSize.width, rawPreviewSize.height);

    final double previewHeight = screenIsPortrait
        ? ScanCameraPreviewStyles.portraitPreviewHeight
        : ScanCameraPreviewStyles.landscapePreviewHeight;

    return Container(
      width: double.infinity,
      height: previewHeight,
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
                  width: orientedPreviewSize.width,
                  height: orientedPreviewSize.height,
                  child: CameraPreview(cameraController),
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
