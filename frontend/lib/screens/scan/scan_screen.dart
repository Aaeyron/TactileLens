import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../models/ai/scan_document_result.dart';
import '../../services/ai/ai_service.dart';
import '../../services/history/history_service.dart';
import '../../services/scan/camera_service.dart';
import '../../services/scan/image_crop_service.dart';
import '../../services/scan/scan_service.dart';
import '../../styles/screens/scan/scan_screen_styles.dart';
import '../../widgets/scan/scan_camera_preview.dart';
import '../../widgets/scan/scan_preview.dart';
import 'scan_result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<ScanScreen> createState() {
    return _ScanScreenState();
  }
}

class _ScanScreenState extends State<ScanScreen> {
  final ScanService _scanService = ScanService();
  final CameraService _cameraService = CameraService();
  final AIService _aiService = AIService();
  final HistoryService _historyService = HistoryService();

  final ImageCropService _imageCropService = ImageCropService();

  File? _selectedImage;
  Rect? _selectedRegion;
  Size? _previewSize;

  bool _flashEnabled = false;
  bool _isProcessing = false;

  bool get _hasSelectedImage {
    return _selectedImage != null;
  }

  Future<void> _toggleFlash() async {
    if (_hasSelectedImage || _isProcessing) {
      return;
    }

    try {
      await _cameraService.toggleFlash();

      if (!mounted) {
        return;
      }

      setState(() {
        _flashEnabled = !_flashEnabled;
      });
    } catch (error, stackTrace) {
      debugPrint('Flash toggle failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        _showScanError('The camera flash could not be changed.');
      }
    }
  }

  Future<void> _pickFile() async {
    if (_isProcessing) {
      return;
    }

    try {
      final File? selectedFile = await _scanService.pickFile();

      if (selectedFile == null || !mounted) {
        return;
      }

      _setSelectedImage(selectedFile);
    } catch (error, stackTrace) {
      debugPrint('Image selection failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        _showScanError('Unable to select an image. Please try again.');
      }
    }
  }

  Future<void> _captureImage() async {
    if (_isProcessing) {
      return;
    }

    try {
      final File capturedImage = await _cameraService.captureImage();

      if (!mounted) {
        return;
      }

      _setSelectedImage(capturedImage);
    } catch (error, stackTrace) {
      debugPrint('Camera capture failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        _showScanError('Unable to capture the document. Please try again.');
      }
    }
  }

  void _setSelectedImage(File imageFile) {
    setState(() {
      _selectedImage = imageFile;
      _selectedRegion = null;
      _previewSize = null;
      _flashEnabled = false;
    });
  }

