import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/materials/material_model.dart';
import '../../services/materials/material_service.dart';
import '../../styles/screens/materials/material_detail_screen_styles.dart';
import '../../widgets/app_header.dart';

class MaterialDetailScreen extends StatefulWidget {
  const MaterialDetailScreen({super.key, required this.material});

  final MaterialModel material;

  @override
  State<MaterialDetailScreen> createState() => _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends State<MaterialDetailScreen> {
  final MaterialService _materialService = MaterialService();

  MaterialModel get _material => widget.material;

  bool get _isScannedMaterial {
    return _material.recognizedContent.trim().isNotEmpty ||
        _material.brailleContent.trim().isNotEmpty;
  }

  bool get _isImage {
    final String type = _material.fileType.toLowerCase();

    return type.contains('image') ||
        type.contains('jpg') ||
        type.contains('jpeg') ||
        type.contains('png') ||
        type.contains('webp') ||
        type.contains('bmp') ||
        type.contains('tiff');
  }

  bool get _isRemoteFile {
    final String path = _material.filePath.trim().replaceAll('\\', '/');

    return path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.contains('/uploads/') ||
        path.startsWith('uploads/');
  }

  @override
  void dispose() {
    _materialService.dispose();
    super.dispose();
  }

  String _formatDate(BuildContext context, DateTime date) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(
      context,
    );

    final String formattedDate = localizations.formatMediumDate(date);

    final String formattedTime = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(date),
    );

