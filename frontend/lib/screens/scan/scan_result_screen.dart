import 'dart:io';

import 'package:image/image.dart' as img;

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter/services.dart';

import '../../models/ai/scan_document_result.dart';
import '../../models/materials/material_model.dart';
import '../../services/materials/material_service.dart';
import '../../styles/screens/scan/scan_result_screen_styles.dart';

abstract final class _ScanResultText {
  static const String appBarTitle = 'Scan Result';

  static const String backTooltip = 'Go back';

  static const String newScanLabel = 'New Scan';

  static const String successTitle = 'Scan Successful!';

  static const String successDescription =
      'Your scanned content is ready for review.';

  static const String imageSectionNumber = '1';

  static const String imageSectionTitle = 'Scanned Image';

  static const String contentSectionNumber = '2';

  static const String contentSectionTitle = 'Scanned Content (Preview)';

  static const String brailleSectionNumber = '3';

  static const String brailleSectionTitle = 'Braille Output (Translation)';

  static const String copyLabel = 'Copy';

  static const String copyBrailleLabel = 'Copy Braille';

  static const String copyTooltip = 'Copy recognized content';

  static const String copyBrailleTooltip = 'Copy Braille translation';

  static const String imageErrorText = 'Unable to display the scanned image.';

  static const String contentBlockSeparator = '\n\n';

  static const String brailleUnavailableTitle = 'Braille output unavailable';

  static const String brailleUnavailableDescription =
      'No Braille translation was returned for this scan.';

  static const String brailleTranslationFailedDescription =
      'The recognized content could not be translated into Braille. Please try scanning again.';

  static const String emptyResultTitle = 'No content recognized';

  static const String emptyResultDescription =
      'Try scanning again with clearer lighting and a sharper image.';

  static const String saveMaterialLabel = 'Save to Materials';

  static const String savingMaterialLabel = 'Saving...';

  static const String savedMaterialLabel = 'Saved to Materials';

  static const String saveMaterialTooltip = 'Save this scan to your materials';

  static const String saveDialogTitle = 'Save as Material';

  static const String saveDialogDescription =
      'Enter the material details so you can easily find it later.';

  static const String saveTitleLabel = 'Title';

  static const String saveTitleHint = 'Example: Algebra Worksheet';

  static const String saveSubjectLabel = 'Subject';

  static const String saveSubjectHint = 'Example: General Algebra';

  static const String saveDescriptionLabel = 'Description (Optional)';

  static const String saveDescriptionHint =
      'Add a short description of this material.';

  static const String defaultMaterialTitle = 'Untitled Scan';

  static const String defaultMaterialSubject = 'Scanned Document';

  static const String cancelLabel = 'Cancel';

  static const String confirmSaveLabel = 'Save';

  static const String emptyMaterialTitleError = 'Please enter a title.';

  static const String emptyMaterialSubjectError = 'Please enter a subject.';

  static const String materialSavedMessage = 'Scan saved to your materials.';

  static const String materialSaveFailedMessage =
      'Unable to save this scan to materials.';

  static const String contentCopiedMessage = 'Recognized content copied.';

  static const String brailleCopiedMessage = 'Braille translation copied.';

  static const String imageSemanticLabel = 'Image processed by PaddleOCR-VL';

  static const String resultSemanticLabel = 'Recognized document content';

  static const String brailleSemanticLabel = 'Braille translation output';
}

