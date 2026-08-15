import 'package:flutter/material.dart';

import '../../models/history/history_model.dart';
import '../../services/history/history_service.dart';
import '../../styles/screens/history/history_screen_styles.dart';
import '../../widgets/app_header.dart';

enum _HistoryFilter { all, content, braille }

enum _HistoryAction { rename, delete }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  final TextEditingController _searchController = TextEditingController();

  List<HistoryRecord> _records = <HistoryRecord>[];
  _HistoryFilter _selectedFilter = _HistoryFilter.all;

  bool _isLoading = true;
  bool _isUpdating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_handleSearchChanged);
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();

    _historyService.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    setState(() {});
  }

  List<HistoryRecord> get _visibleRecords {
    final String searchQuery = _searchController.text.trim().toLowerCase();

    return _records
        .where((HistoryRecord record) {
          final bool matchesFilter = switch (_selectedFilter) {
            _HistoryFilter.all => true,
            _HistoryFilter.content =>
              record.recognizedContent.trim().isNotEmpty,
            _HistoryFilter.braille => record.brailleContent.trim().isNotEmpty,
          };

          if (!matchesFilter) {
            return false;
          }

          if (searchQuery.isEmpty) {
            return true;
          }

          return record.title.toLowerCase().contains(searchQuery) ||
              record.recognizedContent.toLowerCase().contains(searchQuery) ||
              record.brailleContent.toLowerCase().contains(searchQuery);
        })
        .toList(growable: false);
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final HistoryPage page = await _historyService.getHistory(limit: 100);

      if (!mounted) {
        return;
      }

      setState(() {
        _records = page.records;
        _isLoading = false;
      });
    } on HistoryServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    }
  }

  Future<void> _refreshHistory() async {
    try {
      final HistoryPage page = await _historyService.getHistory(limit: 100);

      if (!mounted) {
        return;
      }

      setState(() {
        _records = page.records;
        _errorMessage = null;
      });
    } on HistoryServiceException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    }
  }

  Future<void> _renameRecord(HistoryRecord record) async {
    final String? newTitle = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return _RenameHistoryDialog(currentTitle: record.title);
      },
    );

    if (!mounted || newTitle == null) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final HistoryRecord updatedRecord = await _historyService.renameHistory(
        historyId: record.id,
        title: newTitle,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _records = _records
            .map((HistoryRecord item) {
              return item.id == updatedRecord.id ? updatedRecord : item;
            })
            .toList(growable: false);

        _isUpdating = false;
      });

      _showMessage(HistoryScreenStyles.renameSuccessMessage);
    } on HistoryServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdating = false;
      });

      _showMessage(error.message);
    }
  }

  Future<void> _deleteRecord(HistoryRecord record) async {
    final bool confirmed = await _showConfirmationDialog(
      title: HistoryScreenStyles.deleteDialogTitle,
      description: HistoryScreenStyles.deleteDialogDescription,
      confirmationLabel: HistoryScreenStyles.confirmDeleteLabel,
    );

    if (!mounted || !confirmed) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await _historyService.deleteHistory(record.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _records = _records
            .where((HistoryRecord item) => item.id != record.id)
            .toList(growable: false);

        _isUpdating = false;
      });

      _showMessage(HistoryScreenStyles.deleteSuccessMessage);
    } on HistoryServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdating = false;
      });

      _showMessage(error.message);
    }
  }

  Future<void> _clearAllHistory() async {
    if (_records.isEmpty || _isUpdating) {
      return;
    }

    final bool confirmed = await _showConfirmationDialog(
      title: HistoryScreenStyles.clearDialogTitle,
      description: HistoryScreenStyles.clearDialogDescription,
      confirmationLabel: HistoryScreenStyles.confirmClearLabel,
    );

    if (!mounted || !confirmed) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      for (final HistoryRecord record in _records) {
        await _historyService.deleteHistory(record.id);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _records = <HistoryRecord>[];
        _isUpdating = false;
      });

      _showMessage(HistoryScreenStyles.clearSuccessMessage);
    } on HistoryServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdating = false;
      });

      _showMessage(error.message);
      await _refreshHistory();
    }
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String description,
    required String confirmationLabel,
  }) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: HistoryScreenStyles.dialogRadius,
          ),
          title: Text(title, style: HistoryScreenStyles.dialogTitleStyle),
          content: Text(
            description,
            style: HistoryScreenStyles.dialogDescriptionStyle,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(HistoryScreenStyles.cancelLabel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: HistoryScreenStyles.retryButtonStyle,
              child: Text(confirmationLabel),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  void _showRecordDetails(HistoryRecord record) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: HistoryScreenStyles.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: HistoryScreenStyles.detailSheetRadius,
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.82,
            child: SingleChildScrollView(
              padding: HistoryScreenStyles.detailSheetPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    record.title,
                    style: HistoryScreenStyles.detailTitleStyle,
                  ),
                  const SizedBox(height: HistoryScreenStyles.sectionSpacing),
                  const Text(
                    HistoryScreenStyles.recognizedContentTitle,
                    style: HistoryScreenStyles.detailSectionTitleStyle,
                  ),
                  const SizedBox(height: HistoryScreenStyles.compactSpacing),
                  SelectableText(
                    record.recognizedContent,
                    style: HistoryScreenStyles.detailContentStyle,
                  ),
                  const SizedBox(height: HistoryScreenStyles.sectionSpacing),
                  const Text(
                    HistoryScreenStyles.brailleContentTitle,
                    style: HistoryScreenStyles.detailSectionTitleStyle,
                  ),
                  const SizedBox(height: HistoryScreenStyles.compactSpacing),
                  SelectableText(
                    record.brailleContent.trim().isEmpty
                        ? HistoryScreenStyles.noBrailleContent
                        : record.brailleContent,
                    style: record.brailleContent.trim().isEmpty
                        ? HistoryScreenStyles.detailContentStyle
                        : HistoryScreenStyles.detailBrailleStyle,
                  ),
                  const SizedBox(height: HistoryScreenStyles.sectionSpacing),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                    },
                    style: HistoryScreenStyles.retryButtonStyle,
                    child: const Text(HistoryScreenStyles.closeLabel),
                  ),
                ],
              ),
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
          duration: HistoryScreenStyles.snackBarDuration,
          behavior: HistoryScreenStyles.snackBarBehavior,
          backgroundColor: HistoryScreenStyles.primaryColor,
          margin: HistoryScreenStyles.snackBarMargin,
          shape: const RoundedRectangleBorder(
            borderRadius: HistoryScreenStyles.snackBarRadius,
          ),
          content: Text(message, style: HistoryScreenStyles.snackBarTextStyle),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HistoryScreenStyles.backgroundColor,
      appBar: PreferredSize(
        preferredSize: HistoryScreenStyles.headerSize,
        child: Stack(
          children: <Widget>[
            const AppHeader(),
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: HistoryScreenStyles.headerPadding,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          tooltip: HistoryScreenStyles.backButtonTooltip,
                          onPressed: widget.onBack,
                          icon: const Icon(
                            HistoryScreenStyles.backButtonIcon,
                            size: HistoryScreenStyles.backButtonIconSize,
                            color: HistoryScreenStyles.primaryColor,
                          ),
                        ),
                      ),
                      _buildHeader(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: HistoryScreenStyles.primaryColor,
        onRefresh: _refreshHistory,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: HistoryScreenStyles.screenPadding,
          children: <Widget>[
            _buildHistoryToolbar(),
            const SizedBox(height: HistoryScreenStyles.toolbarBottomSpacing),
            _buildFilters(),
            const SizedBox(height: HistoryScreenStyles.sectionSpacing),
            _buildSearchField(),
            const SizedBox(height: HistoryScreenStyles.sectionSpacing),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Center(
      child: Text(
        HistoryScreenStyles.screenTitle,
        style: HistoryScreenStyles.titleStyle,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildHistoryToolbar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const Expanded(
          child: Text(
            HistoryScreenStyles.screenDescription,
            style: HistoryScreenStyles.descriptionStyle,
          ),
        ),
        const SizedBox(width: HistoryScreenStyles.compactSpacing),
        TextButton.icon(
          onPressed: _records.isEmpty || _isUpdating ? null : _clearAllHistory,
          icon: const Icon(
            HistoryScreenStyles.clearAllIcon,
            size: HistoryScreenStyles.clearAllIconSize,
          ),
          label: const Text(HistoryScreenStyles.clearAllLabel),
          style: HistoryScreenStyles.clearAllButtonStyle,
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          _HistoryFilterButton(
            label: HistoryScreenStyles.allFilterLabel,
            icon: HistoryScreenStyles.allFilterIcon,
            isSelected: _selectedFilter == _HistoryFilter.all,
            onPressed: () {
              setState(() {
                _selectedFilter = _HistoryFilter.all;
              });
            },
          ),
          const SizedBox(width: HistoryScreenStyles.filterSpacing),
          _HistoryFilterButton(
            label: HistoryScreenStyles.contentFilterLabel,
            icon: HistoryScreenStyles.contentFilterIcon,
            isSelected: _selectedFilter == _HistoryFilter.content,
            onPressed: () {
              setState(() {
                _selectedFilter = _HistoryFilter.content;
              });
            },
          ),
          const SizedBox(width: HistoryScreenStyles.filterSpacing),
          _HistoryFilterButton(
            label: HistoryScreenStyles.brailleFilterLabel,
            icon: HistoryScreenStyles.brailleFilterIcon,
            isSelected: _selectedFilter == _HistoryFilter.braille,
            onPressed: () {
              setState(() {
                _selectedFilter = _HistoryFilter.braille;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      height: HistoryScreenStyles.searchHeight,
      child: TextField(
        controller: _searchController,
        style: HistoryScreenStyles.searchTextStyle,
        decoration: HistoryScreenStyles.searchDecoration.copyWith(
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  tooltip: HistoryScreenStyles.searchTooltip,
                  onPressed: _searchController.clear,
                  icon: const Icon(
                    HistoryScreenStyles.clearSearchIcon,
                    color: HistoryScreenStyles.textSecondaryColor,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const _HistoryStateView(
        icon: HistoryScreenStyles.historyIcon,
        title: HistoryScreenStyles.loadingLabel,
        showProgressIndicator: true,
      );
    }

    if (_errorMessage != null) {
      return _HistoryStateView(
        icon: HistoryScreenStyles.errorIcon,
        title: HistoryScreenStyles.errorTitle,
        description: _errorMessage,
        actionLabel: HistoryScreenStyles.retryLabel,
        onActionPressed: _loadHistory,
      );
    }

    final List<HistoryRecord> visibleRecords = _visibleRecords;

    if (visibleRecords.isEmpty) {
      final bool hasSearchOrFilter =
          _searchController.text.trim().isNotEmpty ||
          _selectedFilter != _HistoryFilter.all;

      return _HistoryStateView(
        icon: hasSearchOrFilter
            ? HistoryScreenStyles.emptySearchIcon
            : HistoryScreenStyles.emptyIcon,
        title: hasSearchOrFilter
            ? HistoryScreenStyles.emptySearchTitle
            : HistoryScreenStyles.emptyTitle,
        description: hasSearchOrFilter
            ? HistoryScreenStyles.emptySearchDescription
            : HistoryScreenStyles.emptyDescription,
      );
    }

    return Semantics(
      label: HistoryScreenStyles.historyListSemanticLabel,
      child: Column(
        children: List<Widget>.generate(visibleRecords.length, (int index) {
          final HistoryRecord record = visibleRecords[index];

          return Padding(
            padding: EdgeInsets.only(
              bottom: index == visibleRecords.length - 1
                  ? HistoryScreenStyles.zero
                  : HistoryScreenStyles.cardSpacing,
            ),
            child: _HistoryCard(
              record: record,
              showBraille: _selectedFilter == _HistoryFilter.braille,
              onView: () {
                _showRecordDetails(record);
              },
              onRename: () {
                _renameRecord(record);
              },
              onDelete: () {
                _deleteRecord(record);
              },
            ),
          );
        }, growable: false),
      ),
    );
  }
}

class _HistoryFilterButton extends StatelessWidget {
  const _HistoryFilterButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: HistoryScreenStyles.filterRadius,
      child: Container(
        height: HistoryScreenStyles.filterHeight,
        padding: HistoryScreenStyles.filterPadding,
        decoration: BoxDecoration(
          color: isSelected
              ? HistoryScreenStyles.primaryColor
              : HistoryScreenStyles.surfaceColor,
          borderRadius: HistoryScreenStyles.filterRadius,
          border: Border.all(
            color: isSelected
                ? HistoryScreenStyles.primaryColor
                : HistoryScreenStyles.outlineColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: HistoryScreenStyles.filterIconSize,
              color: isSelected
                  ? HistoryScreenStyles.surfaceColor
                  : HistoryScreenStyles.textSecondaryColor,
            ),
            const SizedBox(width: HistoryScreenStyles.compactSpacing),
            Text(
              label,
              style: isSelected
                  ? HistoryScreenStyles.selectedFilterTextStyle
                  : HistoryScreenStyles.unselectedFilterTextStyle,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.record,
    required this.showBraille,
    required this.onView,
    required this.onRename,
    required this.onDelete,
  });

  final HistoryRecord record;
  final bool showBraille;
  final VoidCallback onView;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(
      context,
    );

    final String date = localizations.formatMediumDate(record.createdAt);

    final String time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(record.createdAt),
    );

    final bool displayBraille =
        showBraille && record.brailleContent.trim().isNotEmpty;

    final String previewContent = displayBraille
        ? record.brailleContent
        : record.recognizedContent;

    return Container(
      padding: HistoryScreenStyles.cardPadding,
      decoration: const BoxDecoration(
        color: HistoryScreenStyles.surfaceColor,
        borderRadius: HistoryScreenStyles.cardRadius,
        border: HistoryScreenStyles.cardBorder,
        boxShadow: HistoryScreenStyles.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: HistoryScreenStyles.previewWidth,
            height: HistoryScreenStyles.previewHeight,
            padding: HistoryScreenStyles.previewPadding,
            decoration: const BoxDecoration(
              color: HistoryScreenStyles.softBackgroundColor,
              borderRadius: HistoryScreenStyles.previewRadius,
            ),
            child: Text(
              previewContent,
              maxLines: HistoryScreenStyles.previewMaximumLines,
              overflow: TextOverflow.ellipsis,
              style: displayBraille
                  ? HistoryScreenStyles.previewBrailleStyle
                  : HistoryScreenStyles.previewTextStyle,
            ),
          ),
          const SizedBox(width: HistoryScreenStyles.itemSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: HistoryScreenStyles.badgePadding,
                      decoration: const BoxDecoration(
                        color: HistoryScreenStyles.selectedBackgroundColor,
                        borderRadius: HistoryScreenStyles.badgeRadius,
                      ),
                      child: Text(
                        displayBraille
                            ? HistoryScreenStyles.brailleBadgeLabel
                            : HistoryScreenStyles.contentBadgeLabel,
                        style: HistoryScreenStyles.badgeTextStyle,
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<_HistoryAction>(
                      tooltip: HistoryScreenStyles.moreActionsTooltip,
                      icon: const Icon(
                        HistoryScreenStyles.moreActionsIcon,
                        size: HistoryScreenStyles.moreActionIconSize,
                        color: HistoryScreenStyles.textSecondaryColor,
                      ),
                      onSelected: (_HistoryAction action) {
                        switch (action) {
                          case _HistoryAction.rename:
                            onRename();
                          case _HistoryAction.delete:
                            onDelete();
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return const <PopupMenuEntry<_HistoryAction>>[
                          PopupMenuItem<_HistoryAction>(
                            value: _HistoryAction.rename,
                            child: ListTile(
                              leading: Icon(HistoryScreenStyles.renameIcon),
                              title: Text(HistoryScreenStyles.renameLabel),
                            ),
                          ),
                          PopupMenuItem<_HistoryAction>(
                            value: _HistoryAction.delete,
                            child: ListTile(
                              leading: Icon(
                                HistoryScreenStyles.deleteIcon,
                                color: HistoryScreenStyles.destructiveColor,
                              ),
                              title: Text(HistoryScreenStyles.deleteLabel),
                            ),
                          ),
                        ];
                      },
                    ),
                  ],
                ),
                const SizedBox(height: HistoryScreenStyles.compactSpacing),
                Text(
                  record.title,
                  maxLines: HistoryScreenStyles.cardTitleMaximumLines,
                  overflow: TextOverflow.ellipsis,
                  style: HistoryScreenStyles.cardTitleStyle,
                ),
                const SizedBox(height: HistoryScreenStyles.compactSpacing),
                Text(
                  previewContent,
                  maxLines: HistoryScreenStyles.cardDescriptionMaximumLines,
                  overflow: TextOverflow.ellipsis,
                  style: HistoryScreenStyles.cardDescriptionStyle,
                ),
                const SizedBox(height: HistoryScreenStyles.itemSpacing),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: HistoryScreenStyles.metadataSpacing,
                  children: <Widget>[
                    const Icon(
                      HistoryScreenStyles.calendarIcon,
                      size: HistoryScreenStyles.metadataIconSize,
                      color: HistoryScreenStyles.textMutedColor,
                    ),
                    Text(date, style: HistoryScreenStyles.metadataTextStyle),
                    const Text(
                      HistoryScreenStyles.metadataSeparator,
                      style: HistoryScreenStyles.metadataTextStyle,
                    ),
                    const Icon(
                      HistoryScreenStyles.timeIcon,
                      size: HistoryScreenStyles.metadataIconSize,
                      color: HistoryScreenStyles.textMutedColor,
                    ),
                    Text(time, style: HistoryScreenStyles.metadataTextStyle),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onView,
                    icon: const Icon(
                      HistoryScreenStyles.viewIcon,
                      size: HistoryScreenStyles.actionIconSize,
                    ),
                    label: const Text(HistoryScreenStyles.viewLabel),
                    style: HistoryScreenStyles.viewButtonStyle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryStateView extends StatelessWidget {
  const _HistoryStateView({
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onActionPressed,
    this.showProgressIndicator = false,
  });

  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final bool showProgressIndicator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: HistoryScreenStyles.statePadding,
      child: Column(
        children: <Widget>[
          if (showProgressIndicator)
            const CircularProgressIndicator(
              color: HistoryScreenStyles.primaryColor,
            )
          else
            Icon(
              icon,
              size: HistoryScreenStyles.stateIconSize,
              color: HistoryScreenStyles.primaryColor,
            ),
          const SizedBox(height: HistoryScreenStyles.itemSpacing),
          Text(
            title,
            textAlign: TextAlign.center,
            style: HistoryScreenStyles.stateTitleStyle,
          ),
          if (description != null) ...<Widget>[
            const SizedBox(height: HistoryScreenStyles.compactSpacing),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: HistoryScreenStyles.stateDescriptionStyle,
            ),
          ],
          if (actionLabel != null && onActionPressed != null) ...<Widget>[
            const SizedBox(height: HistoryScreenStyles.itemSpacing),
            FilledButton(
              onPressed: onActionPressed,
              style: HistoryScreenStyles.retryButtonStyle,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _RenameHistoryDialog extends StatefulWidget {
  const _RenameHistoryDialog({required this.currentTitle});

  final String currentTitle;

  @override
  State<_RenameHistoryDialog> createState() => _RenameHistoryDialogState();
}

class _RenameHistoryDialogState extends State<_RenameHistoryDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.currentTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final String title = _controller.text.trim();

    if (title.isEmpty) {
      return;
    }

    Navigator.of(context).pop(title);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: HistoryScreenStyles.dialogRadius,
      ),
      title: const Text(
        HistoryScreenStyles.renameDialogTitle,
        style: HistoryScreenStyles.dialogTitleStyle,
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 150,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          labelText: HistoryScreenStyles.renameFieldLabel,
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) {
          _submit();
        },
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(HistoryScreenStyles.cancelLabel),
        ),
        FilledButton(
          onPressed: _submit,
          style: HistoryScreenStyles.retryButtonStyle,
          child: const Text(HistoryScreenStyles.saveLabel),
        ),
      ],
    );
  }
}
