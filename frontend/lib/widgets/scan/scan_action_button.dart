import 'package:flutter/material.dart';

import '../../styles/widgets/scan/scan_widget_styles.dart';

class ScanActionButton extends StatelessWidget {
  const ScanActionButton({
    super.key,
    required this.hasCapturedImage,
    required this.onCameraPressed,
    required this.onScanPressed,
    required this.onUploadPressed,
    required this.onFlashPressed,
    required this.flashEnabled,
    this.isProcessing = false,
    this.flashAvailable = true,
  });

  final bool hasCapturedImage;
  final bool flashEnabled;
  final bool isProcessing;
  final bool flashAvailable;

  final VoidCallback onCameraPressed;
  final VoidCallback onScanPressed;
  final VoidCallback onUploadPressed;
  final VoidCallback onFlashPressed;

  bool get _canUseFlash {
    return flashAvailable && !hasCapturedImage && !isProcessing;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: ScanWidgetStyles.actionButtonBottomPadding,
      ),
      child: Padding(
        padding: ScanWidgetStyles.actionButtonHorizontalPadding,
        child: Row(
          mainAxisAlignment: ScanWidgetStyles.actionButtonAlignment,
          crossAxisAlignment:
              ScanWidgetStyles.actionButtonCrossAlignment,
          children: [
            _buildUploadButton(),
            _buildPrimaryButton(),
            _buildFlashButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    final isEnabled = !isProcessing;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: ScanWidgetStyles.uploadButtonLabel,
      child: AnimatedOpacity(
        opacity: isEnabled
            ? ScanWidgetStyles.enabledButtonOpacity
            : ScanWidgetStyles.disabledButtonOpacity,
        duration: ScanWidgetStyles.buttonOpacityDuration,
        child: GestureDetector(
          onTap: isEnabled ? onUploadPressed : null,
          child: _buildSecondaryButton(
            child: const Icon(
              ScanWidgetStyles.galleryButtonIcon,
              size: ScanWidgetStyles.galleryIconSize,
              color: ScanWidgetStyles.primaryBlue,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    final semanticsLabel = isProcessing
        ? ScanWidgetStyles.processingButtonLabel
        : hasCapturedImage
            ? ScanWidgetStyles.scanButtonLabel
            : ScanWidgetStyles.cameraButtonLabel;

    return Semantics(
      button: true,
      enabled: !isProcessing,
      label: semanticsLabel,
      child: GestureDetector(
        onTap: isProcessing
            ? null
            : hasCapturedImage
                ? onScanPressed
                : onCameraPressed,
        child: Container(
          width: ScanWidgetStyles.captureButtonSize,
          height: ScanWidgetStyles.captureButtonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ScanWidgetStyles.primaryBlue,
            border: Border.all(
              color: ScanWidgetStyles.galleryBackgroundColor,
              width: ScanWidgetStyles.captureBorderWidth,
            ),
            boxShadow: ScanWidgetStyles.captureButtonShadow,
          ),
          alignment: Alignment.center,
          child: isProcessing
              ? const SizedBox.square(
                  dimension:
                      ScanWidgetStyles.processingIndicatorSize,
                  child: CircularProgressIndicator(
                    strokeWidth:
                        ScanWidgetStyles.processingIndicatorStrokeWidth,
                    color:
                        ScanWidgetStyles.processingIndicatorColor,
                  ),
                )
              : Icon(
                  hasCapturedImage
                      ? ScanWidgetStyles.scanButtonIcon
                      : ScanWidgetStyles.captureButtonIcon,
                  color: ScanWidgetStyles.captureIconColor,
                  size: ScanWidgetStyles.captureIconSize,
                ),
        ),
      ),
    );
  }

  Widget _buildFlashButton() {
    return Semantics(
      button: true,
      enabled: _canUseFlash,
      label: ScanWidgetStyles.flashButtonLabel,
      child: AnimatedOpacity(
        opacity: _canUseFlash
            ? ScanWidgetStyles.enabledButtonOpacity
            : ScanWidgetStyles.disabledButtonOpacity,
        duration: ScanWidgetStyles.buttonOpacityDuration,
        child: GestureDetector(
          onTap: _canUseFlash ? onFlashPressed : null,
          child: _buildSecondaryButton(
            child: Icon(
              flashEnabled
                  ? ScanWidgetStyles.flashEnabledIcon
                  : ScanWidgetStyles.flashDisabledIcon,
              color: flashEnabled && _canUseFlash
                  ? ScanWidgetStyles.flashEnabledColor
                  : ScanWidgetStyles.flashDisabledColor,
              size: ScanWidgetStyles.flashIconSize,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required Widget child,
  }) {
    return Container(
      width: ScanWidgetStyles.galleryButtonSize,
      height: ScanWidgetStyles.galleryButtonSize,
      decoration: BoxDecoration(
        color: ScanWidgetStyles.galleryBackgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: ScanWidgetStyles.galleryBorderColor,
          width: ScanWidgetStyles.galleryBorderWidth,
        ),
        boxShadow: ScanWidgetStyles.secondaryButtonShadow,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}