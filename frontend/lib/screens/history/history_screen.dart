import 'package:flutter/material.dart';

import '../../models/history/history_model.dart';
import '../../services/history/history_service.dart';
import '../../styles/screens/history/history_screen_styles.dart';
import '../../widgets/app_header.dart';

abstract final class _HistoryText {
  static const String screenTitle = 'History';
  static const String screenDescription =
      'Review and manage your previously scanned documents.';
  static const String searchHint = 'Search History';

  static const String allFilterLabel = 'All';
  static const String textFilterLabel = 'Text';
  static const String mathFilterLabel = 'Math';
  static const String uebFilterLabel = 'UEB';
  static const String nemethFilterLabel = 'Nemeth';

  static const String todayLabel = 'Today';
  static const String yesterdayLabel = 'Yesterday';

  static const String mathBadgeLabel = 'Math Equation';
  static const String textBadgeLabel = 'Printed Text';

  static const String nemethLabel = 'Nemeth';
  static const String uebLabel = 'UEB';

  static const String brailleTranslationLabel = 'Braille Translation';

  static const String notAvailableLabel = 'not available';

  static const String emptyRecognizedContent =
      'No recognized content was saved.';

  static const String newestLabel = 'Newest first';
  static const String oldestLabel = 'Oldest first';
  static const String titleSortLabel = 'Title A–Z';

  static const String clearSearchTooltip = 'Clear history search';
  static const String sortTooltip = 'Sort scan history';

  static const String loadingLabel = 'Loading your scan history...';

  static const String emptyTitle = 'No scan history yet';
  static const String emptyDescription =
      'Your successful scans will appear here.';

  static const String emptySearchTitle = 'No matching scans';
  static const String emptySearchDescription =
      'Try another search word or filter.';

  static const String errorTitle = 'Unable to load history';
  static const String retryLabel = 'Try Again';

  static const String recognizedContentTitle = 'Recognized Content';

  static const String brailleContentTitle = 'Braille Output';

  static const String noBrailleContent =
      'No Braille output was saved for this scan.';

  static const String closeLabel = 'Close';

  static const String renameLabel = 'Rename';
  static const String deleteLabel = 'Delete';

  static const String moreActionsTooltip = 'More history actions';

  static const String favoriteTooltip = 'Add to favorites';

  static const String renameDialogTitle = 'Rename Scan';
  static const String renameFieldLabel = 'Title';

  static const String cancelLabel = 'Cancel';
  static const String saveLabel = 'Save';

  static const String deleteDialogTitle = 'Delete Scan?';

  static const String deleteDialogDescription =
      'This scan will be permanently removed from your history.';

  static const String confirmDeleteLabel = 'Delete';

  static const String renameSuccessMessage = 'History title updated.';

  static const String deleteSuccessMessage = 'Scan removed from history.';

  static const String historyListSemanticLabel = 'Saved scan history';
}

enum _HistoryFilter { all, text, math, ueb, nemeth }

enum _HistoryAction { rename, delete }