  void _retakeImage() {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _selectedImage = null;
      _selectedRegion = null;
      _previewSize = null;
      _flashEnabled = false;
    });
  }

  String _createAutomaticHistoryTitle(ScanDocumentResult result) {
    if (result.hasText && result.hasFormulas) {
      return ScanScreenStyles.textAndEquationHistoryTitle;
    }

    if (result.hasFormulas) {
      return ScanScreenStyles.equationHistoryTitle;
    }

    if (result.hasText) {
      return ScanScreenStyles.textHistoryTitle;
    }

    return ScanScreenStyles.documentHistoryTitle;
  }

  Future<void> _saveScanToHistory(ScanDocumentResult result) async {
    final String recognizedContent = result.blocks
        .map((DocumentBlock block) => block.content.trim())
        .where((String content) => content.isNotEmpty)
        .join('\n\n');

    final List<Map<String, dynamic>> documentBlocks = result.blocks
        .map((DocumentBlock block) => block.toJson())
        .toList(growable: false);

    try {
      await _historyService.createHistory(
        title: _createAutomaticHistoryTitle(result),
        recognizedContent: recognizedContent,
        brailleContent: result.combinedBraille,
        documentBlocks: documentBlocks,
        modelName: result.model,
        pipelineVersion: result.pipelineVersion,
        processingTimeMs: result.processingTimeMs,
      );

      debugPrint('Scan was automatically added to History.');
    } on HistoryServiceException catch (error, stackTrace) {
      debugPrint(
        'Automatic History save failed: '
        '${error.message}',
      );

      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        _showScanError(ScanScreenStyles.historySaveFailureMessage);
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Unexpected automatic History save error: '
        '$error',
      );

      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        _showScanError(ScanScreenStyles.historySaveFailureMessage);
      }
    }
  }

  Future<void> _scanImage() async {
    final File? selectedImage = _selectedImage;

    if (selectedImage == null || _isProcessing) {
      return;
    }

    final bool shouldScan = await _confirmDocumentScan();

    if (!shouldScan || !mounted) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final File imageToScan = await _prepareImageForScanning(selectedImage);

      if (!mounted) {
        return;
      }

      debugPrint(
        'Sending image to PaddleOCR-VL: '
        '${imageToScan.path}',
      );

      final ScanDocumentResult scanResult = await _aiService.scanDocument(
        imageToScan,
      );

      if (!mounted) {
        return;
      }

      unawaited(_saveScanToHistory(scanResult));

      debugPrint('PaddleOCR-VL scan completed successfully.');

      debugPrint(
        'AI processing time: '
        '${scanResult.processingTimeMs} ms',
      );

      debugPrint(
        'Detected blocks: '
        '${scanResult.blocks.length}',
      );

      for (final DocumentBlock block in scanResult.blocks) {
        debugPrint('[${block.type}] ${block.content}');
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isProcessing = false;
      });

      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return ScanResultScreen(
              result: scanResult,
              scannedImage: imageToScan,
            );
          },
        ),
      );

      if (!mounted) {
        return;
      }

      _retakeImage();
    } on AIServiceException catch (error, stackTrace) {
      debugPrint('AI service error: ${error.message}');

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      _showScanError(error.message);
    } catch (error, stackTrace) {
      debugPrint('Document scan failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      _showScanError(ScanScreenStyles.scanFailureMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<bool> _confirmDocumentScan() async {
    final bool? shouldContinue = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: ScanScreenStyles.confirmationSheetColor,
            borderRadius: ScanScreenStyles.confirmationSheetRadius,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: ScanScreenStyles.confirmationSheetPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: ScanScreenStyles.confirmationHandleWidth,
                      height: ScanScreenStyles.confirmationHandleHeight,
                      decoration: const BoxDecoration(
                        color: ScanScreenStyles.confirmationHandleColor,
                        borderRadius: ScanScreenStyles.confirmationHandleRadius,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: ScanScreenStyles.confirmationTopSpacing,
                  ),
                  Center(
                    child: Container(
                      width: ScanScreenStyles.confirmationIconContainerSize,
                      height: ScanScreenStyles.confirmationIconContainerSize,
                      decoration: const BoxDecoration(
                        color: ScanScreenStyles.confirmationIconBackgroundColor,
                        borderRadius: ScanScreenStyles.confirmationIconRadius,
                      ),
                      child: const Icon(
                        ScanScreenStyles.confirmationHeaderIcon,
                        size: ScanScreenStyles.confirmationIconSize,
                        color: ScanScreenStyles.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: ScanScreenStyles.confirmationTitleSpacing,
                  ),
                  const Text(
                    ScanScreenStyles.confirmationTitle,
                    textAlign: TextAlign.center,
                    style: ScanScreenStyles.confirmationTitleStyle,
                  ),
                  const SizedBox(
                    height: ScanScreenStyles.confirmationDescriptionSpacing,
                  ),
                  const Text(
                    ScanScreenStyles.confirmationDescription,
                    textAlign: TextAlign.center,
                    style: ScanScreenStyles.confirmationDescriptionStyle,
                  ),
                  const SizedBox(
                    height: ScanScreenStyles.confirmationDetailsSpacing,
                  ),
                  const _ScanConfirmationDetail(
                    icon: ScanScreenStyles.selectedAreaIcon,
                    text: ScanScreenStyles.selectedAreaDetail,
                  ),
                  const SizedBox(
                    height: ScanScreenStyles.confirmationDetailSpacing,
                  ),
                  const _ScanConfirmationDetail(
                    icon: ScanScreenStyles.recognitionIcon,
                    text: ScanScreenStyles.recognitionDetail,
                  ),
                  const SizedBox(
                    height: ScanScreenStyles.confirmationDetailSpacing,
                  ),
                  const _ScanConfirmationDetail(
                    icon: ScanScreenStyles.brailleOutputIcon,
                    text: ScanScreenStyles.brailleDetail,
                  ),
                  const SizedBox(
                    height: ScanScreenStyles.confirmationDetailSpacing,
                  ),
                  const _ScanConfirmationDetail(
                    icon: ScanScreenStyles.processingTimeIcon,
                    text: ScanScreenStyles.processingDetail,
                  ),
                  const SizedBox(
                    height: ScanScreenStyles.confirmationButtonsSpacing,
                  ),
                  SizedBox(
                    height: ScanScreenStyles.confirmationButtonHeight,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop(false);
                      },
                      style: ScanScreenStyles.adjustCropButtonStyle,
                      icon: const Icon(
                        ScanScreenStyles.adjustCropIcon,
                        size: ScanScreenStyles.confirmationButtonIconSize,
                      ),
                      label: const Text(
                        ScanScreenStyles.adjustCropLabel,
                        style:
                            ScanScreenStyles.confirmationSecondaryButtonStyle,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: ScanScreenStyles.confirmationButtonGap,
                  ),
                  SizedBox(
                    height: ScanScreenStyles.confirmationButtonHeight,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop(true);
                      },
                      style: ScanScreenStyles.scanDocumentButtonStyle,
                      child: const Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              ScanScreenStyles.scanDocumentLabel,
                              textAlign: TextAlign.center,
                              style: ScanScreenStyles
                                  .confirmationPrimaryButtonStyle,
                            ),
                          ),
                          Icon(
                            ScanScreenStyles.scanDocumentIcon,
                            size: ScanScreenStyles.confirmationButtonIconSize,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return shouldContinue ?? false;
  }

  Future<File> _prepareImageForScanning(File selectedImage) async {
    final Rect? selectedRegion = _selectedRegion;
    final Size? previewSize = _previewSize;

    if (selectedRegion == null || previewSize == null) {
      return selectedImage;
    }

    final bytes = await selectedImage.readAsBytes();

    final img.Image? decodedImage = img.decodeImage(bytes);

    if (decodedImage == null) {
      throw const FormatException('Unable to decode the selected image.');
    }

    final Rect actualRegion = _mapPreviewRegionToImage(
      selectedRegion: selectedRegion,
      previewSize: previewSize,
      imageSize: Size(
        decodedImage.width.toDouble(),
        decodedImage.height.toDouble(),
      ),
    );

    return _imageCropService.cropImage(
      imageFile: selectedImage,
      cropRect: actualRegion,
    );
  }

  Rect _mapPreviewRegionToImage({
    required Rect selectedRegion,
    required Size previewSize,
    required Size imageSize,
  }) {
    if (previewSize.isEmpty || imageSize.isEmpty) {
      throw const FormatException('Invalid image or preview dimensions.');
    }

    final double widthScale = previewSize.width / imageSize.width;

    final double heightScale = previewSize.height / imageSize.height;

    final double coverScale = widthScale > heightScale
        ? widthScale
        : heightScale;

    final Size displayedImageSize = Size(
      imageSize.width * coverScale,
      imageSize.height * coverScale,
    );

    final Offset displayedImageOffset = Offset(
      (previewSize.width - displayedImageSize.width) / 2,
      (previewSize.height - displayedImageSize.height) / 2,
    );

    final Rect previewBounds = Offset.zero & previewSize;

    final Rect clippedRegion = selectedRegion.intersect(previewBounds);

    if (clippedRegion.isEmpty) {
      throw const FormatException('The selected crop area is invalid.');
    }

    final double left =
        ((clippedRegion.left - displayedImageOffset.dx) / coverScale)
            .clamp(0.0, imageSize.width)
            .toDouble();

    final double top =
        ((clippedRegion.top - displayedImageOffset.dy) / coverScale)
            .clamp(0.0, imageSize.height)
            .toDouble();

    final double right =
        ((clippedRegion.right - displayedImageOffset.dx) / coverScale)
            .clamp(0.0, imageSize.width)
            .toDouble();

    final double bottom =
        ((clippedRegion.bottom - displayedImageOffset.dy) / coverScale)
            .clamp(0.0, imageSize.height)
            .toDouble();

    if (right <= left || bottom <= top) {
      throw const FormatException('The selected crop area is too small.');
    }

    return Rect.fromLTRB(
      left.roundToDouble(),
      top.roundToDouble(),
      right.roundToDouble(),
      bottom.roundToDouble(),
    );
  }

  void _onRegionSelected(Rect selectedRegion, Size previewSize) {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _selectedRegion = selectedRegion;
      _previewSize = previewSize;
    });
  }

  void _clearSelectedRegion() {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _selectedRegion = null;
      _previewSize = null;
    });
  }

  void _showScanError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: ScanScreenStyles.snackBarDuration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: ScanScreenStyles.primaryDarkColor,
          margin: ScanScreenStyles.snackBarMargin,
          shape: const RoundedRectangleBorder(
            borderRadius: ScanScreenStyles.snackBarRadius,
          ),
          content: Text(message, style: ScanScreenStyles.snackBarTextStyle),
        ),
      );
  }

  Future<void> _showScanningHelp() async {
    if (_isProcessing) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: ScanScreenStyles.dialogBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: ScanScreenStyles.helpSheetRadius,
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: ScanScreenStyles.helpSheetPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: ScanScreenStyles.helpHandleWidth,
                    height: ScanScreenStyles.helpHandleHeight,
                    decoration: const BoxDecoration(
                      color: ScanScreenStyles.helpHandleColor,
                      borderRadius: ScanScreenStyles.helpHandleRadius,
                    ),
                  ),
                ),
                const SizedBox(height: ScanScreenStyles.helpTitleTopSpacing),
                const Text(
                  ScanScreenStyles.helpTitle,
                  style: ScanScreenStyles.helpTitleStyle,
                ),
                const SizedBox(height: ScanScreenStyles.helpDescriptionSpacing),
                const Text(
                  ScanScreenStyles.helpDescription,
                  style: ScanScreenStyles.helpDescriptionStyle,
                ),
                const SizedBox(height: ScanScreenStyles.helpTipTopSpacing),
                const _ScanningTip(
                  icon: Icons.light_mode_outlined,
                  text: ScanScreenStyles.lightingTip,
                ),
                const SizedBox(height: ScanScreenStyles.helpTipSpacing),
                const _ScanningTip(
                  icon: Icons.document_scanner_outlined,
                  text: ScanScreenStyles.alignmentTip,
                ),
                const SizedBox(height: ScanScreenStyles.helpTipSpacing),
                const _ScanningTip(
                  icon: Icons.center_focus_strong_outlined,
                  text: ScanScreenStyles.stabilityTip,
                ),
                const SizedBox(height: ScanScreenStyles.helpTipSpacing),
                const _ScanningTip(
                  icon: Icons.text_fields_rounded,
                  text: ScanScreenStyles.printedMaterialTip,
                ),
                const SizedBox(height: ScanScreenStyles.helpButtonTopSpacing),
                SizedBox(
                  height: ScanScreenStyles.helpButtonHeight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                    },
                    style: ScanScreenStyles.helpButtonStyle,
                    child: const Text(ScanScreenStyles.closeLabel),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _aiService.dispose();
    _historyService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScanScreenStyles.backgroundColor,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _buildHeader(),
            Expanded(child: _buildCameraArea()),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ColoredBox(
      color: ScanScreenStyles.headerColor,
      child: Padding(
        padding: ScanScreenStyles.headerPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: ScanScreenStyles.headerSideWidth,
              height: ScanScreenStyles.headerIconButtonSize,
              child: IconButton(
                tooltip: ScanScreenStyles.backTooltip,
                onPressed: _isProcessing ? null : widget.onBack,
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  size: ScanScreenStyles.headerIconSize,
                  color: ScanScreenStyles.primaryTextColor,
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    ScanScreenStyles.screenTitle,
                    textAlign: TextAlign.center,
                    style: ScanScreenStyles.headerTitleStyle,
                  ),
                  const SizedBox(
                    height: ScanScreenStyles.titleDescriptionSpacing,
                  ),
                  const Text(
                    ScanScreenStyles.screenDescription,
                    textAlign: TextAlign.center,
                    style: ScanScreenStyles.headerDescriptionStyle,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: ScanScreenStyles.headerSideWidth,
              height: ScanScreenStyles.headerIconButtonSize,
              child: IconButton(
                tooltip: ScanScreenStyles.helpTooltip,
                onPressed: _isProcessing ? null : _showScanningHelp,
                icon: const Icon(
                  Icons.help_outline_rounded,
                  size: ScanScreenStyles.helpIconSize,
                  color: ScanScreenStyles.primaryTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraArea() {
    final String statusLabel = _hasSelectedImage
        ? ScanScreenStyles.imageReadyLabel
        : ScanScreenStyles.cameraReadyLabel;

    final String instructionLabel = _hasSelectedImage
        ? ScanScreenStyles.imageInstruction
        : ScanScreenStyles.cameraInstruction;

    return ColoredBox(
      color: ScanScreenStyles.cameraBackgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (_selectedImage == null)
            ScanCameraPreview(cameraService: _cameraService)
          else
            ScanPreview(
              selectedImage: _selectedImage!,
              onRegionSelected: _onRegionSelected,
              onSelectionCleared: _clearSelectedRegion,
            ),

          if (!_hasSelectedImage)
            const IgnorePointer(
              child: CustomPaint(painter: _ScanFramePainter()),
            ),
          Positioned(
            top: ScanScreenStyles.cameraOverlayTopSpacing,
            left: ScanScreenStyles.frameHorizontalInset,
            right: ScanScreenStyles.frameHorizontalInset,
            child: Center(
              child: _CameraMessagePill(
                icon: _hasSelectedImage
                    ? Icons.check_circle_rounded
                    : Icons.document_scanner_outlined,
                label: statusLabel,
                isStatus: true,
              ),
            ),
          ),
          Positioned(
            bottom: ScanScreenStyles.cameraOverlayBottomSpacing,
            left: ScanScreenStyles.frameHorizontalInset,
            right: ScanScreenStyles.frameHorizontalInset,
            child: Center(
              child: _CameraMessagePill(
                icon: _hasSelectedImage
                    ? Icons.image_search_outlined
                    : Icons.stay_current_portrait_rounded,
                label: instructionLabel,
              ),
            ),
          ),
          if (_isProcessing) const _ProcessingOverlay(),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      height: ScanScreenStyles.controlsHeight,
      color: ScanScreenStyles.controlPanelColor,
      padding: ScanScreenStyles.controlsPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _CameraControlButton(
            label: ScanScreenStyles.uploadLabel,
            icon: Icons.image_outlined,
            onPressed: _isProcessing ? null : _pickFile,
          ),
          _CaptureButton(
            semanticLabel: _hasSelectedImage
                ? ScanScreenStyles.scanSemanticLabel
                : ScanScreenStyles.captureSemanticLabel,
            icon: _hasSelectedImage
                ? Icons.document_scanner_rounded
                : Icons.camera_alt_rounded,
            isProcessing: _isProcessing,
            onPressed: _isProcessing
                ? null
                : _hasSelectedImage
                ? _scanImage
                : _captureImage,
          ),
          _CameraControlButton(
            label: _hasSelectedImage
                ? ScanScreenStyles.retakeLabel
                : ScanScreenStyles.flashLabel,
            icon: _hasSelectedImage
                ? Icons.refresh_rounded
                : _flashEnabled
                ? Icons.flash_on_rounded
                : Icons.flash_off_rounded,
            isActive: !_hasSelectedImage && _flashEnabled,
            onPressed: _isProcessing
                ? null
                : _hasSelectedImage
                ? _retakeImage
                : _toggleFlash,
          ),
        ],
      ),
    );
  }
}

class _ScanConfirmationDetail extends StatelessWidget {
  const _ScanConfirmationDetail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          icon,
          size: ScanScreenStyles.confirmationDetailIconSize,
          color: ScanScreenStyles.primaryColor,
        ),
        const SizedBox(width: ScanScreenStyles.confirmationDetailIconSpacing),
        Expanded(
          child: Text(text, style: ScanScreenStyles.confirmationDetailStyle),
        ),
      ],
    );
  }
}