    return '$formattedDate • $formattedTime';
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) {
      return '0 B';
    }

    if (bytes < 1024) {
      return '$bytes B';
    }

    final double kilobytes = bytes / 1024;

    if (kilobytes < 1024) {
      return '${kilobytes.toStringAsFixed(1)} KB';
    }

    final double megabytes = kilobytes / 1024;

    return '${megabytes.toStringAsFixed(1)} MB';
  }

  Future<void> _copyToClipboard({
    required String content,
    required String confirmationMessage,
  }) async {
    if (content.trim().isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: content));

    if (!mounted) {
      return;
    }

    _showMessage(confirmationMessage);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: MaterialDetailScreenStyles.snackBarDuration,
          behavior: MaterialDetailScreenStyles.snackBarBehavior,
          backgroundColor: MaterialDetailScreenStyles.primaryColor,
          margin: MaterialDetailScreenStyles.snackBarMargin,
          shape: const RoundedRectangleBorder(
            borderRadius: MaterialDetailScreenStyles.snackBarRadius,
          ),
          content: Text(
            message,
            style: MaterialDetailScreenStyles.snackBarTextStyle,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaterialDetailScreenStyles.backgroundColor,
      appBar: PreferredSize(
        preferredSize: MaterialDetailScreenStyles.headerSize,
        child: Stack(
          children: <Widget>[
            const AppHeader(),
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: MaterialDetailScreenStyles.headerPadding,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          tooltip: MaterialDetailScreenStyles.backTooltip,
                          onPressed: () {
                            Navigator.maybePop(context);
                          },
                          icon: const Icon(
                            MaterialDetailScreenStyles.backIcon,
                            size: MaterialDetailScreenStyles.headerIconSize,
                            color: MaterialDetailScreenStyles.primaryColor,
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          MaterialDetailScreenStyles.screenTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: MaterialDetailScreenStyles.headerTitleStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: MaterialDetailScreenStyles.screenPadding,
          children: <Widget>[
            _buildMaterialInformation(),
            const SizedBox(height: MaterialDetailScreenStyles.sectionSpacing),
            _buildFilePreview(),
            if (_isScannedMaterial) ...<Widget>[
              const SizedBox(height: MaterialDetailScreenStyles.sectionSpacing),
              _buildRecognizedContent(),
              const SizedBox(height: MaterialDetailScreenStyles.sectionSpacing),
              _buildBrailleContent(),
            ] else ...<Widget>[
              const SizedBox(height: MaterialDetailScreenStyles.sectionSpacing),
              _buildFileInformation(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialInformation() {
    final String description = _material.description.trim().isEmpty
        ? MaterialDetailScreenStyles.noDescriptionLabel
        : _material.description.trim();

    final String subject = _material.subject.trim().isEmpty
        ? MaterialDetailScreenStyles.noSubjectLabel
        : _material.subject.trim();

    return Container(
      padding: MaterialDetailScreenStyles.cardPadding,
      decoration: const BoxDecoration(
        color: MaterialDetailScreenStyles.surfaceColor,
        borderRadius: MaterialDetailScreenStyles.cardRadius,
        border: MaterialDetailScreenStyles.cardBorder,
        boxShadow: MaterialDetailScreenStyles.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: MaterialDetailScreenStyles.badgePadding,
            decoration: BoxDecoration(
              color: _isScannedMaterial
                  ? MaterialDetailScreenStyles.scannedBadgeColor
                  : MaterialDetailScreenStyles.uploadedBadgeColor,
              borderRadius: MaterialDetailScreenStyles.badgeRadius,
            ),
            child: Text(
              _isScannedMaterial
                  ? MaterialDetailScreenStyles.scannedBadgeLabel
                  : MaterialDetailScreenStyles.uploadedBadgeLabel,
              style: _isScannedMaterial
                  ? MaterialDetailScreenStyles.scannedBadgeTextStyle
                  : MaterialDetailScreenStyles.uploadedBadgeTextStyle,
            ),
          ),
          const SizedBox(height: MaterialDetailScreenStyles.itemSpacing),
          Text(
            _material.title,
            style: MaterialDetailScreenStyles.materialTitleStyle,
          ),
          const SizedBox(height: MaterialDetailScreenStyles.compactSpacing),
          Text(subject, style: MaterialDetailScreenStyles.subjectStyle),
          const SizedBox(height: MaterialDetailScreenStyles.itemSpacing),
          Text(description, style: MaterialDetailScreenStyles.descriptionStyle),
          const SizedBox(height: MaterialDetailScreenStyles.itemSpacing),
          Row(
            children: <Widget>[
              const Icon(
                MaterialDetailScreenStyles.calendarIcon,
                size: MaterialDetailScreenStyles.metadataIconSize,
                color: MaterialDetailScreenStyles.textMutedColor,
              ),
              const SizedBox(width: MaterialDetailScreenStyles.metadataSpacing),
              Expanded(
                child: Text(
                  _formatDate(context, _material.uploadDate),
                  style: MaterialDetailScreenStyles.metadataTextStyle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview() {
    return Container(
      padding: MaterialDetailScreenStyles.cardPadding,
      decoration: const BoxDecoration(
        color: MaterialDetailScreenStyles.surfaceColor,
        borderRadius: MaterialDetailScreenStyles.cardRadius,
        border: MaterialDetailScreenStyles.cardBorder,
        boxShadow: MaterialDetailScreenStyles.cardShadow,
      ),
      child: _isImage ? _buildImagePreview() : _buildUnsupportedFilePreview(),
    );
  }

  Widget _buildImagePreview() {
    final Widget image = _isRemoteFile
        ? Image.network(
            _materialService.getFileUrl(_material.filePath),
            fit: MaterialDetailScreenStyles.imagePreviewFit,
            errorBuilder: _buildImageError,
          )
        : Image.file(
            File(_material.filePath),
            fit: MaterialDetailScreenStyles.imagePreviewFit,
            errorBuilder: _buildImageError,
          );

    return Semantics(
      image: true,
      label: MaterialDetailScreenStyles.imageSemanticLabel,
      child: Container(
        width: double.infinity,
        height: MaterialDetailScreenStyles.imagePreviewHeight,
        decoration: const BoxDecoration(
          color: MaterialDetailScreenStyles.imageBackgroundColor,
          borderRadius: MaterialDetailScreenStyles.imagePreviewRadius,
        ),
        clipBehavior: Clip.antiAlias,
        child: image,
      ),
    );
  }

  Widget _buildImageError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return const _MaterialEmptyState(
      icon: MaterialDetailScreenStyles.imageErrorIcon,
      iconSize: MaterialDetailScreenStyles.imageErrorIconSize,
      title: MaterialDetailScreenStyles.imageErrorTitle,
      description: MaterialDetailScreenStyles.imageErrorDescription,
    );
  }

  Widget _buildUnsupportedFilePreview() {
    return SizedBox(
      height: MaterialDetailScreenStyles.filePreviewHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(
            MaterialDetailScreenStyles.fileIcon,
            size: MaterialDetailScreenStyles.filePreviewIconSize,
            color: MaterialDetailScreenStyles.primaryColor,
          ),
          const SizedBox(height: MaterialDetailScreenStyles.itemSpacing),
          Text(
            _material.fileName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: MaterialDetailScreenStyles.fileNameStyle,
          ),
          const SizedBox(height: MaterialDetailScreenStyles.compactSpacing),
          const Text(
            MaterialDetailScreenStyles.filePreviewDescription,
            textAlign: TextAlign.center,
            style: MaterialDetailScreenStyles.emptyDescriptionStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildRecognizedContent() {
    final String content = _material.recognizedContent.trim();

    return _MaterialSection(
      title: MaterialDetailScreenStyles.recognizedSectionTitle,
      action: content.isEmpty
          ? null
          : _MaterialSectionAction(
              label: MaterialDetailScreenStyles.copyLabel,
              tooltip: MaterialDetailScreenStyles.copyContentTooltip,
              onPressed: () {
                _copyToClipboard(
                  content: content,
                  confirmationMessage:
                      MaterialDetailScreenStyles.contentCopiedMessage,
                );
              },
            ),
      child: content.isEmpty
          ? const _MaterialEmptyState(
              icon: MaterialDetailScreenStyles.emptyContentIcon,
              title: MaterialDetailScreenStyles.emptyContentTitle,
              description: MaterialDetailScreenStyles.emptyContentDescription,
            )
          : Semantics(
              label: MaterialDetailScreenStyles.recognizedContentSemanticLabel,
              child: SelectableText(
                content,
                style: MaterialDetailScreenStyles.recognizedContentStyle,
              ),
            ),
    );
  }

  Widget _buildBrailleContent() {
    final String content = _material.brailleContent.trim();

    return _MaterialSection(
      title: MaterialDetailScreenStyles.brailleSectionTitle,
      action: content.isEmpty
          ? null
          : _MaterialSectionAction(
              label: MaterialDetailScreenStyles.copyBrailleLabel,
              tooltip: MaterialDetailScreenStyles.copyBrailleTooltip,
              onPressed: () {
                _copyToClipboard(
                  content: content,
                  confirmationMessage:
                      MaterialDetailScreenStyles.brailleCopiedMessage,
                );
              },
            ),
      child: content.isEmpty
          ? const _MaterialEmptyState(
              icon: MaterialDetailScreenStyles.emptyContentIcon,
              title: MaterialDetailScreenStyles.emptyBrailleTitle,
              description: MaterialDetailScreenStyles.emptyBrailleDescription,
            )
          : Semantics(
              label: MaterialDetailScreenStyles.brailleSemanticLabel,
              child: SelectableText(
                content,
                style: MaterialDetailScreenStyles.brailleContentStyle,
              ),
            ),
    );
  }

  Widget _buildFileInformation() {
    return _MaterialSection(
      title: MaterialDetailScreenStyles.fileInformationTitle,
      child: Column(
        children: <Widget>[
          _InformationRow(
            label: MaterialDetailScreenStyles.fileNameLabel,
            value: _material.fileName,
          ),
          const SizedBox(height: MaterialDetailScreenStyles.itemSpacing),
          _InformationRow(
            label: MaterialDetailScreenStyles.fileTypeLabel,
            value: _material.fileType,
          ),
          const SizedBox(height: MaterialDetailScreenStyles.itemSpacing),
          _InformationRow(
            label: MaterialDetailScreenStyles.fileSizeLabel,
            value: _formatFileSize(_material.fileSize),
          ),
          const SizedBox(height: MaterialDetailScreenStyles.itemSpacing),
          _InformationRow(
            label: MaterialDetailScreenStyles.uploadDateLabel,
            value: _formatDate(context, _material.uploadDate),
          ),
        ],
      ),
    );
  }
}

class _MaterialSection extends StatelessWidget {
  const _MaterialSection({
    required this.title,
    required this.child,
    this.action,
  });

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: MaterialDetailScreenStyles.cardPadding,
      decoration: const BoxDecoration(
        color: MaterialDetailScreenStyles.surfaceColor,
        borderRadius: MaterialDetailScreenStyles.cardRadius,
        border: MaterialDetailScreenStyles.cardBorder,
        boxShadow: MaterialDetailScreenStyles.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: MaterialDetailScreenStyles.sectionTitleStyle,
                ),
              ),
              if (action case final Widget action) action,
            ],
          ),
          const SizedBox(height: MaterialDetailScreenStyles.itemSpacing),
          Container(
            width: double.infinity,
            padding: MaterialDetailScreenStyles.contentPadding,
            decoration: const BoxDecoration(
              color: MaterialDetailScreenStyles.softBackgroundColor,
              borderRadius: MaterialDetailScreenStyles.innerRadius,
              border: MaterialDetailScreenStyles.innerBorder,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _MaterialSectionAction extends StatelessWidget {
  const _MaterialSectionAction({
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  final String label;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(
          MaterialDetailScreenStyles.copyIcon,
          size: MaterialDetailScreenStyles.actionIconSize,
        ),
        label: Text(label),
        style: MaterialDetailScreenStyles.sectionActionStyle,
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: MaterialDetailScreenStyles.informationLabelStyle,
          ),
        ),
        const SizedBox(width: MaterialDetailScreenStyles.itemSpacing),
        Expanded(
          flex: 3,
          child: Text(
            value.trim().isEmpty ? '—' : value,
            textAlign: TextAlign.right,
            style: MaterialDetailScreenStyles.informationValueStyle,
          ),
        ),
      ],
    );
  }
}

class _MaterialEmptyState extends StatelessWidget {
  const _MaterialEmptyState({
    required this.icon,
    required this.title,
    required this.description,
    this.iconSize = MaterialDetailScreenStyles.emptyContentIconSize,
  });

  final IconData icon;
  final double iconSize;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MaterialDetailScreenStyles.emptyStatePadding,
      child: Column(
        children: <Widget>[
          Icon(
            icon,
            size: iconSize,
            color: MaterialDetailScreenStyles.primaryColor,
          ),
          const SizedBox(height: MaterialDetailScreenStyles.itemSpacing),
          Text(
            title,
            textAlign: TextAlign.center,
            style: MaterialDetailScreenStyles.emptyTitleStyle,
          ),
          const SizedBox(height: MaterialDetailScreenStyles.compactSpacing),
          Text(
            description,
            textAlign: TextAlign.center,
            style: MaterialDetailScreenStyles.emptyDescriptionStyle,
          ),
        ],
      ),
    );
  }
}
