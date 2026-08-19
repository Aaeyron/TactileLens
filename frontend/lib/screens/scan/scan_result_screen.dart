import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter/services.dart';

import '../../models/ai/scan_document_result.dart';
import '../../models/materials/material_model.dart';
import '../../services/materials/material_service.dart';
import '../../styles/screens/scan/scan_result_screen_styles.dart';
import '../../widgets/app_header.dart';

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
        .join(ScanResultScreenStyles.contentBlockSeparator);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScanResultScreenStyles.backgroundColor,
      appBar: PreferredSize(
        preferredSize: ScanResultScreenStyles.headerSize,
        child: Stack(
          children: <Widget>[
            const AppHeader(),
            SafeArea(
              child: SizedBox(
                height: ScanResultScreenStyles.headerContentHeight,
                child: Row(
                  children: <Widget>[
                    IconButton(
                      tooltip: ScanResultScreenStyles.backTooltip,
                      onPressed: () {
                        Navigator.maybePop(context);
                      },
                      icon: const Icon(
                        ScanResultScreenStyles.backIcon,
                        size: ScanResultScreenStyles.headerIconSize,
                      ),
                    ),
                    const SizedBox(
                      width: ScanResultScreenStyles.headerTitleSpacing,
                    ),
                    const Expanded(
                      child: Text(
                        ScanResultScreenStyles.appBarTitle,
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
                      label: const Text(ScanResultScreenStyles.newScanLabel),
                      style: ScanResultScreenStyles.headerActionStyle,
                    ),
                    const SizedBox(
                      width: ScanResultScreenStyles.headerRightSpacing,
                    ),
                  ],
                ),
              ),
            ),
          ],
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
              number: ScanResultScreenStyles.imageSectionNumber,
              title: ScanResultScreenStyles.imageSectionTitle,
              child: _buildImagePreview(),
            ),
            const SizedBox(height: ScanResultScreenStyles.sectionSpacing),
            _ResultSection(
              number: ScanResultScreenStyles.contentSectionNumber,
              title: ScanResultScreenStyles.contentSectionTitle,
              action: result.hasContent
                  ? _SectionAction(
                      icon: ScanResultScreenStyles.copyIcon,
                      label: ScanResultScreenStyles.copyLabel,
                      tooltip: ScanResultScreenStyles.copyTooltip,
                      onPressed: () {
                        _copyToClipboard(
                          context: context,
                          content: _combinedContent,
                          confirmationMessage:
                              ScanResultScreenStyles.contentCopiedMessage,
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
              number: ScanResultScreenStyles.brailleSectionNumber,
              title: ScanResultScreenStyles.brailleSectionTitle,
              action: result.hasBraille
                  ? _SectionAction(
                      icon: ScanResultScreenStyles.copyIcon,
                      label: ScanResultScreenStyles.copyBrailleLabel,
                      tooltip: ScanResultScreenStyles.copyBrailleTooltip,
                      onPressed: () {
                        _copyToClipboard(
                          context: context,
                          content: result.combinedBraille,
                          confirmationMessage:
                              ScanResultScreenStyles.brailleCopiedMessage,
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
                  ScanResultScreenStyles.successTitle,
                  style: ScanResultScreenStyles.successTitleStyle,
                ),
                SizedBox(height: ScanResultScreenStyles.compactSpacing),
                Text(
                  ScanResultScreenStyles.successDescription,
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
    return Semantics(
      image: true,
      label: ScanResultScreenStyles.imageSemanticLabel,
      child: Container(
        width: double.infinity,
        height: ScanResultScreenStyles.imagePreviewHeight,
        decoration: const BoxDecoration(
          color: ScanResultScreenStyles.imagePreviewBackgroundColor,
          borderRadius: ScanResultScreenStyles.imagePreviewRadius,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.file(
          scannedImage,
          fit: ScanResultScreenStyles.imagePreviewFit,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stackTrace) {
                return const _ImageErrorState();
              },
        ),
      ),
    );
  }

  Widget _buildRecognizedContent() {
    final List<DocumentBlock> contentBlocks = result.blocks
        .where(
          (DocumentBlock block) => block.normalizedContent.trim().isNotEmpty,
        )
        .toList(growable: false);

    return Semantics(
      label: ScanResultScreenStyles.resultSemanticLabel,
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
      label: ScanResultScreenStyles.brailleSemanticLabel,
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
        ? ScanResultScreenStyles.brailleTranslationFailedDescription
        : ScanResultScreenStyles.brailleUnavailableDescription;

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
            ScanResultScreenStyles.brailleUnavailableTitle,
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
            ScanResultScreenStyles.emptyResultTitle,
            textAlign: TextAlign.center,
            style: ScanResultScreenStyles.emptyResultTitleStyle,
          ),
          SizedBox(height: ScanResultScreenStyles.compactSpacing),
          Text(
            ScanResultScreenStyles.emptyResultDescription,
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
        .join(ScanResultScreenStyles.contentBlockSeparator);

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

      _showMessage(ScanResultScreenStyles.materialSavedMessage);
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

      _showMessage(ScanResultScreenStyles.materialSaveFailedMessage);
    }
  }

  Future<_MaterialDetails?> _requestMaterialDetails() {
    return showDialog<_MaterialDetails>(
      context: context,
      builder: (BuildContext dialogContext) {
        return const _MaterialDetailsDialog();
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
        ? ScanResultScreenStyles.savingMaterialLabel
        : _isSaved
        ? ScanResultScreenStyles.savedMaterialLabel
        : ScanResultScreenStyles.saveMaterialLabel;

    return SizedBox(
      width: double.infinity,
      child: Tooltip(
        message: ScanResultScreenStyles.saveMaterialTooltip,
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
      text: ScanResultScreenStyles.defaultMaterialTitle,
    );

    _subjectController = TextEditingController(
      text: ScanResultScreenStyles.defaultMaterialSubject,
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
            ? ScanResultScreenStyles.emptyMaterialTitleError
            : null;

        _subjectError = hasSubjectError
            ? ScanResultScreenStyles.emptyMaterialSubjectError
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
        ScanResultScreenStyles.saveDialogTitle,
        style: ScanResultScreenStyles.saveDialogTitleStyle,
      ),
      contentPadding: ScanResultScreenStyles.saveDialogContentPadding,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              ScanResultScreenStyles.saveDialogDescription,
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
                  .copyWith(errorText: _titleError),
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
                  .copyWith(errorText: _subjectError),
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
              decoration: ScanResultScreenStyles.saveDescriptionInputDecoration,
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
          child: const Text(ScanResultScreenStyles.cancelLabel),
        ),
        FilledButton(
          onPressed: _submit,
          style: ScanResultScreenStyles.saveDialogConfirmStyle,
          child: const Text(ScanResultScreenStyles.confirmSaveLabel),
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

    return formula;
  }

  @override
  Widget build(BuildContext context) {
    final String content = block.normalizedContent.trim();

    if (block.isFormula) {
      final String rawFormula = block.rawContent.trim();

      final String formula = _prepareFormula(
        rawFormula.isEmpty ? content : rawFormula,
      );

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
            onErrorFallback: (_) {
              return SelectableText(
                content,
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
              ScanResultScreenStyles.imageErrorText,
              textAlign: TextAlign.center,
              style: ScanResultScreenStyles.emptyResultDescriptionStyle,
            ),
          ],
        ),
      ),
    );
  }
}