class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({
    super.key,
    required this.result,
    required this.scannedImage,
  });

  final ScanDocumentResult result;
  final File scannedImage;

  String get _combinedContent {
    return result.blocks
        .map((DocumentBlock block) => block.normalizedContent.trim())
        .where((String content) => content.isNotEmpty)
        .join(_ScanResultText.contentBlockSeparator);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScanResultScreenStyles.backgroundColor,
      appBar: PreferredSize(
        preferredSize: ScanResultScreenStyles.headerSize,
        child: Material(
          color: ScanResultScreenStyles.surfaceColor,
          elevation: 1,
          shadowColor: Colors.black12,
          child: SafeArea(
            child: SizedBox(
              height: ScanResultScreenStyles.headerContentHeight,
              child: Row(
                children: <Widget>[
                  IconButton(
                    tooltip: _ScanResultText.backTooltip,
                    onPressed: () {
                      Navigator.maybePop(context);
                    },
                    icon: const Icon(
                      ScanResultScreenStyles.backIcon,
                      size: ScanResultScreenStyles.headerIconSize,
                      color: ScanResultScreenStyles.primaryColor,
                    ),
                  ),
                  const SizedBox(
                    width: ScanResultScreenStyles.headerTitleSpacing,
                  ),
                  const Expanded(
                    child: Text(
                      _ScanResultText.appBarTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ScanResultScreenStyles.appBarTitleStyle,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.maybePop(context);
                    },
                    icon: const Icon(
                      ScanResultScreenStyles.newScanIcon,
                      size: ScanResultScreenStyles.actionIconSize,
                    ),
                    label: const Text(_ScanResultText.newScanLabel),
                    style: ScanResultScreenStyles.headerActionStyle,
                  ),
                  const SizedBox(
                    width: ScanResultScreenStyles.headerRightSpacing,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: ScanResultScreenStyles.screenPadding,
          children: <Widget>[
            _buildSuccessBanner(),
            const SizedBox(height: ScanResultScreenStyles.sectionSpacing),
            _ResultSection(
              number: _ScanResultText.imageSectionNumber,
              title: _ScanResultText.imageSectionTitle,
              child: _buildImagePreview(),
            ),
            const SizedBox(height: ScanResultScreenStyles.sectionSpacing),
            _ResultSection(
              number: _ScanResultText.contentSectionNumber,
              title: _ScanResultText.contentSectionTitle,
              action: result.hasContent
                  ? _SectionAction(
                      icon: ScanResultScreenStyles.copyIcon,
                      label: _ScanResultText.copyLabel,
                      tooltip: _ScanResultText.copyTooltip,
                      onPressed: () {
                        _copyToClipboard(
                          context: context,
                          content: _combinedContent,
                          confirmationMessage:
                              _ScanResultText.contentCopiedMessage,
                        );
                      },
                    )
                  : null,
              child: result.hasContent
                  ? _buildRecognizedContent()
                  : _buildEmptyResult(),
            ),
            const SizedBox(height: ScanResultScreenStyles.sectionSpacing),
            _ResultSection(
              number: _ScanResultText.brailleSectionNumber,
              title: _ScanResultText.brailleSectionTitle,
              action: result.hasBraille
                  ? _SectionAction(
                      icon: ScanResultScreenStyles.copyIcon,
                      label: _ScanResultText.copyBrailleLabel,
                      tooltip: _ScanResultText.copyBrailleTooltip,
                      onPressed: () {
                        _copyToClipboard(
                          context: context,
                          content: result.combinedBraille,
                          confirmationMessage:
                              _ScanResultText.brailleCopiedMessage,
                        );
                      },
                    )
                  : null,
              child: result.hasBraille
                  ? _buildBrailleOutput()
                  : _buildBrailleUnavailable(),
            ),
            if (result.hasContent) ...<Widget>[
              const SizedBox(height: ScanResultScreenStyles.sectionSpacing),
              _SaveMaterialButton(result: result, scannedImage: scannedImage),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      padding: ScanResultScreenStyles.successBannerPadding,
      decoration: const BoxDecoration(
        color: ScanResultScreenStyles.successBackgroundColor,
        borderRadius: ScanResultScreenStyles.cardRadius,
        border: ScanResultScreenStyles.successBorder,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: ScanResultScreenStyles.successIconContainerSize,
            height: ScanResultScreenStyles.successIconContainerSize,
            decoration: const BoxDecoration(
              color: ScanResultScreenStyles.successIconBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              ScanResultScreenStyles.successDocumentIcon,
              color: ScanResultScreenStyles.successColor,
              size: ScanResultScreenStyles.successDocumentIconSize,
            ),
          ),
          const SizedBox(width: ScanResultScreenStyles.itemSpacing),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _ScanResultText.successTitle,
                  style: ScanResultScreenStyles.successTitleStyle,
                ),
                SizedBox(height: ScanResultScreenStyles.compactSpacing),
                Text(
                  _ScanResultText.successDescription,
                  style: ScanResultScreenStyles.successDescriptionStyle,
                ),
              ],
            ),
          ),
          const SizedBox(width: ScanResultScreenStyles.compactSpacing),
          const Icon(
            ScanResultScreenStyles.successCheckIcon,
            color: ScanResultScreenStyles.successColor,
            size: ScanResultScreenStyles.successCheckIconSize,
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return _ScannedImagePreview(scannedImage: scannedImage);
  }

  Widget _buildRecognizedContent() {
    final List<DocumentBlock> contentBlocks = result.blocks
        .where(
          (DocumentBlock block) => block.normalizedContent.trim().isNotEmpty,
        )
        .toList(growable: false);

    return Semantics(
      label: _ScanResultText.resultSemanticLabel,
      child: Container(
        width: double.infinity,
        padding: ScanResultScreenStyles.contentPreviewPadding,
        decoration: const BoxDecoration(
          color: ScanResultScreenStyles.surfaceColor,
          borderRadius: ScanResultScreenStyles.innerCardRadius,
          border: ScanResultScreenStyles.innerCardBorder,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List<Widget>.generate(contentBlocks.length, (int index) {
            final DocumentBlock block = contentBlocks[index];

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == contentBlocks.length - 1
                    ? ScanResultScreenStyles.zero
                    : ScanResultScreenStyles.unifiedBlockSpacing,
              ),
              child: _RecognizedBlock(block: block),
            );
          }, growable: false),
        ),
      ),
    );
  }

  Widget _buildBrailleOutput() {
    return Semantics(
      label: _ScanResultText.brailleSemanticLabel,
      child: Container(
        width: double.infinity,
        padding: ScanResultScreenStyles.braillePreviewPadding,
        decoration: const BoxDecoration(
          color: ScanResultScreenStyles.brailleBackgroundColor,
          borderRadius: ScanResultScreenStyles.innerCardRadius,
          border: ScanResultScreenStyles.innerCardBorder,
        ),
        child: SelectableText(
          result.combinedBraille,
          textAlign: TextAlign.left,
          style: ScanResultScreenStyles.brailleContentStyle,
        ),
      ),
    );
  }

  Widget _buildBrailleUnavailable() {
    final String message = result.hasBrailleErrors
        ? _ScanResultText.brailleTranslationFailedDescription
        : _ScanResultText.brailleUnavailableDescription;

    return Padding(
      padding: ScanResultScreenStyles.emptyResultPadding,
      child: Column(
        children: <Widget>[
          const Icon(
            ScanResultScreenStyles.brailleUnavailableIcon,
            size: ScanResultScreenStyles.brailleUnavailableIconSize,
            color: ScanResultScreenStyles.primaryColor,
          ),
          const SizedBox(height: ScanResultScreenStyles.itemSpacing),
          const Text(
            _ScanResultText.brailleUnavailableTitle,
            textAlign: TextAlign.center,
            style: ScanResultScreenStyles.emptyResultTitleStyle,
          ),
          const SizedBox(height: ScanResultScreenStyles.compactSpacing),
          Text(
            message,
            textAlign: TextAlign.center,
            style: ScanResultScreenStyles.emptyResultDescriptionStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResult() {
    return const Padding(
      padding: ScanResultScreenStyles.emptyResultPadding,
      child: Column(
        children: <Widget>[
          Icon(
            ScanResultScreenStyles.emptyResultIcon,
            size: ScanResultScreenStyles.emptyResultIconSize,
            color: ScanResultScreenStyles.primaryColor,
          ),
          SizedBox(height: ScanResultScreenStyles.itemSpacing),
          Text(
            _ScanResultText.emptyResultTitle,
            textAlign: TextAlign.center,
            style: ScanResultScreenStyles.emptyResultTitleStyle,
          ),
          SizedBox(height: ScanResultScreenStyles.compactSpacing),
          Text(
            _ScanResultText.emptyResultDescription,
            textAlign: TextAlign.center,
            style: ScanResultScreenStyles.emptyResultDescriptionStyle,
          ),
        ],
      ),
    );
  }

  Future<void> _copyToClipboard({
    required BuildContext context,
    required String content,
    required String confirmationMessage,
  }) async {
    if (content.trim().isEmpty) return;

    await Clipboard.setData(ClipboardData(text: content));

    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: ScanResultScreenStyles.snackBarDuration,
          behavior: ScanResultScreenStyles.snackBarBehavior,
          backgroundColor: ScanResultScreenStyles.snackBarBackgroundColor,
          margin: ScanResultScreenStyles.snackBarMargin,
          shape: const RoundedRectangleBorder(
            borderRadius: ScanResultScreenStyles.snackBarRadius,
          ),
          content: Text(
            confirmationMessage,
            style: ScanResultScreenStyles.snackBarTextStyle,
          ),
        ),
      );
  }
}

class _SaveMaterialButton extends StatefulWidget {
  const _SaveMaterialButton({required this.result, required this.scannedImage});

  final ScanDocumentResult result;
  final File scannedImage;

  @override
  State<_SaveMaterialButton> createState() => _SaveMaterialButtonState();
}

class _SaveMaterialButtonState extends State<_SaveMaterialButton> {
  final MaterialService _materialService = MaterialService();

  bool _isSaving = false;
  bool _isSaved = false;

  @override
  void dispose() {
    _materialService.dispose();
    super.dispose();
  }

  Future<void> _saveToMaterials() async {
    if (_isSaving || _isSaved) {
      return;
    }

    final _MaterialDetails? details = await _requestMaterialDetails();

    if (!mounted || details == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final String recognizedContent = widget.result.blocks
        .map((DocumentBlock block) => block.normalizedContent.trim())
        .where((String content) => content.isNotEmpty)
        .join(_ScanResultText.contentBlockSeparator);

    try {
      await _materialService.uploadMaterial(
        file: widget.scannedImage,
        title: details.title,
        subject: details.subject,
        description: details.description,
        sourceType: MaterialModel.scanResultSourceType,
        recognizedContent: recognizedContent,
        brailleContent: widget.result.combinedBraille,
        documentBlocks: widget.result.blocks
            .map((DocumentBlock block) => block.toJson())
            .toList(growable: false),
        modelName: widget.result.model,
        pipelineVersion: widget.result.pipelineVersion,
        processingTimeMs: widget.result.processingTimeMs,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _isSaved = true;
      });

      _showMessage(_ScanResultText.materialSavedMessage);
    } on MaterialServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      _showMessage(_ScanResultText.materialSaveFailedMessage);
    }
  }

  Future<_MaterialDetails?> _requestMaterialDetails() {
    return showGeneralDialog<_MaterialDetails>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: ScanResultScreenStyles.saveDialogBarrierColor,
      transitionDuration: ScanResultScreenStyles.saveDialogAnimationDuration,
      pageBuilder:
          (
            BuildContext dialogContext,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return const _MaterialDetailsDialog();
          },
      transitionBuilder:
          (
            BuildContext dialogContext,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final Animation<double> curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: ScanResultScreenStyles.saveDialogEntranceCurve,
              reverseCurve: ScanResultScreenStyles.saveDialogExitCurve,
            );

            final Animation<double> scaleAnimation = Tween<double>(
              begin: ScanResultScreenStyles.saveDialogInitialScale,
              end: 1,
            ).animate(curvedAnimation);

            final Animation<Offset> slideAnimation = Tween<Offset>(
              begin: ScanResultScreenStyles.saveDialogInitialOffset,
              end: Offset.zero,
            ).animate(curvedAnimation);

            return FadeTransition(
              opacity: curvedAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: ScaleTransition(
                  scale: scaleAnimation,
                  alignment: Alignment.center,
                  child: child,
                ),
              ),
            );
          },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: ScanResultScreenStyles.snackBarDuration,
          behavior: ScanResultScreenStyles.snackBarBehavior,
          backgroundColor: ScanResultScreenStyles.snackBarBackgroundColor,
          margin: ScanResultScreenStyles.snackBarMargin,
          shape: const RoundedRectangleBorder(
            borderRadius: ScanResultScreenStyles.snackBarRadius,
          ),
          content: Text(
            message,
            style: ScanResultScreenStyles.snackBarTextStyle,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final String label = _isSaving
        ? _ScanResultText.savingMaterialLabel
        : _isSaved
        ? _ScanResultText.savedMaterialLabel
        : _ScanResultText.saveMaterialLabel;

    return SizedBox(
      width: double.infinity,
      child: Tooltip(
        message: _ScanResultText.saveMaterialTooltip,
        child: FilledButton.icon(
          onPressed: _isSaving || _isSaved ? null : _saveToMaterials,
          style: ScanResultScreenStyles.saveMaterialButtonStyle,
          icon: _isSaving
              ? const SizedBox(
                  width: ScanResultScreenStyles.saveProgressIndicatorSize,
                  height: ScanResultScreenStyles.saveProgressIndicatorSize,
                  child: CircularProgressIndicator(
                    strokeWidth:
                        ScanResultScreenStyles.saveProgressIndicatorStrokeWidth,
                    color: ScanResultScreenStyles.surfaceColor,
                  ),
                )
              : Icon(
                  _isSaved
                      ? ScanResultScreenStyles.savedMaterialIcon
                      : ScanResultScreenStyles.saveMaterialIcon,
                  size: ScanResultScreenStyles.saveMaterialIconSize,
                ),
          label: Text(label),
        ),
      ),
    );
  }
}

class _MaterialDetails {
  const _MaterialDetails({
    required this.title,
    required this.subject,
    required this.description,
  });

  final String title;
  final String subject;
  final String description;
}

class _MaterialDetailsDialog extends StatefulWidget {
  const _MaterialDetailsDialog();

  @override
  State<_MaterialDetailsDialog> createState() => _MaterialDetailsDialogState();
}

class _MaterialDetailsDialogState extends State<_MaterialDetailsDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _subjectController;
  late final TextEditingController _descriptionController;

  String? _titleError;
  String? _subjectError;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: _ScanResultText.defaultMaterialTitle,
    );

    _subjectController = TextEditingController(
      text: _ScanResultText.defaultMaterialSubject,
    );

    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    final String title = _titleController.text.trim();

    final String subject = _subjectController.text.trim();

    final String description = _descriptionController.text.trim();

    final bool hasTitleError = title.isEmpty;
    final bool hasSubjectError = subject.isEmpty;

    if (hasTitleError || hasSubjectError) {
      setState(() {
        _titleError = hasTitleError
            ? _ScanResultText.emptyMaterialTitleError
            : null;

        _subjectError = hasSubjectError
            ? _ScanResultText.emptyMaterialSubjectError
            : null;
      });

      return;
    }

    Navigator.of(context).pop(
      _MaterialDetails(
        title: title,
        subject: subject,
        description: description,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: ScanResultScreenStyles.saveDialogRadius,
      ),
      title: const Text(
        _ScanResultText.saveDialogTitle,
        style: ScanResultScreenStyles.saveDialogTitleStyle,
      ),
      contentPadding: ScanResultScreenStyles.saveDialogContentPadding,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              _ScanResultText.saveDialogDescription,
              style: ScanResultScreenStyles.saveDialogDescriptionStyle,
            ),
            const SizedBox(
              height: ScanResultScreenStyles.saveDialogFieldSpacing,
            ),
            TextField(
              controller: _titleController,
              autofocus: true,
              maxLength: ScanResultScreenStyles.maximumMaterialTitleLength,
              textInputAction: TextInputAction.next,
              style: ScanResultScreenStyles.saveInputTextStyle,
              decoration: ScanResultScreenStyles.saveTitleInputDecoration
                  .copyWith(
                    labelText: _ScanResultText.saveTitleLabel,
                    hintText: _ScanResultText.saveTitleHint,
                    errorText: _titleError,
                  ),
              onChanged: (_) {
                if (_titleError == null) {
                  return;
                }

                setState(() {
                  _titleError = null;
                });
              },
            ),
            const SizedBox(
              height: ScanResultScreenStyles.saveDialogFieldSpacing,
            ),
            TextField(
              controller: _subjectController,
              maxLength: ScanResultScreenStyles.maximumMaterialSubjectLength,
              textInputAction: TextInputAction.next,
              style: ScanResultScreenStyles.saveInputTextStyle,
              decoration: ScanResultScreenStyles.saveSubjectInputDecoration
                  .copyWith(
                    labelText: _ScanResultText.saveSubjectLabel,
                    hintText: _ScanResultText.saveSubjectHint,
                    errorText: _subjectError,
                  ),
              onChanged: (_) {
                if (_subjectError == null) {
                  return;
                }

                setState(() {
                  _subjectError = null;
                });
              },
            ),
            const SizedBox(
              height: ScanResultScreenStyles.saveDialogFieldSpacing,
            ),
            TextField(
              controller: _descriptionController,
              maxLength:
                  ScanResultScreenStyles.maximumMaterialDescriptionLength,
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              style: ScanResultScreenStyles.saveInputTextStyle,
              decoration: ScanResultScreenStyles.saveDescriptionInputDecoration
                  .copyWith(
                    labelText: _ScanResultText.saveDescriptionLabel,
                    hintText: _ScanResultText.saveDescriptionHint,
                  ),
            ),
          ],
        ),
      ),
      actionsPadding: ScanResultScreenStyles.saveDialogActionsPadding,
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          style: ScanResultScreenStyles.saveDialogCancelStyle,
          child: const Text(_ScanResultText.cancelLabel),
        ),
        FilledButton(
          onPressed: _submit,
          style: ScanResultScreenStyles.saveDialogConfirmStyle,
          child: const Text(_ScanResultText.confirmSaveLabel),
        ),
      ],
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({
    required this.number,
    required this.title,
    required this.child,
    this.action,
  });

  final String number;
  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ScanResultScreenStyles.sectionCardPadding,
      decoration: const BoxDecoration(
        color: ScanResultScreenStyles.surfaceColor,
        borderRadius: ScanResultScreenStyles.cardRadius,
        border: ScanResultScreenStyles.cardBorder,
        boxShadow: ScanResultScreenStyles.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: ScanResultScreenStyles.sectionNumberSize,
                height: ScanResultScreenStyles.sectionNumberSize,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: ScanResultScreenStyles.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  number,
                  style: ScanResultScreenStyles.sectionNumberStyle,
                ),
              ),
              const SizedBox(width: ScanResultScreenStyles.itemSpacing),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ScanResultScreenStyles.sectionTitleStyle,
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: ScanResultScreenStyles.sectionHeaderSpacing),
          child,
        ],
      ),
    );
  }
}

