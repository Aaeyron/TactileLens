import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/ai/scan_document_result.dart';
import '../../styles/screens/scan/scan_result_screen_styles.dart';

class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({
    super.key,
    required this.result,
    required this.scannedImage,
  });

  final ScanDocumentResult result;
  final File scannedImage;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          ScanResultScreenStyles.backgroundColor,
      appBar: AppBar(
        elevation:
            ScanResultScreenStyles.appBarElevation,
        backgroundColor:
            ScanResultScreenStyles.appBarBackgroundColor,
        foregroundColor:
            ScanResultScreenStyles.appBarForegroundColor,
        title: const Text(
          ScanResultScreenStyles.appBarTitle,
          style:
              ScanResultScreenStyles.appBarTitleStyle,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding:
              ScanResultScreenStyles.screenPadding,
          children: <Widget>[
            _buildImagePreview(),
            const SizedBox(
              height:
                  ScanResultScreenStyles.sectionSpacing,
            ),
            _buildStatusCard(),
            const SizedBox(
              height:
                  ScanResultScreenStyles.sectionSpacing,
            ),
            _buildMetrics(),
            const SizedBox(
              height:
                  ScanResultScreenStyles.sectionSpacing,
            ),
            if (result.hasContent)
              _buildUnifiedContentPreview(context)
            else
              _buildEmptyResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Semantics(
      image: true,
      label:
          ScanResultScreenStyles.imageSemanticLabel,
      child: Container(
        width: double.infinity,
        height:
            ScanResultScreenStyles.imagePreviewHeight,
        decoration: BoxDecoration(
          color: ScanResultScreenStyles
              .imagePreviewBackgroundColor,
          borderRadius:
              ScanResultScreenStyles.imagePreviewRadius,
          border: Border.all(
            color: ScanResultScreenStyles
                .imagePreviewBorderColor,
            width: ScanResultScreenStyles
                .imagePreviewBorderWidth,
          ),
          boxShadow:
              ScanResultScreenStyles.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.file(
          scannedImage,
          fit:
              ScanResultScreenStyles.imagePreviewFit,
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

  Widget _buildStatusCard() {
    return Container(
      padding: ScanResultScreenStyles.cardPadding,
      decoration: BoxDecoration(
        color: ScanResultScreenStyles.surfaceColor,
        borderRadius:
            ScanResultScreenStyles.cardRadius,
        border: Border.all(
          color: ScanResultScreenStyles.outlineColor,
          width:
              ScanResultScreenStyles.cardBorderWidth,
        ),
        boxShadow:
            ScanResultScreenStyles.cardShadow,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: ScanResultScreenStyles
                .statusIconContainerSize,
            height: ScanResultScreenStyles
                .statusIconContainerSize,
            decoration: const BoxDecoration(
              color: ScanResultScreenStyles
                  .primaryTintColor,
              borderRadius: ScanResultScreenStyles
                  .statusIconRadius,
            ),
            alignment: Alignment.center,
            child: const Icon(
              ScanResultScreenStyles.statusIcon,
              color:
                  ScanResultScreenStyles.primaryColor,
              size:
                  ScanResultScreenStyles.statusIconSize,
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
                  ScanResultScreenStyles.statusTitle,
                  style: ScanResultScreenStyles
                      .statusTitleStyle,
                ),
                SizedBox(
                  height: ScanResultScreenStyles
                      .compactSpacing,
                ),
                Text(
                  ScanResultScreenStyles
                      .statusDescription,
                  style: ScanResultScreenStyles
                      .statusDescriptionStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics() {
    final String processingTime =
        result.processingTimeMs > 0
            ? '${(result.processingTimeMs / 1000).toStringAsFixed(1)}'
                '${ScanResultScreenStyles.secondUnit}'
            : ScanResultScreenStyles
                .unavailableMetricValue;

    return Wrap(
      spacing:
          ScanResultScreenStyles.metricSpacing,
      runSpacing:
          ScanResultScreenStyles.metricSpacing,
      children: <Widget>[
        _ResultMetric(
          icon:
              ScanResultScreenStyles.textMetricIcon,
          label:
              ScanResultScreenStyles.textMetricLabel,
          value:
              result.textBlocks.length.toString(),
        ),
        _ResultMetric(
          icon: ScanResultScreenStyles
              .formulaMetricIcon,
          label: ScanResultScreenStyles
              .formulaMetricLabel,
          value:
              result.formulaBlocks.length.toString(),
        ),
        _ResultMetric(
          icon:
              ScanResultScreenStyles.pageMetricIcon,
          label:
              ScanResultScreenStyles.pageMetricLabel,
          value: result.pageCount.toString(),
        ),
        _ResultMetric(
          icon:
              ScanResultScreenStyles.timeMetricIcon,
          label:
              ScanResultScreenStyles.timeMetricLabel,
          value: processingTime,
        ),
      ],
    );
  }

  Widget _buildUnifiedContentPreview(
    BuildContext context,
  ) {
    return Semantics(
      label:
          ScanResultScreenStyles.resultSemanticLabel,
      child: Container(
        width: double.infinity,
        padding:
            ScanResultScreenStyles.blockContentPadding,
        decoration: BoxDecoration(
          color: ScanResultScreenStyles.surfaceColor,
          borderRadius:
              ScanResultScreenStyles.cardRadius,
          border: Border.all(
            color:
                ScanResultScreenStyles.outlineColor,
            width:
                ScanResultScreenStyles.cardBorderWidth,
          ),
          boxShadow:
              ScanResultScreenStyles.cardShadow,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: ScanResultScreenStyles
                      .blockIconContainerSize,
                  height: ScanResultScreenStyles
                      .blockIconContainerSize,
                  decoration: const BoxDecoration(
                    color: ScanResultScreenStyles
                        .primaryTintColor,
                    borderRadius:
                        ScanResultScreenStyles
                            .blockIconRadius,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    ScanResultScreenStyles
                        .unknownBlockIcon,
                    size: ScanResultScreenStyles
                        .blockHeaderIconSize,
                    color: ScanResultScreenStyles
                        .primaryColor,
                  ),
                ),
                const SizedBox(
                  width: ScanResultScreenStyles
                      .itemSpacing,
                ),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        ScanResultScreenStyles
                            .contentSectionTitle,
                        style: ScanResultScreenStyles
                            .sectionTitleStyle,
                      ),
                      SizedBox(
                        height: ScanResultScreenStyles
                            .compactSpacing,
                      ),
                      Text(
                        ScanResultScreenStyles
                            .contentSectionDescription,
                        style: ScanResultScreenStyles
                            .sectionDescriptionStyle,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip:
                      ScanResultScreenStyles.copyTooltip,
                  onPressed: () {
                    _copyContent(
                      context,
                      _combinedContent,
                    );
                  },
                  icon: const Icon(
                    ScanResultScreenStyles.copyIcon,
                    color: ScanResultScreenStyles
                        .copyIconColor,
                    size: ScanResultScreenStyles
                        .copyIconSize,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height:
                  ScanResultScreenStyles.itemSpacing,
            ),
            const Divider(
              height:
                  ScanResultScreenStyles.cardBorderWidth,
              thickness:
                  ScanResultScreenStyles.cardBorderWidth,
              color:
                  ScanResultScreenStyles.dividerColor,
            ),
            const SizedBox(
              height:
                  ScanResultScreenStyles.itemSpacing,
            ),
            ..._buildUnifiedBlocks(),
          ],
        ),
      ),
    );
  }

 List<Widget> _buildUnifiedBlocks() {
  final List<DocumentBlock> contentBlocks = result.blocks
      .where(
        (DocumentBlock block) =>
            block.normalizedContent.trim().isNotEmpty,
      )
      .toList(growable: false);

  return List<Widget>.generate(
    contentBlocks.length,
    (int index) {
      final DocumentBlock block = contentBlocks[index];

      return Padding(
        padding: EdgeInsets.only(
          bottom: index == contentBlocks.length - 1
              ? 0
              : ScanResultScreenStyles.unifiedBlockSpacing,
        ),
        child: _buildUnifiedBlock(block),
      );
    },
    growable: false,
  );
}



 Widget _buildUnifiedBlock(
  DocumentBlock block,
) {
  final String displayContent =
      block.normalizedContent.trim();

  if (block.isFormula) {
    return Container(
      width: double.infinity,
      padding:
          ScanResultScreenStyles.formulaPreviewPadding,
      decoration: const BoxDecoration(
        color: ScanResultScreenStyles
            .formulaBlockBackgroundColor,
        borderRadius:
            ScanResultScreenStyles.formulaPreviewRadius,
      ),
      child: SelectableText(
        displayContent,
        style:
            ScanResultScreenStyles.formulaContentStyle,
        textAlign: TextAlign.center,
      ),
    );
  }

  return SelectableText(
    displayContent,
    style: ScanResultScreenStyles.blockContentStyle,
    textAlign: TextAlign.left,
  );
}

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

  Widget _buildEmptyResult() {
    return Container(
      padding:
          ScanResultScreenStyles.cardPadding,
      decoration: BoxDecoration(
        color:
            ScanResultScreenStyles.surfaceColor,
        borderRadius:
            ScanResultScreenStyles.cardRadius,
        border: Border.all(
          color:
              ScanResultScreenStyles.outlineColor,
          width:
              ScanResultScreenStyles.cardBorderWidth,
        ),
        boxShadow:
            ScanResultScreenStyles.cardShadow,
      ),
      child: const Column(
        children: <Widget>[
          Icon(
            ScanResultScreenStyles.emptyResultIcon,
            size: ScanResultScreenStyles
                .emptyResultIconSize,
            color:
                ScanResultScreenStyles.primaryColor,
          ),
          SizedBox(
            height:
                ScanResultScreenStyles.itemSpacing,
          ),
          Text(
            ScanResultScreenStyles.emptyResultTitle,
            style: ScanResultScreenStyles
                .emptyResultTitleStyle,
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height:
                ScanResultScreenStyles.compactSpacing,
          ),
          Text(
            ScanResultScreenStyles
                .emptyResultDescription,
            style: ScanResultScreenStyles
                .emptyResultDescriptionStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _copyContent(
    BuildContext context,
    String content,
  ) async {
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
          content: const Text(
            ScanResultScreenStyles.copiedMessage,
            style: ScanResultScreenStyles
                .snackBarTextStyle,
          ),
        ),
      );
  }
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          ScanResultScreenStyles.metricPadding,
      decoration: const BoxDecoration(
        color:
            ScanResultScreenStyles.primarySoftColor,
        borderRadius:
            ScanResultScreenStyles.metricRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size:
                ScanResultScreenStyles.metricIconSize,
            color:
                ScanResultScreenStyles.primaryColor,
          ),
          const SizedBox(
            width:
                ScanResultScreenStyles.compactSpacing,
          ),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                value,
                style: ScanResultScreenStyles
                    .metricValueStyle,
              ),
              Text(
                label,
                style: ScanResultScreenStyles
                    .metricLabelStyle,
              ),
            ],
          ),
        ],
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
        padding:
            ScanResultScreenStyles.cardPadding,
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
              style: ScanResultScreenStyles
                  .emptyResultDescriptionStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}