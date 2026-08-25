import 'package:flutter/material.dart';

import '../../models/history/history_model.dart';
import '../../services/history/history_service.dart';
import '../../styles/screens/history/history_screen_styles.dart';
import '../../widgets/app_header.dart';

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
      return HistoryScreenStyles.todayLabel;
    }

    if (difference == 1) {
      return HistoryScreenStyles.yesterdayLabel;
    }

    return MaterialLocalizations.of(context).formatMediumDate(localDate);
  }

  String _recordBadge(HistoryRecord record) {
    return _containsMath(record)
        ? HistoryScreenStyles.mathBadgeLabel
        : HistoryScreenStyles.textBadgeLabel;
  }

  String _brailleCode(HistoryRecord record) {
    return _containsMath(record)
        ? HistoryScreenStyles.nemethLabel
        : HistoryScreenStyles.uebLabel;
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
        _errorMessage = HistoryScreenStyles.errorTitle;
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
        _showMessage(HistoryScreenStyles.errorTitle);
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
    if (_isUpdating) {
      return;
    }

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
            .where((HistoryRecord item) {
              return item.id != record.id;
            })
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
                  const SizedBox(height: 7),
                  SelectableText(
                    record.recognizedContent,
                    style: HistoryScreenStyles.detailContentStyle,
                  ),
                  const SizedBox(height: HistoryScreenStyles.sectionSpacing),
                  const Text(
                    HistoryScreenStyles.brailleContentTitle,
                    style: HistoryScreenStyles.detailSectionTitleStyle,
                  ),
                  const SizedBox(height: 7),
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
    return Row(
      children: <Widget>[
        const Expanded(
          child: Text(
            HistoryScreenStyles.screenTitle,
            style: HistoryScreenStyles.titleStyle,
          ),
        ),
        TextButton(
          onPressed: _records.isEmpty || _isUpdating ? null : _clearAllHistory,
          child: const Text(HistoryScreenStyles.confirmClearLabel),
        ),
      ],
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
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: HistoryScreenStyles.clearSearchTooltip,
                        onPressed: _searchController.clear,
                        icon: const Icon(HistoryScreenStyles.clearSearchIcon),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(width: HistoryScreenStyles.sortSpacing),
        PopupMenuButton<_HistorySort>(
          tooltip: HistoryScreenStyles.sortTooltip,
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
                child: Text(HistoryScreenStyles.newestLabel),
              ),
              PopupMenuItem<_HistorySort>(
                value: _HistorySort.oldest,
                child: Text(HistoryScreenStyles.oldestLabel),
              ),
              PopupMenuItem<_HistorySort>(
                value: _HistorySort.title,
                child: Text(HistoryScreenStyles.titleSortLabel),
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
                _HistoryFilter.all => HistoryScreenStyles.allFilterLabel,
                _HistoryFilter.text => HistoryScreenStyles.textFilterLabel,
                _HistoryFilter.math => HistoryScreenStyles.mathFilterLabel,
                _HistoryFilter.ueb => HistoryScreenStyles.uebFilterLabel,
                _HistoryFilter.nemeth => HistoryScreenStyles.nemethFilterLabel,
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

    final Map<String, List<HistoryRecord>> groups = _groupedRecords;

    return Semantics(
      label: HistoryScreenStyles.historyListSemanticLabel,
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
        ? HistoryScreenStyles.emptyRecognizedContent
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
                          tooltip: HistoryScreenStyles.moreActionsTooltip,
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
                                  title: Text(HistoryScreenStyles.renameLabel),
                                ),
                              ),
                              PopupMenuItem<_HistoryAction>(
                                value: _HistoryAction.delete,
                                child: ListTile(
                                  leading: Icon(
                                    HistoryScreenStyles.deleteIcon,
                                    color: HistoryScreenStyles.primaryColor,
                                  ),
                                  title: Text(HistoryScreenStyles.deleteLabel),
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
                      '${HistoryScreenStyles.brailleTranslationLabel}:',
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
                        '${HistoryScreenStyles.notAvailableLabel}',
                        style: HistoryScreenStyles.brailleUnavailableStyle,
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: HistoryScreenStyles.favoriteTooltip,
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
