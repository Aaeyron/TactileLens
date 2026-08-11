import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/ai/scan_document_result.dart';
import '../../services/history/history_service.dart';
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
              _SaveHistoryButton(result: result),
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

class _SaveHistoryButton extends StatefulWidget {
  const _SaveHistoryButton({required this.result});

  final ScanDocumentResult result;

  @override
  State<_SaveHistoryButton> createState() => _SaveHistoryButtonState();
}

class _SaveHistoryButtonState extends State<_SaveHistoryButton> {
  final HistoryService _historyService = HistoryService();

  bool _isSaving = false;
  bool _isSaved = false;

  @override
  void dispose() {
    _historyService.dispose();
    super.dispose();
  }

  Future<void> _saveToHistory() async {
    if (_isSaving || _isSaved) {
      return;
    }

    final String? title = await _requestTitle();

    if (!mounted || title == null) {
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
      await _historyService.createHistory(
        title: title,
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

      _showMessage(ScanResultScreenStyles.historySavedMessage);
    } on HistoryServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      _showMessage(error.message);
    }
  }

  Future<String?> _requestTitle() {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return const _HistoryTitleDialog();
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
        ? ScanResultScreenStyles.savingHistoryLabel
        : _isSaved
        ? ScanResultScreenStyles.savedHistoryLabel
        : ScanResultScreenStyles.saveHistoryLabel;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _isSaving || _isSaved ? null : _saveToHistory,
        style: ScanResultScreenStyles.saveHistoryButtonStyle,
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
                    ? ScanResultScreenStyles.savedHistoryIcon
                    : ScanResultScreenStyles.saveHistoryIcon,
                size: ScanResultScreenStyles.saveHistoryIconSize,
              ),
        label: Text(label),
      ),
    );
  }
}

class _HistoryTitleDialog extends StatefulWidget {
  const _HistoryTitleDialog();

  @override
  State<_HistoryTitleDialog> createState() => _HistoryTitleDialogState();
}

class _HistoryTitleDialogState extends State<_HistoryTitleDialog> {
  late final TextEditingController _controller;

  String? _errorText;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: ScanResultScreenStyles.defaultHistoryTitle,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final String cleanTitle = _controller.text.trim();

    if (cleanTitle.isEmpty) {
      setState(() {
        _errorText = ScanResultScreenStyles.emptyHistoryTitleError;
      });
      return;
    }

    Navigator.of(context).pop(cleanTitle);
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            ScanResultScreenStyles.saveDialogDescription,
            style: ScanResultScreenStyles.saveDialogDescriptionStyle,
          ),
          const SizedBox(height: ScanResultScreenStyles.itemSpacing),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: ScanResultScreenStyles.maximumHistoryTitleLength,
            textInputAction: TextInputAction.done,
            style: ScanResultScreenStyles.saveInputTextStyle,
            decoration: ScanResultScreenStyles.saveTitleInputDecoration
                .copyWith(errorText: _errorText),
            onChanged: (_) {
              if (_errorText == null) {
                return;
              }

              setState(() {
                _errorText = null;
              });
            },
            onSubmitted: (_) {
              _submit();
            },
          ),
        ],
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
              if (action != null) action!,
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

  @override
  Widget build(BuildContext context) {
    final String content = block.normalizedContent.trim();

    if (block.isFormula) {
      return Container(
        width: double.infinity,
        padding: ScanResultScreenStyles.formulaPreviewPadding,
        decoration: const BoxDecoration(
          color: ScanResultScreenStyles.formulaBackgroundColor,
          borderRadius: ScanResultScreenStyles.formulaRadius,
        ),
        child: SelectableText(
          content,
          textAlign: TextAlign.center,
          style: ScanResultScreenStyles.formulaContentStyle,
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