enum _HistorySort { newest, oldest, title }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.onBack});

  // Retained for compatibility with MainScreen.
  final VoidCallback onBack;

  @override
  State<HistoryScreen> createState() {
    return _HistoryScreenState();
  }
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  final TextEditingController _searchController = TextEditingController();

  List<HistoryRecord> _records = <HistoryRecord>[];

  _HistoryFilter _selectedFilter = _HistoryFilter.all;
  _HistorySort _selectedSort = _HistorySort.newest;

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

  bool _containsMath(HistoryRecord record) {
    final String content = record.recognizedContent.toLowerCase();

    return content.contains(r'\frac') ||
        content.contains(r'\sqrt') ||
        content.contains(r'\sum') ||
        content.contains(r'\int') ||
        content.contains('=') ||
        content.contains('^') ||
        RegExp(r'\d+\s*[+\-*/]\s*\d+').hasMatch(content);
  }

  bool _hasBraille(HistoryRecord record) {
    return record.brailleContent.trim().isNotEmpty;
  }

  bool _matchesSelectedFilter(HistoryRecord record) {
    final bool containsMath = _containsMath(record);
    final bool hasBraille = _hasBraille(record);

    return switch (_selectedFilter) {
      _HistoryFilter.all => true,
      _HistoryFilter.text => !containsMath,
      _HistoryFilter.math => containsMath,
      _HistoryFilter.ueb => !containsMath && hasBraille,
      _HistoryFilter.nemeth => containsMath && hasBraille,
    };
  }

  List<HistoryRecord> get _visibleRecords {
    final String searchQuery = _searchController.text.trim().toLowerCase();

    final List<HistoryRecord> records = _records
        .where((HistoryRecord record) {
          if (!_matchesSelectedFilter(record)) {
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

    switch (_selectedSort) {
      case _HistorySort.newest:
        records.sort((HistoryRecord first, HistoryRecord second) {
          return second.createdAt.compareTo(first.createdAt);
        });

      case _HistorySort.oldest:
        records.sort((HistoryRecord first, HistoryRecord second) {
          return first.createdAt.compareTo(second.createdAt);
        });

      case _HistorySort.title:
        records.sort((HistoryRecord first, HistoryRecord second) {
          return first.title.toLowerCase().compareTo(
            second.title.toLowerCase(),
          );
        });
    }

    return records;
  }

  Map<String, List<HistoryRecord>> get _groupedRecords {
    final Map<String, List<HistoryRecord>> groups =
        <String, List<HistoryRecord>>{};

    for (final HistoryRecord record in _visibleRecords) {
      final String group = _dateGroupLabel(record.createdAt);

      groups.putIfAbsent(group, () => <HistoryRecord>[]);

      groups[group]!.add(record);
    }

    return groups;
  }

  String _dateGroupLabel(DateTime value) {
    final DateTime localDate = value.toLocal();
    final DateTime now = DateTime.now();

    final DateTime today = DateTime(now.year, now.month, now.day);

    final DateTime recordDate = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
    );

    final int difference = today.difference(recordDate).inDays;

    if (difference == 0) {
      return _HistoryText.todayLabel;
    }

    if (difference == 1) {
      return _HistoryText.yesterdayLabel;
    }

    return MaterialLocalizations.of(context).formatMediumDate(localDate);
  }

  String _recordBadge(HistoryRecord record) {
    return _containsMath(record)
        ? _HistoryText.mathBadgeLabel
        : _HistoryText.textBadgeLabel;
  }

  String _brailleCode(HistoryRecord record) {
    return _containsMath(record)
        ? _HistoryText.nemethLabel
        : _HistoryText.uebLabel;
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
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = _HistoryText.errorTitle;
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
      if (mounted) {
        _showMessage(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showMessage(_HistoryText.errorTitle);
      }
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

      _showMessage(_HistoryText.renameSuccessMessage);
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
    if (_isUpdating) {
      return;
    }

    final bool confirmed = await _showConfirmationDialog(
      title: _HistoryText.deleteDialogTitle,
      description: _HistoryText.deleteDialogDescription,
      confirmationLabel: _HistoryText.confirmDeleteLabel,
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
            .where((HistoryRecord item) {
              return item.id != record.id;
            })
            .toList(growable: false);

        _isUpdating = false;
      });

      _showMessage(_HistoryText.deleteSuccessMessage);
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
              child: const Text(_HistoryText.cancelLabel),
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
                    _HistoryText.recognizedContentTitle,
                    style: HistoryScreenStyles.detailSectionTitleStyle,
                  ),
                  const SizedBox(height: 7),
                  SelectableText(
                    record.recognizedContent,
                    style: HistoryScreenStyles.detailContentStyle,
                  ),
                  const SizedBox(height: HistoryScreenStyles.sectionSpacing),
                  const Text(
                    _HistoryText.brailleContentTitle,
                    style: HistoryScreenStyles.detailSectionTitleStyle,
                  ),
                  const SizedBox(height: 7),
                  SelectableText(
                    record.brailleContent.trim().isEmpty
                        ? _HistoryText.noBrailleContent
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
                    child: const Text(_HistoryText.closeLabel),
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
      resizeToAvoidBottomInset: true,
      backgroundColor: HistoryScreenStyles.backgroundColor,
      body: Column(
        children: <Widget>[
          // Shared logo-and-notification header.
          // No back arrow is added here.
          const AppHeader(),
          Expanded(
            child: RefreshIndicator(
              color: HistoryScreenStyles.primaryColor,
              onRefresh: _refreshHistory,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: HistoryScreenStyles.screenPadding,
                children: <Widget>[
                  _buildTitle(),
                  const SizedBox(height: HistoryScreenStyles.searchTopSpacing),
                  _buildSearchAndSort(),
                  const SizedBox(height: HistoryScreenStyles.filterTopSpacing),
                  _buildFilters(),
                  const SizedBox(height: HistoryScreenStyles.sectionSpacing),
                  _buildContent(),
                  const SizedBox(height: HistoryScreenStyles.bottomSpacing),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Container(
      width: double.infinity,
      padding: HistoryScreenStyles.headerContainerPadding,
      decoration: const BoxDecoration(
        color: HistoryScreenStyles.primaryColor,
        borderRadius: HistoryScreenStyles.headerContainerRadius,
        border: HistoryScreenStyles.headerContainerBorder,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _HistoryText.screenTitle,
            style: HistoryScreenStyles.headerTitleStyle,
          ),
          SizedBox(height: HistoryScreenStyles.headerDescriptionSpacing),
          Text(
            _HistoryText.screenDescription,
            style: HistoryScreenStyles.headerDescriptionStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndSort() {
    return Row(
      children: <Widget>[
        Expanded(
          child: SizedBox(
            height: HistoryScreenStyles.searchHeight,
            child: TextField(
              controller: _searchController,
              style: HistoryScreenStyles.searchTextStyle,
              decoration: HistoryScreenStyles.searchDecoration.copyWith(
                hintText: _HistoryText.searchHint,
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: _HistoryText.clearSearchTooltip,
                        onPressed: _searchController.clear,
                        icon: const Icon(HistoryScreenStyles.clearSearchIcon),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(width: HistoryScreenStyles.sortSpacing),
        PopupMenuButton<_HistorySort>(
          tooltip: _HistoryText.sortTooltip,
          initialValue: _selectedSort,
          onSelected: (_HistorySort sort) {
            setState(() {
              _selectedSort = sort;
            });
          },
          icon: const Icon(
            HistoryScreenStyles.sortIcon,
            color: HistoryScreenStyles.textMutedColor,
          ),
          itemBuilder: (BuildContext context) {
            return const <PopupMenuEntry<_HistorySort>>[
              PopupMenuItem<_HistorySort>(
                value: _HistorySort.newest,
                child: Text(_HistoryText.newestLabel),
              ),
              PopupMenuItem<_HistorySort>(
                value: _HistorySort.oldest,
                child: Text(_HistoryText.oldestLabel),
              ),
              PopupMenuItem<_HistorySort>(
                value: _HistorySort.title,
                child: Text(_HistoryText.titleSortLabel),
              ),
            ];
          },
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _HistoryFilter.values
            .map((_HistoryFilter filter) {
              final String label = switch (filter) {
                _HistoryFilter.all => _HistoryText.allFilterLabel,
                _HistoryFilter.text => _HistoryText.textFilterLabel,
                _HistoryFilter.math => _HistoryText.mathFilterLabel,
                _HistoryFilter.ueb => _HistoryText.uebFilterLabel,
                _HistoryFilter.nemeth => _HistoryText.nemethFilterLabel,
              };

              return Padding(
                padding: const EdgeInsets.only(
                  right: HistoryScreenStyles.filterSpacing,
                ),
                child: _HistoryFilterButton(
                  label: label,
                  isSelected: _selectedFilter == filter,
                  onPressed: () {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const _HistoryStateView(
        icon: HistoryScreenStyles.historyIcon,
        title: _HistoryText.loadingLabel,
        showProgressIndicator: true,
      );
    }

    if (_errorMessage != null) {
      return _HistoryStateView(
        icon: HistoryScreenStyles.errorIcon,
        title: _HistoryText.errorTitle,
        description: _errorMessage,
        actionLabel: _HistoryText.retryLabel,
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
            ? _HistoryText.emptySearchTitle
            : _HistoryText.emptyTitle,
        description: hasSearchOrFilter
            ? _HistoryText.emptySearchDescription
            : _HistoryText.emptyDescription,
      );
    }

    final Map<String, List<HistoryRecord>> groups = _groupedRecords;

    return Semantics(
      label: _HistoryText.historyListSemanticLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: groups.entries
            .map((MapEntry<String, List<HistoryRecord>> group) {
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: HistoryScreenStyles.groupSpacing,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(group.key, style: HistoryScreenStyles.groupTitleStyle),
                    const SizedBox(
                      height: HistoryScreenStyles.groupTitleSpacing,
                    ),
                    ...List<Widget>.generate(group.value.length, (int index) {
                      final HistoryRecord record = group.value[index];

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == group.value.length - 1
                              ? 0
                              : HistoryScreenStyles.cardSpacing,
                        ),
                        child: _HistoryCard(
                          record: record,
                          badge: _recordBadge(record),
                          brailleCode: _brailleCode(record),
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
                  ],
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _HistoryFilterButton extends StatelessWidget {
  const _HistoryFilterButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? HistoryScreenStyles.primaryColor
          : HistoryScreenStyles.filterBackgroundColor,
      borderRadius: HistoryScreenStyles.filterRadius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: HistoryScreenStyles.filterRadius,
        child: Container(
          height: HistoryScreenStyles.filterHeight,
          padding: HistoryScreenStyles.filterPadding,
          alignment: Alignment.center,
          child: Text(
            label,
            style: isSelected
                ? HistoryScreenStyles.selectedFilterTextStyle
                : HistoryScreenStyles.unselectedFilterTextStyle,
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.record,
    required this.badge,
    required this.brailleCode,
    required this.onView,
    required this.onRename,
    required this.onDelete,
  });

  final HistoryRecord record;
  final String badge;
  final String brailleCode;

  final VoidCallback onView;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final String recognizedContent = record.recognizedContent.trim();

    final String previewContent = recognizedContent.isEmpty
        ? _HistoryText.emptyRecognizedContent
        : recognizedContent;

    return Material(
      color: HistoryScreenStyles.cardBackgroundColor,
      borderRadius: HistoryScreenStyles.cardRadius,
      child: InkWell(
        onTap: onView,
        borderRadius: HistoryScreenStyles.cardRadius,
        child: Container(
          padding: HistoryScreenStyles.cardPadding,
          decoration: const BoxDecoration(
            borderRadius: HistoryScreenStyles.cardRadius,
            border: HistoryScreenStyles.cardBorder,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: HistoryScreenStyles.previewWidth,
                height: HistoryScreenStyles.previewHeight,
                padding: HistoryScreenStyles.previewPadding,
                decoration: const BoxDecoration(
                  color: HistoryScreenStyles.previewBackgroundColor,
                  borderRadius: HistoryScreenStyles.previewRadius,
                ),
                child: Text(
                  previewContent,
                  maxLines: HistoryScreenStyles.previewMaximumLines,
                  overflow: TextOverflow.ellipsis,
                  style: HistoryScreenStyles.previewTextStyle,
                ),
              ),
              const SizedBox(width: HistoryScreenStyles.cardContentSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Container(
                            padding: HistoryScreenStyles.badgePadding,
                            decoration: const BoxDecoration(
                              color: HistoryScreenStyles.primaryColor,
                              borderRadius: HistoryScreenStyles.badgeRadius,
                            ),
                            child: Text(
                              badge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: HistoryScreenStyles.badgeTextStyle,
                            ),
                          ),
                        ),
                        PopupMenuButton<_HistoryAction>(
                          tooltip: _HistoryText.moreActionsTooltip,
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            HistoryScreenStyles.moreActionsIcon,
                            size: HistoryScreenStyles.moreActionIconSize,
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
                                  title: Text(_HistoryText.renameLabel),
                                ),
                              ),
                              PopupMenuItem<_HistoryAction>(
                                value: _HistoryAction.delete,
                                child: ListTile(
                                  leading: Icon(
                                    HistoryScreenStyles.deleteIcon,
                                    color: HistoryScreenStyles.primaryColor,
                                  ),
                                  title: Text(_HistoryText.deleteLabel),
                                ),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                    Text(
                      previewContent,
                      maxLines: HistoryScreenStyles.contentMaximumLines,
                      overflow: TextOverflow.ellipsis,
                      style: HistoryScreenStyles.contentStyle,
                    ),
                    const SizedBox(
                      height: HistoryScreenStyles.brailleLabelSpacing,
                    ),
                    const Text(
                      '${_HistoryText.brailleTranslationLabel}:',
                      style: HistoryScreenStyles.brailleLabelStyle,
                    ),
                    if (_hasVisibleBraille)
                      Text(
                        record.brailleContent,
                        maxLines: HistoryScreenStyles.brailleMaximumLines,
                        overflow: TextOverflow.ellipsis,
                        style: HistoryScreenStyles.brailleStyle,
                      )
                    else
                      Text(
                        '$brailleCode '
                        '${_HistoryText.notAvailableLabel}',
                        style: HistoryScreenStyles.brailleUnavailableStyle,
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: _HistoryText.favoriteTooltip,
                onPressed: null,
                icon: const Icon(HistoryScreenStyles.favoriteIcon),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasVisibleBraille {
    return record.brailleContent.trim().isNotEmpty;
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
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: HistoryScreenStyles.stateTitleStyle,
          ),
          if (description != null) ...<Widget>[
            const SizedBox(height: 7),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: HistoryScreenStyles.stateDescriptionStyle,
            ),
          ],
          if (actionLabel != null && onActionPressed != null) ...<Widget>[
            const SizedBox(height: 18),
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
  State<_RenameHistoryDialog> createState() {
    return _RenameHistoryDialogState();
  }
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
        _HistoryText.renameDialogTitle,
        style: HistoryScreenStyles.dialogTitleStyle,
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 150,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          labelText: _HistoryText.renameFieldLabel,
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
          child: const Text(_HistoryText.cancelLabel),
        ),
        FilledButton(
          onPressed: _submit,
          style: HistoryScreenStyles.retryButtonStyle,
          child: const Text(_HistoryText.saveLabel),
        ),
      ],
    );
  }
}
