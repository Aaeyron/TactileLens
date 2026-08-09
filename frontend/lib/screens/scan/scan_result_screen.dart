import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/ai/scan_document_result.dart';
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
        .map(
          (DocumentBlock block) =>
              block.normalizedContent.trim(),
        )
        .where(
          (String content) => content.isNotEmpty,
        )
        .join(
          ScanResultScreenStyles.contentBlockSeparator,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          ScanResultScreenStyles.backgroundColor,
      appBar: PreferredSize(
        preferredSize: ScanResultScreenStyles.headerSize,
        child: Stack(
          children: <Widget>[
            const AppHeader(),
            SafeArea(
              child: SizedBox(
                height:
                    ScanResultScreenStyles.headerContentHeight,
                child: Row(
                  children: <Widget>[
                    IconButton(
                      tooltip:
                          ScanResultScreenStyles.backTooltip,
                      onPressed: () {
                        Navigator.maybePop(context);
                      },
                      icon: const Icon(
                        ScanResultScreenStyles.backIcon,
                        size: ScanResultScreenStyles
                            .headerIconSize,
                      ),
                    ),
                    const SizedBox(
                      width: ScanResultScreenStyles
                          .headerTitleSpacing,
                    ),
                    const Expanded(
                      child: Text(
                        ScanResultScreenStyles.appBarTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ScanResultScreenStyles
                            .appBarTitleStyle,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.maybePop(context);
                      },
                      icon: const Icon(
                        ScanResultScreenStyles.newScanIcon,
                        size: ScanResultScreenStyles
                            .actionIconSize,
                      ),
                      label: const Text(
                        ScanResultScreenStyles.newScanLabel,
                      ),
                      style: ScanResultScreenStyles
                          .headerActionStyle,
                    ),
                    const SizedBox(
                      width: ScanResultScreenStyles
                          .headerRightSpacing,
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
            const SizedBox(
              height: ScanResultScreenStyles.sectionSpacing,
            ),
            _ResultSection(
              number:
                  ScanResultScreenStyles.imageSectionNumber,
              title: ScanResultScreenStyles.imageSectionTitle,
              child: _buildImagePreview(),
            ),
            const SizedBox(
              height: ScanResultScreenStyles.sectionSpacing,
            ),
            _ResultSection(
              number:
                  ScanResultScreenStyles.contentSectionNumber,
              title:
                  ScanResultScreenStyles.contentSectionTitle,
              action: result.hasContent
                  ? _SectionAction(
                      icon:
                          ScanResultScreenStyles.copyIcon,
                      label:
                          ScanResultScreenStyles.copyLabel,
                      tooltip:
                          ScanResultScreenStyles.copyTooltip,
                      onPressed: () {
                        _copyToClipboard(
                          context: context,
                          content: _combinedContent,
                          confirmationMessage:
                              ScanResultScreenStyles
                                  .contentCopiedMessage,
                        );
                      },
                    )
                  : null,
              child: result.hasContent
                  ? _buildRecognizedContent()
                  : _buildEmptyResult(),
            ),
            const SizedBox(
              height: ScanResultScreenStyles.sectionSpacing,
            ),
            _ResultSection(
              number:
                  ScanResultScreenStyles.brailleSectionNumber,
              title:
                  ScanResultScreenStyles.brailleSectionTitle,
              action: result.hasBraille
                  ? _SectionAction(
                      icon:
                          ScanResultScreenStyles.copyIcon,
                      label: ScanResultScreenStyles
                          .copyBrailleLabel,
                      tooltip: ScanResultScreenStyles
                          .copyBrailleTooltip,
                      onPressed: () {
                        _copyToClipboard(
                          context: context,
                          content: result.combinedBraille,
                          confirmationMessage:
                              ScanResultScreenStyles
                                  .brailleCopiedMessage,
                        );
                      },
                    )
                  : null,
              child: result.hasBraille
                  ? _buildBrailleOutput()
                  : _buildBrailleUnavailable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      padding:
          ScanResultScreenStyles.successBannerPadding,
      decoration: const BoxDecoration(
        color:
            ScanResultScreenStyles.successBackgroundColor,
        borderRadius:
            ScanResultScreenStyles.cardRadius,
        border: ScanResultScreenStyles.successBorder,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: ScanResultScreenStyles
                .successIconContainerSize,
            height: ScanResultScreenStyles
                .successIconContainerSize,
            decoration: const BoxDecoration(
              color: ScanResultScreenStyles
                  .successIconBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              ScanResultScreenStyles.successDocumentIcon,
              color: ScanResultScreenStyles.successColor,
              size: ScanResultScreenStyles
                  .successDocumentIconSize,
            ),
          ),
          const SizedBox(
            width: ScanResultScreenStyles.itemSpacing,
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  ScanResultScreenStyles.successTitle,
                  style: ScanResultScreenStyles
                      .successTitleStyle,
                ),
                SizedBox(
                  height: ScanResultScreenStyles
                      .compactSpacing,
                ),
                Text(
                  ScanResultScreenStyles
                      .successDescription,
                  style: ScanResultScreenStyles
                      .successDescriptionStyle,
                ),
              ],
            ),
          ),
          const SizedBox(
            width: ScanResultScreenStyles.compactSpacing,
          ),
          const Icon(
            ScanResultScreenStyles.successCheckIcon,
            color: ScanResultScreenStyles.successColor,
            size:
                ScanResultScreenStyles.successCheckIconSize,
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
        height:
            ScanResultScreenStyles.imagePreviewHeight,
        decoration: const BoxDecoration(
          color: ScanResultScreenStyles
              .imagePreviewBackgroundColor,
          borderRadius:
              ScanResultScreenStyles.imagePreviewRadius,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.file(
          scannedImage,
          fit: ScanResultScreenStyles.imagePreviewFit,
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) {
            return const _ImageErrorState();
          },
        ),
      ),
    );
  }

  Widget _buildRecognizedContent() {
    final List<DocumentBlock> contentBlocks =
        result.blocks
            .where(
              (DocumentBlock block) =>
                  block.normalizedContent
                      .trim()
                      .isNotEmpty,
            )
            .toList(growable: false);

    return Semantics(
      label: ScanResultScreenStyles.resultSemanticLabel,
      child: Container(
        width: double.infinity,
        padding:
            ScanResultScreenStyles.contentPreviewPadding,
        decoration: const BoxDecoration(
          color: ScanResultScreenStyles.surfaceColor,
          borderRadius:
              ScanResultScreenStyles.innerCardRadius,
          border:
              ScanResultScreenStyles.innerCardBorder,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: List<Widget>.generate(
            contentBlocks.length,
            (int index) {
              final DocumentBlock block =
                  contentBlocks[index];

              return Padding(
                padding: EdgeInsets.only(
                  bottom:
                      index == contentBlocks.length - 1
                          ? ScanResultScreenStyles.zero
                          : ScanResultScreenStyles
                              .unifiedBlockSpacing,
                ),
                child: _RecognizedBlock(block: block),
              );
            },
            growable: false,
          ),
        ),
      ),
    );
  }

  Widget _buildBrailleOutput() {
    return Semantics(
      label:
          ScanResultScreenStyles.brailleSemanticLabel,
      child: Container(
        width: double.infinity,
        padding:
            ScanResultScreenStyles.braillePreviewPadding,
        decoration: const BoxDecoration(
          color: ScanResultScreenStyles
              .brailleBackgroundColor,
          borderRadius:
              ScanResultScreenStyles.innerCardRadius,
          border:
              ScanResultScreenStyles.innerCardBorder,
        ),
        child: SelectableText(
          result.combinedBraille,
          textAlign: TextAlign.left,
          style:
              ScanResultScreenStyles.brailleContentStyle,
        ),
      ),
    );
  }

  Widget _buildBrailleUnavailable() {
    final String message = result.hasBrailleErrors
        ? ScanResultScreenStyles
            .brailleTranslationFailedDescription
        : ScanResultScreenStyles
            .brailleUnavailableDescription;

    return Padding(
      padding:
          ScanResultScreenStyles.emptyResultPadding,
      child: Column(
        children: <Widget>[
          const Icon(
            ScanResultScreenStyles
                .brailleUnavailableIcon,
            size: ScanResultScreenStyles
                .brailleUnavailableIconSize,
            color: ScanResultScreenStyles.primaryColor,
          ),
          const SizedBox(
            height: ScanResultScreenStyles.itemSpacing,
          ),
          const Text(
            ScanResultScreenStyles
                .brailleUnavailableTitle,
            textAlign: TextAlign.center,
            style: ScanResultScreenStyles
                .emptyResultTitleStyle,
          ),
          const SizedBox(
            height: ScanResultScreenStyles.compactSpacing,
          ),
          Text(
            message,
            textAlign: TextAlign.center,
            style: ScanResultScreenStyles
                .emptyResultDescriptionStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResult() {
    return const Padding(
      padding:
          ScanResultScreenStyles.emptyResultPadding,
      child: Column(
        children: <Widget>[
          Icon(
            ScanResultScreenStyles.emptyResultIcon,
            size:
                ScanResultScreenStyles.emptyResultIconSize,
            color: ScanResultScreenStyles.primaryColor,
          ),
          SizedBox(
            height: ScanResultScreenStyles.itemSpacing,
          ),
          Text(
            ScanResultScreenStyles.emptyResultTitle,
            textAlign: TextAlign.center,
            style: ScanResultScreenStyles
                .emptyResultTitleStyle,
          ),
          SizedBox(
            height: ScanResultScreenStyles.compactSpacing,
          ),
          Text(
            ScanResultScreenStyles
                .emptyResultDescription,
            textAlign: TextAlign.center,
            style: ScanResultScreenStyles
                .emptyResultDescriptionStyle,
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

    await Clipboard.setData(
      ClipboardData(text: content),
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration:
              ScanResultScreenStyles.snackBarDuration,
          behavior:
              ScanResultScreenStyles.snackBarBehavior,
          backgroundColor: ScanResultScreenStyles
              .snackBarBackgroundColor,
          margin:
              ScanResultScreenStyles.snackBarMargin,
          shape: const RoundedRectangleBorder(
            borderRadius:
                ScanResultScreenStyles.snackBarRadius,
          ),
          content: Text(
            confirmationMessage,
            style: ScanResultScreenStyles
                .snackBarTextStyle,
          ),
        ),
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
      padding:
          ScanResultScreenStyles.sectionCardPadding,
      decoration: const BoxDecoration(
        color: ScanResultScreenStyles.surfaceColor,
        borderRadius:
            ScanResultScreenStyles.cardRadius,
        border: ScanResultScreenStyles.cardBorder,
        boxShadow:
            ScanResultScreenStyles.cardShadow,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: ScanResultScreenStyles
                    .sectionNumberSize,
                height: ScanResultScreenStyles
                    .sectionNumberSize,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color:
                      ScanResultScreenStyles.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  number,
                  style: ScanResultScreenStyles
                      .sectionNumberStyle,
                ),
              ),
              const SizedBox(
                width:
                    ScanResultScreenStyles.itemSpacing,
              ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ScanResultScreenStyles
                      .sectionTitleStyle,
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(
            height: ScanResultScreenStyles
                .sectionHeaderSpacing,
          ),
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
        icon: Icon(
          icon,
          size: ScanResultScreenStyles.actionIconSize,
        ),
        label: Text(label),
        style:
            ScanResultScreenStyles.sectionActionStyle,
      ),
    );
  }
}

class _RecognizedBlock extends StatelessWidget {
  const _RecognizedBlock({
    required this.block,
  });

  final DocumentBlock block;

  @override
  Widget build(BuildContext context) {
    final String content =
        block.normalizedContent.trim();

    if (block.isFormula) {
      return Container(
        width: double.infinity,
        padding:
            ScanResultScreenStyles.formulaPreviewPadding,
        decoration: const BoxDecoration(
          color: ScanResultScreenStyles
              .formulaBackgroundColor,
          borderRadius:
              ScanResultScreenStyles.formulaRadius,
        ),
        child: SelectableText(
          content,
          textAlign: TextAlign.center,
          style:
              ScanResultScreenStyles.formulaContentStyle,
        ),
      );
    }

    return SelectableText(
      content,
      textAlign: TextAlign.left,
      style: ScanResultScreenStyles
          .recognizedContentStyle,
    );
  }
}

class _ImageErrorState extends StatelessWidget {
  const _ImageErrorState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding:
            ScanResultScreenStyles.emptyResultPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              ScanResultScreenStyles.imageErrorIcon,
              size: ScanResultScreenStyles
                  .imageErrorIconSize,
              color:
                  ScanResultScreenStyles.primaryColor,
            ),
            SizedBox(
              height:
                  ScanResultScreenStyles.itemSpacing,
            ),
            Text(
              ScanResultScreenStyles.imageErrorText,
              textAlign: TextAlign.center,
              style: ScanResultScreenStyles
                  .emptyResultDescriptionStyle,
            ),
          ],
        ),
      ),
    );
  }
}