class _SectionAction extends StatelessWidget {
  const _SectionAction({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: ScanResultScreenStyles.actionIconSize),
        label: Text(label),
        style: ScanResultScreenStyles.sectionActionStyle,
      ),
    );
  }
}

class _RecognizedBlock extends StatelessWidget {
  const _RecognizedBlock({required this.block});

  final DocumentBlock block;

  String _prepareFormula(String value) {
    String formula = value.trim();

    formula = formula
        .replaceAll('```latex', '')
        .replaceAll('```tex', '')
        .replaceAll('```math', '')
        .replaceAll('```', '')
        .trim();

    final List<(String, String)> delimiters = <(String, String)>[
      (r'$$', r'$$'),
      (r'\[', r'\]'),
      (r'\(', r'\)'),
      (r'$', r'$'),
    ];

    for (final (String opening, String closing) in delimiters) {
      if (formula.startsWith(opening) &&
          formula.endsWith(closing) &&
          formula.length >= opening.length + closing.length) {
        formula = formula
            .substring(opening.length, formula.length - closing.length)
            .trim();

        break;
      }
    }

    formula = formula
        .replaceAll('\\\\', '\\')
        .replaceAll(r'\qquad', r'\;')
        .trim();

    return formula;
  }

  @override
  Widget build(BuildContext context) {
    final String content = block.normalizedContent.trim();
    final String rawContent = block.rawContent.trim();

    final String displayContent = rawContent.isEmpty ? content : rawContent;

    final bool containsLatexFormula =
        displayContent.contains(r'\frac') ||
        displayContent.contains(r'\sqrt') ||
        displayContent.contains(r'\sum') ||
        displayContent.contains(r'\int') ||
        displayContent.contains(r'\begin') ||
        displayContent.contains(r'\left') ||
        displayContent.contains(r'\right');

    final bool shouldRenderAsFormula = block.isFormula || containsLatexFormula;

    if (shouldRenderAsFormula) {
      final String formula = _prepareFormula(displayContent);

      return Container(
        width: double.infinity,
        padding: ScanResultScreenStyles.formulaPreviewPadding,
        decoration: const BoxDecoration(
          color: ScanResultScreenStyles.formulaBackgroundColor,
          borderRadius: ScanResultScreenStyles.formulaRadius,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Math.tex(
            formula,
            mathStyle: MathStyle.display,
            textStyle: ScanResultScreenStyles.formulaContentStyle,
            onErrorFallback: (FlutterMathException error) {
              debugPrint('MATH RENDER ERROR: $error');
              debugPrint('MATH INPUT: $formula');

              return SelectableText(
                formula,
                textAlign: TextAlign.center,
                style: ScanResultScreenStyles.formulaContentStyle,
              );
            },
          ),
        ),
      );
    }

    return SelectableText(
      content,
      textAlign: TextAlign.left,
      style: ScanResultScreenStyles.recognizedContentStyle,
    );
  }
}

