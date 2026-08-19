import 'package:flutter/material.dart';

import '../../styles/widgets/scan/scan_action_button_styles.dart';

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
        bottom: ScanActionButtonStyles.bottomPadding,
      ),
      child: Padding(
        padding: ScanActionButtonStyles.horizontalPadding,
        child: Row(
          mainAxisAlignment: ScanActionButtonStyles.alignment,
          crossAxisAlignment: ScanActionButtonStyles.crossAlignment,
          children: <Widget>[
            _buildUploadButton(),
            _buildPrimaryButton(),
            _buildFlashButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    final bool isEnabled = !isProcessing;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: ScanActionButtonStyles.uploadButtonLabel,
      child: AnimatedOpacity(
        opacity: isEnabled
            ? ScanActionButtonStyles.enabledOpacity
            : ScanActionButtonStyles.disabledOpacity,
        duration: ScanActionButtonStyles.opacityDuration,
        child: GestureDetector(
          onTap: isEnabled ? onUploadPressed : null,
          child: _buildSecondaryButton(
            child: const Icon(
              ScanActionButtonStyles.galleryIcon,
              size: ScanActionButtonStyles.galleryIconSize,
              color: ScanActionButtonStyles.primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    final String semanticsLabel = isProcessing
        ? ScanActionButtonStyles.processingButtonLabel
        : hasCapturedImage
        ? ScanActionButtonStyles.scanButtonLabel
        : ScanActionButtonStyles.cameraButtonLabel;

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
          width: ScanActionButtonStyles.captureButtonSize,
          height: ScanActionButtonStyles.captureButtonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ScanActionButtonStyles.primaryColor,
            border: Border.all(
              color: ScanActionButtonStyles.secondaryButtonColor,
              width: ScanActionButtonStyles.captureBorderWidth,
            ),
            boxShadow: ScanActionButtonStyles.captureButtonShadow,
          ),
          alignment: Alignment.center,
          child: isProcessing
              ? const SizedBox.square(
                  dimension: ScanActionButtonStyles.processingIndicatorSize,
                  child: CircularProgressIndicator(
                    strokeWidth:
                        ScanActionButtonStyles.processingIndicatorStrokeWidth,
                    color: ScanActionButtonStyles.processingIndicatorColor,
                  ),
                )
              : Icon(
                  hasCapturedImage
                      ? ScanActionButtonStyles.scanIcon
                      : ScanActionButtonStyles.captureIcon,
                  color: ScanActionButtonStyles.captureIconColor,
                  size: ScanActionButtonStyles.captureIconSize,
                ),
        ),
      ),
    );
  }

  Widget _buildFlashButton() {
    return Semantics(
      button: true,
      enabled: _canUseFlash,
      label: ScanActionButtonStyles.flashButtonLabel,
      child: AnimatedOpacity(
        opacity: _canUseFlash
            ? ScanActionButtonStyles.enabledOpacity
            : ScanActionButtonStyles.disabledOpacity,
        duration: ScanActionButtonStyles.opacityDuration,
        child: GestureDetector(
          onTap: _canUseFlash ? onFlashPressed : null,
          child: _buildSecondaryButton(
            child: Icon(
              flashEnabled
                  ? ScanActionButtonStyles.flashEnabledIcon
                  : ScanActionButtonStyles.flashDisabledIcon,
              color: flashEnabled && _canUseFlash
                  ? ScanActionButtonStyles.flashEnabledColor
                  : ScanActionButtonStyles.flashDisabledColor,
              size: ScanActionButtonStyles.flashIconSize,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({required Widget child}) {
    return Container(
      width: ScanActionButtonStyles.secondaryButtonSize,
      height: ScanActionButtonStyles.secondaryButtonSize,
      decoration: BoxDecoration(
        color: ScanActionButtonStyles.secondaryButtonColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: ScanActionButtonStyles.secondaryBorderColor,
          width: ScanActionButtonStyles.secondaryBorderWidth,
        ),
        boxShadow: ScanActionButtonStyles.secondaryButtonShadow,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
