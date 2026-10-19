import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/ai/scan_document_result.dart';
import '../../models/braille/braille_mode.dart';
import '../../services/braille/braille_mode_translator.dart';
import '../../styles/widgets/braille/braille_mode_selector_styles.dart';
import '../../widgets/braille/braille_mode_section.dart';
import '../../widgets/document/document_layout_view.dart';
import '../../models/materials/material_model.dart';
import '../../services/materials/material_service.dart';
import '../../styles/screens/materials/material_preview_screen_styles.dart';

import '../../utils/session_manager.dart';
import '../../widgets/materials/material_file_image.dart';

class MaterialDetailScreen extends StatefulWidget {
  const MaterialDetailScreen({super.key, required this.material});

  final MaterialModel material;

  @override
  State<MaterialDetailScreen> createState() => _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends State<MaterialDetailScreen> {
  final MaterialService _materialService = MaterialService();

  MaterialModel get _material => widget.material;

  List<DocumentPage> get _documentPages {
    return List<DocumentPage>.generate(_material.documentPages.length, (
      int index,
    ) {
      return DocumentPage.fromJson(
        Map<String, dynamic>.from(_material.documentPages[index]),
        fallbackPageIndex: index,
      );
    }, growable: false);
  }

  /// Pages kept once, so switching Braille modes reuses the same record.
  late final List<DocumentPage> _modePages = _documentPages;

  late final BrailleMode _savedBrailleMode = savedBrailleModeOf(_modePages);

  /// A material saved in Braille 1 on a device that cannot recreate
  /// Braille 1 (iOS) shows its saved Braille as saved, without pairing.
  late final bool _showsSavedBraille1AsSaved =
      _savedBrailleMode == BrailleMode.uncontracted &&
      BrailleModeTranslator.instance.availabilityOf(_modePages) !=
          BrailleModeAvailability.available;

  bool get _isScannedMaterial {
    return _material.recognizedContent.trim().isNotEmpty ||
        _material.brailleContent.trim().isNotEmpty ||
        _material.documentPages.isNotEmpty ||
        _material.documentBlocks.isNotEmpty;
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

  bool? _isGuestSession;

  @override
  void initState() {
    super.initState();
    _loadSessionType();
  }

  Future<void> _loadSessionType() async {
    final bool isGuest = await SessionManager.isGuest();

    if (!mounted) {
      return;
    }

    setState(() {
      _isGuestSession = isGuest;
    });
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: MaterialDetailScreenStyles.backgroundColor,
        body: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: MaterialDetailScreenStyles.entranceDuration,
          curve: MaterialDetailScreenStyles.entranceCurve,
          builder:
              (BuildContext context, double animationValue, Widget? child) {
                return Opacity(
                  opacity: animationValue,
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      MaterialDetailScreenStyles.entranceOffsetY *
                          (1 - animationValue),
                    ),
                    child: child,
                  ),
                );
              },
          child: Column(
            children: <Widget>[
              _buildPageHeader(),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: ListView(
                    physics: const ClampingScrollPhysics(),
                    padding: MaterialDetailScreenStyles.screenPadding,
                    children: <Widget>[
                      _buildMaterialInformation(),
                      const SizedBox(
                        height: MaterialDetailScreenStyles.sectionSpacing,
                      ),
                      _buildFilePreview(),
                      if (_isScannedMaterial) ...<Widget>[
                        const SizedBox(
                          height: MaterialDetailScreenStyles.sectionSpacing,
                        ),
                        if (TextBrailleLayoutView.canDisplay(_documentPages) &&
                            !_showsSavedBraille1AsSaved)
                          _buildTextAndBrailleContent()
                        else ...<Widget>[
                          _buildRecognizedContent(),
                          const SizedBox(
                            height: MaterialDetailScreenStyles.sectionSpacing,
                          ),
                          _buildBrailleContent(),
                        ],
                      ] else ...<Widget>[
                        const SizedBox(
                          height: MaterialDetailScreenStyles.sectionSpacing,
                        ),
                        _buildFileInformation(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: MaterialDetailScreenStyles.headerHeight,
      ),
      padding: MaterialDetailScreenStyles.headerPadding,
      decoration: const BoxDecoration(
        gradient: MaterialDetailScreenStyles.headerGradient,
        borderRadius: MaterialDetailScreenStyles.headerRadius,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            IconButton(
              tooltip: MaterialDetailScreenStyles.backTooltip,
              onPressed: () {
                Navigator.maybePop(context);
              },
              style: MaterialDetailScreenStyles.headerBackButtonStyle,
              icon: const Icon(
                MaterialDetailScreenStyles.backIcon,
                size: MaterialDetailScreenStyles.headerIconSize,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    MaterialDetailScreenStyles.screenTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MaterialDetailScreenStyles.headerTitleStyle,
                  ),
                  SizedBox(height: 5),
                  Text(
                    MaterialDetailScreenStyles.screenSubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: MaterialDetailScreenStyles.headerSubtitleStyle,
                  ),
                ],
              ),
            ),
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
    final Widget image = _buildImageContent();
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

  Widget _buildImageContent() {
    if (_isGuestSession == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // The preview is never wider than the screen and cannot be zoomed.
    final int cacheWidth =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round();

    if (_isGuestSession == false && _material.id != null) {
      return MaterialFileImage(
        materialId: _material.id!,
        cacheWidth: cacheWidth,
        fit: MaterialDetailScreenStyles.imagePreviewFit,
        errorBuilder: _buildImageError,
      );
    }

    return Image.file(
      File(_material.filePath),
      cacheWidth: cacheWidth,
      fit: MaterialDetailScreenStyles.imagePreviewFit,
      errorBuilder: _buildImageError,
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
    final List<DocumentPage> pages = _documentPages;

    final bool hasRecognizedLayout =
        content.isNotEmpty ||
        pages.any(
          (DocumentPage page) =>
              page.blocks.any((DocumentBlock block) => block.hasContent),
        );

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
      child: hasRecognizedLayout
          ? DocumentLayoutView(
              pages: pages,
              useBraille: false,
              fallbackText: content,
              fallbackBraille: _material.brailleContent,
              semanticLabel:
                  MaterialDetailScreenStyles.recognizedContentSemanticLabel,
            )
          : const _MaterialEmptyState(
              icon: MaterialDetailScreenStyles.emptyContentIcon,
              title: MaterialDetailScreenStyles.emptyContentTitle,
              description: MaterialDetailScreenStyles.emptyContentDescription,
            ),
    );
  }

  /// Text with its Braille beneath each word, in one section, opened in the
  /// mode the material was saved in.
  Widget _buildTextAndBrailleContent() {
    final String content = _material.recognizedContent.trim();
    final String savedBraille = _material.brailleContent.trim();

    return BrailleModeSection(
      pages: _modePages,
      initialMode: _savedBrailleMode,
      builder: (BuildContext context, BrailleModeView? view, Widget selector) {
        // In the saved mode, copy exactly what was saved.
        final String braille = view == null
            ? ''
            : view.mode == _savedBrailleMode && savedBraille.isNotEmpty
            ? savedBraille
            : view.combinedBraille;

        return _MaterialSection(
          title: MaterialDetailScreenStyles.textAndBrailleSectionTitle,
          actions: <Widget>[
            if (content.isNotEmpty)
              _MaterialSectionAction(
                label: MaterialDetailScreenStyles.copyTextLabel,
                tooltip: MaterialDetailScreenStyles.copyContentTooltip,
                onPressed: () {
                  _copyToClipboard(
                    content: content,
                    confirmationMessage:
                        MaterialDetailScreenStyles.contentCopiedMessage,
                  );
                },
              ),
            if (braille.isNotEmpty)
              _MaterialSectionAction(
                label: MaterialDetailScreenStyles.copyBrailleLabel,
                tooltip: MaterialDetailScreenStyles.copyBrailleTooltip,
                onPressed: () {
                  _copyToClipboard(
                    content: braille,
                    confirmationMessage:
                        MaterialDetailScreenStyles.brailleCopiedMessage,
                  );
                },
              ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              selector,
              const SizedBox(height: MaterialDetailScreenStyles.compactSpacing),
              if (view == null)
                const BrailleModeLoadingPlaceholder()
              else
                TextBrailleLayoutView(
                  pages: view.pages,
                  semanticLabel:
                      MaterialDetailScreenStyles.textAndBrailleSemanticLabel,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrailleContent() {
    final String content = _material.brailleContent.trim();
    final List<DocumentPage> pages = _documentPages;

    final bool hasBrailleLayout =
        content.isNotEmpty ||
        pages.any(
          (DocumentPage page) =>
              page.blocks.any((DocumentBlock block) => block.hasBraille),
        );

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
      child: hasBrailleLayout
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Saved in Braille 1 on a device that cannot recreate it:
                // show the saved Braille as saved.
                if (_savedBrailleMode == BrailleMode.uncontracted) ...<Widget>[
                  const Text(
                    BrailleModeSelectorStyles.savedUncontractedNote,
                    style: BrailleModeSelectorStyles.noteStyle,
                  ),
                  const SizedBox(
                    height: MaterialDetailScreenStyles.compactSpacing,
                  ),
                ],
                DocumentLayoutView(
                  pages: pages,
                  useBraille: true,
                  fallbackText: _material.recognizedContent,
                  fallbackBraille: content,
                  semanticLabel:
                      MaterialDetailScreenStyles.brailleSemanticLabel,
                ),
              ],
            )
          : const _MaterialEmptyState(
              icon: MaterialDetailScreenStyles.emptyContentIcon,
              title: MaterialDetailScreenStyles.emptyBrailleTitle,
              description: MaterialDetailScreenStyles.emptyBrailleDescription,
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
    this.actions = const <Widget>[],
  });

  final String title;
  final Widget child;
  final Widget? action;

  /// Several actions, shown in a wrapping row under the title so they
  /// still fit at large system font sizes.
  final List<Widget> actions;

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
          if (actions.isNotEmpty) ...<Widget>[
            const SizedBox(height: MaterialDetailScreenStyles.compactSpacing),
            Wrap(
              spacing: MaterialDetailScreenStyles.compactSpacing,
              runSpacing: MaterialDetailScreenStyles.compactSpacing,
              children: actions,
            ),
          ],
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