class _ScannedImagePreview extends StatefulWidget {
  const _ScannedImagePreview({required this.scannedImage});

  final File scannedImage;

  @override
  State<_ScannedImagePreview> createState() {
    return _ScannedImagePreviewState();
  }
}

class _ScannedImagePreviewState extends State<_ScannedImagePreview> {
  late Future<Size> _imageSizeFuture;

  @override
  void initState() {
    super.initState();

    _imageSizeFuture = _readOrientedImageSize();
  }

  @override
  void didUpdateWidget(covariant _ScannedImagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.scannedImage.path != widget.scannedImage.path) {
      _imageSizeFuture = _readOrientedImageSize();
    }
  }

  Future<Size> _readOrientedImageSize() async {
    if (!await widget.scannedImage.exists()) {
      throw const FormatException('The scanned image could not be found.');
    }

    final Uint8List bytes = await widget.scannedImage.readAsBytes();

    final img.Image? decodedImage = img.decodeImage(bytes);

    if (decodedImage == null) {
      throw const FormatException('The scanned image could not be decoded.');
    }

    final img.Image orientedImage = img.bakeOrientation(decodedImage);

    return Size(
      orientedImage.width.toDouble(),
      orientedImage.height.toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: _ScanResultText.imageSemanticLabel,
      child: FutureBuilder<Size>(
        future: _imageSizeFuture,
        builder: (BuildContext context, AsyncSnapshot<Size> snapshot) {
          if (snapshot.hasError) {
            return const SizedBox(
              height: ScanResultScreenStyles.imageLoadingHeight,
              child: _ImageErrorState(),
            );
          }

          final Size? imageSize = snapshot.data;

          if (imageSize == null || imageSize.isEmpty) {
            return const SizedBox(
              height: ScanResultScreenStyles.imageLoadingHeight,
              child: Center(
                child: CircularProgressIndicator(
                  color: ScanResultScreenStyles.primaryColor,
                ),
              ),
            );
          }

          final double aspectRatio = imageSize.width / imageSize.height;

          return Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: ScanResultScreenStyles.maximumImagePreviewHeight,
              ),
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: ScanResultScreenStyles.imagePreviewBackgroundColor,
                    borderRadius: ScanResultScreenStyles.imagePreviewRadius,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.file(
                    widget.scannedImage,
                    key: ValueKey<String>(widget.scannedImage.path),
                    fit: ScanResultScreenStyles.imagePreviewFit,
                    alignment: Alignment.center,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.medium,
                    errorBuilder:
                        (
                          BuildContext context,
                          Object error,
                          StackTrace? stackTrace,
                        ) {
                          return const _ImageErrorState();
                        },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ImageErrorState extends StatelessWidget {
  const _ImageErrorState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: ScanResultScreenStyles.emptyResultPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              ScanResultScreenStyles.imageErrorIcon,
              size: ScanResultScreenStyles.imageErrorIconSize,
              color: ScanResultScreenStyles.primaryColor,
            ),
            SizedBox(height: ScanResultScreenStyles.itemSpacing),
            Text(
              _ScanResultText.imageErrorText,
              textAlign: TextAlign.center,
              style: ScanResultScreenStyles.emptyResultDescriptionStyle,
            ),
          ],
        ),
      ),
    );
  }
}