class _CameraMessagePill extends StatelessWidget {
  const _CameraMessagePill({
    required this.icon,
    required this.label,
    this.isStatus = false,
  });

  final IconData icon;
  final String label;
  final bool isStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ScanScreenStyles.overlayHorizontalPadding,
        vertical: ScanScreenStyles.overlayVerticalPadding,
      ),
      decoration: const BoxDecoration(
        color: ScanScreenStyles.translucentSurfaceColor,
        borderRadius: ScanScreenStyles.overlayRadius,
        boxShadow: ScanScreenStyles.overlayShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: isStatus
                ? ScanScreenStyles.statusIconSize
                : ScanScreenStyles.instructionIconSize,
            color: isStatus
                ? ScanScreenStyles.primaryColor
                : ScanScreenStyles.primaryTextColor,
          ),
          const SizedBox(width: ScanScreenStyles.overlaySpacing),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: isStatus
                  ? ScanScreenStyles.statusTextStyle
                  : ScanScreenStyles.instructionTextStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraControlButton extends StatelessWidget {
  const _CameraControlButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isActive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isActive
        ? ScanScreenStyles.activeControlBorderColor
        : ScanScreenStyles.controlBorderColor;

    final Color iconColor = isActive
        ? ScanScreenStyles.primaryColor
        : ScanScreenStyles.primarySoftColor;

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(
          ScanScreenStyles.sideControlSize / 2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: ScanScreenStyles.sideControlSize,
              height: ScanScreenStyles.sideControlSize,
              decoration: BoxDecoration(
                color: ScanScreenStyles.controlBackgroundColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor,
                  width: ScanScreenStyles.sideControlBorderWidth,
                ),
              ),
              child: Icon(
                icon,
                size: ScanScreenStyles.sideControlIconSize,
                color: onPressed == null
                    ? ScanScreenStyles.mutedTextColor
                    : iconColor,
              ),
            ),
            const SizedBox(height: ScanScreenStyles.controlLabelSpacing),
            Text(
              label,
              style: ScanScreenStyles.controlLabelStyle.copyWith(
                color: onPressed == null
                    ? ScanScreenStyles.mutedTextColor
                    : ScanScreenStyles.primaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({
    required this.semanticLabel,
    required this.icon,
    required this.isProcessing,
    required this.onPressed,
  });

  final String semanticLabel;
  final IconData icon;
  final bool isProcessing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onPressed != null,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: ScanScreenStyles.captureOuterSize,
          height: ScanScreenStyles.captureOuterSize,
          decoration: BoxDecoration(
            color: ScanScreenStyles.surfaceColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: ScanScreenStyles.primaryColor,
              width: ScanScreenStyles.captureOuterBorderWidth,
            ),
            boxShadow: ScanScreenStyles.captureShadow,
          ),
          alignment: Alignment.center,
          child: Container(
            width: ScanScreenStyles.captureMiddleSize,
            height: ScanScreenStyles.captureMiddleSize,
            decoration: BoxDecoration(
              color: ScanScreenStyles.surfaceColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: ScanScreenStyles.primarySoftColor,
                width: ScanScreenStyles.captureInnerBorderWidth,
              ),
            ),
            alignment: Alignment.center,
            child: SizedBox(
              width: ScanScreenStyles.captureInnerSize,
              height: ScanScreenStyles.captureInnerSize,
              child: Center(
                child: isProcessing
                    ? const CircularProgressIndicator(
                        strokeWidth: ScanScreenStyles.processingIndicatorWidth,
                        color: ScanScreenStyles.primaryColor,
                      )
                    : Icon(
                        icon,
                        size: ScanScreenStyles.captureIconSize,
                        color: ScanScreenStyles.primaryColor,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: ScanScreenStyles.processingOverlayColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox.square(
              dimension: ScanScreenStyles.processingIndicatorSize,
              child: CircularProgressIndicator(
                strokeWidth: ScanScreenStyles.processingIndicatorWidth,
                color: ScanScreenStyles.primaryColor,
              ),
            ),
            SizedBox(height: ScanScreenStyles.processingLabelSpacing),
            Text(
              ScanScreenStyles.processingLabel,
              style: ScanScreenStyles.processingTextStyle,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanningTip extends StatelessWidget {
  const _ScanningTip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          icon,
          size: ScanScreenStyles.helpTipIconSize,
          color: ScanScreenStyles.primaryColor,
        ),
        const SizedBox(width: ScanScreenStyles.helpTipIconSpacing),
        Expanded(child: Text(text, style: ScanScreenStyles.helpTipStyle)),
      ],
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  const _ScanFramePainter();

  Rect _createFrame(Size size) {
    final double maximumVerticalInset =
        (size.height - ScanScreenStyles.frameCornerLength * 2) / 2;

    final double verticalInset = ScanScreenStyles.frameVerticalInset.clamp(
      0.0,
      maximumVerticalInset < 0 ? 0.0 : maximumVerticalInset,
    );

    return Rect.fromLTRB(
      ScanScreenStyles.frameHorizontalInset,
      verticalInset,
      size.width - ScanScreenStyles.frameHorizontalInset,
      size.height - verticalInset,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Rect frame = _createFrame(size);

    final Path overlayPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(
        RRect.fromRectAndRadius(
          frame,
          const Radius.circular(ScanScreenStyles.frameCornerRadius),
        ),
      );

    final Paint overlayPaint = Paint()
      ..color = ScanScreenStyles.outsideFrameOverlayColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(overlayPath, overlayPaint);

    final Paint cornerPaint = Paint()
      ..color = ScanScreenStyles.primaryColor
      ..strokeWidth = ScanScreenStyles.frameCornerWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final double length = ScanScreenStyles.frameCornerLength;

    final Path cornerPath = Path()
      ..moveTo(frame.left, frame.top + length)
      ..lineTo(frame.left, frame.top)
      ..lineTo(frame.left + length, frame.top)
      ..moveTo(frame.right - length, frame.top)
      ..lineTo(frame.right, frame.top)
      ..lineTo(frame.right, frame.top + length)
      ..moveTo(frame.left, frame.bottom - length)
      ..lineTo(frame.left, frame.bottom)
      ..lineTo(frame.left + length, frame.bottom)
      ..moveTo(frame.right - length, frame.bottom)
      ..lineTo(frame.right, frame.bottom)
      ..lineTo(frame.right, frame.bottom - length);

    canvas.drawPath(cornerPath, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _ScanFramePainter oldDelegate) {
    return false;
  }
}
