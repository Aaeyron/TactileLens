import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/history/history_model.dart';
import '../../services/history/history_service.dart';
import '../../styles/screens/history/history_screen_styles.dart';

abstract final class _HistoryText {
  static const String screenTitle = 'History';
  static const String screenDescription =
      'Review your processed scans and Braille translations.';
  static const String searchHint = 'Search history';

  static const String allFilterLabel = 'All';
  static const String textFilterLabel = 'Text';
  static const String mathFilterLabel = 'Math';

  static const String todayLabel = 'Today';
  static const String yesterdayLabel = 'Yesterday';

  static const String mathBadgeLabel = 'Math';
  static const String textBadgeLabel = 'Text';

  static const String nemethLabel = 'Nemeth';
  static const String uebLabel = 'UEB';

  static const String notAvailableLabel = 'not available';

  static const String newestLabel = 'Newest first';
  static const String oldestLabel = 'Oldest first';
  static const String titleSortLabel = 'Title A–Z';

  static const String emptyRecognizedContent =
      'No recognized content was saved.';

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

  static const String clearAllLabel = 'Clear All';
  static const String clearAllTooltip = 'Clear all scan history';

  static const String clearAllDialogTitle = 'Clear All History?';

  static const String clearAllDialogDescription =
      'Every saved scan in your history will be permanently removed.';

  static const String confirmClearAllLabel = 'Clear All';

  static const String clearAllSuccessMessage = 'All scan history was removed.';

  static const String historyListSemanticLabel = 'Saved scan history';
}

enum _HistoryFilter { all, text, math }

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

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final HistoryService _historyService = HistoryService();
  final TextEditingController _searchController = TextEditingController();

  late final AnimationController _entranceController;
  late final Animation<double> _entranceOpacity;
  late final Animation<Offset> _entrancePosition;

  List<HistoryRecord> _records = <HistoryRecord>[];

  _HistoryFilter _selectedFilter = _HistoryFilter.all;
  _HistorySort _selectedSort = _HistorySort.newest;

  bool _isLoading = true;
  bool _isUpdating = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    final CurvedAnimation entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    _entranceOpacity = entranceAnimation;

    _entrancePosition = Tween<Offset>(
      begin: const Offset(0, 0.025),
      end: Offset.zero,
    ).animate(entranceAnimation);

    _searchController.addListener(_handleSearchChanged);

    _loadHistory();
    _entranceController.forward();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();

    _entranceController.dispose();
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

  bool _matchesSelectedFilter(HistoryRecord record) {
    final bool containsMath = _containsMath(record);

    return switch (_selectedFilter) {
      _HistoryFilter.all => true,
      _HistoryFilter.text => !containsMath,
      _HistoryFilter.math => containsMath,
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

  String _formatRecordDate(DateTime value) {
    final DateTime localDate = value.toLocal();
    final MaterialLocalizations localizations = MaterialLocalizations.of(
      context,
    );

    final String date = localizations.formatMediumDate(localDate);

    final String time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(localDate),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

    return '$date · $time';
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

  Future<T?> _showAnimatedDialog<T>({required WidgetBuilder builder}) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: const Color(0x66000000),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder:
          (
            BuildContext dialogContext,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return builder(dialogContext);
          },
      transitionBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final Animation<double> curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
              reverseCurve: Curves.easeInCubic,
            );

            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.92,
                  end: 1,
                ).animate(curvedAnimation),
                child: child,
              ),
            );
          },
    );
  }

  Future<void> _renameRecord(HistoryRecord record) async {
    if (_isUpdating) {
      return;
    }

    final String? newTitle = await _showAnimatedDialog<String>(
      builder: (BuildContext dialogContext) {
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

  Future<void> _clearAllHistory() async {
    if (_records.isEmpty || _isUpdating) {
      return;
    }

    final bool confirmed = await _showConfirmationDialog(
      title: _HistoryText.clearAllDialogTitle,
      description: _HistoryText.clearAllDialogDescription,
      confirmationLabel: _HistoryText.confirmClearAllLabel,
    );

    if (!mounted || !confirmed) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final List<HistoryRecord> recordsToDelete = List<HistoryRecord>.from(
        _records,
      );

      for (final HistoryRecord record in recordsToDelete) {
        await _historyService.deleteHistory(record.id);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _records = <HistoryRecord>[];
        _isUpdating = false;
      });

      _showMessage(_HistoryText.clearAllSuccessMessage);
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
    final bool? confirmed = await _showAnimatedDialog<bool>(
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: HistoryScreenStyles.surfaceColor,
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
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD92D20),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: HistoryScreenStyles.backgroundColor,
        body: FadeTransition(
          opacity: _entranceOpacity,
          child: SlideTransition(
            position: _entrancePosition,
            child: RefreshIndicator(
              color: HistoryScreenStyles.primaryColor,
              backgroundColor: HistoryScreenStyles.surfaceColor,
              onRefresh: _refreshHistory,
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: <Widget>[
                  SliverToBoxAdapter(child: _buildHeader(context)),
                  SliverPadding(
                    padding: HistoryScreenStyles.contentPadding,
                    sliver: SliverList(
                      delegate: SliverChildListDelegate.fixed(<Widget>[
                        _buildHistoryToolbar(),
                        const SizedBox(
                          height: HistoryScreenStyles.sectionSpacing,
                        ),
                        _buildContent(),
                        const SizedBox(
                          height: HistoryScreenStyles.bottomSpacing,
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final double statusBarHeight = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        HistoryScreenStyles.headerHorizontalPadding,
        statusBarHeight + HistoryScreenStyles.headerTopPadding,
        HistoryScreenStyles.headerHorizontalPadding,
        HistoryScreenStyles.headerBottomPadding,
      ),
      decoration: const BoxDecoration(
        gradient: HistoryScreenStyles.headerGradient,
        borderRadius: HistoryScreenStyles.headerContainerRadius,
      ),
      child: Stack(
        children: <Widget>[
          const Positioned(
            right: HistoryScreenStyles.headerDecorationRight,
            top: HistoryScreenStyles.headerDecorationTop,
            child: _HistoryBrailleDecoration(),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                _HistoryText.screenTitle,
                style: HistoryScreenStyles.headerTitleStyle,
              ),
              const SizedBox(
                height: HistoryScreenStyles.headerDescriptionSpacing,
              ),
              const SizedBox(
                width: HistoryScreenStyles.headerDescriptionWidth,
                child: Text(
                  _HistoryText.screenDescription,
                  style: HistoryScreenStyles.headerDescriptionStyle,
                ),
              ),
              const SizedBox(height: HistoryScreenStyles.searchTopSpacing),
              _buildHeaderSearch(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSearch() {
    return SizedBox(
      height: HistoryScreenStyles.searchHeight,
      child: TextField(
        controller: _searchController,
        style: HistoryScreenStyles.searchTextStyle,
        textInputAction: TextInputAction.search,
        decoration: HistoryScreenStyles.searchDecoration.copyWith(
          hintText: _HistoryText.searchHint,
          suffixIcon: _searchController.text.isEmpty
              ? PopupMenuButton<_HistorySort>(
                  tooltip: _HistoryText.sortTooltip,
                  initialValue: _selectedSort,
                  padding: EdgeInsets.zero,
                  onSelected: (_HistorySort sort) {
                    setState(() {
                      _selectedSort = sort;
                    });
                  },
                  icon: const Icon(
                    HistoryScreenStyles.sortIcon,
                    color: HistoryScreenStyles.textMutedColor,
                    size: HistoryScreenStyles.searchSuffixIconSize,
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
                )
              : IconButton(
                  tooltip: _HistoryText.clearSearchTooltip,
                  onPressed: _searchController.clear,
                  icon: const Icon(
                    HistoryScreenStyles.clearSearchIcon,
                    color: HistoryScreenStyles.textMutedColor,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHistoryToolbar() {
    final bool canClearHistory = _records.isNotEmpty && !_isUpdating;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(child: _buildFilters()),
        const SizedBox(width: 8),
        Tooltip(
          message: _HistoryText.clearAllTooltip,
          child: TextButton.icon(
            onPressed: canClearHistory ? _clearAllHistory : null,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD92D20),
              disabledForegroundColor: const Color(0x66728096),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.delete_sweep_outlined, size: 18),
            label: const Text(_HistoryText.clearAllLabel),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    const List<_HistoryFilter> visibleFilters = <_HistoryFilter>[
      _HistoryFilter.all,
      _HistoryFilter.text,
      _HistoryFilter.math,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List<Widget>.generate(visibleFilters.length, (int index) {
          final _HistoryFilter filter = visibleFilters[index];

          final String label = switch (filter) {
            _HistoryFilter.all => _HistoryText.allFilterLabel,
            _HistoryFilter.text => _HistoryText.textFilterLabel,
            _HistoryFilter.math => _HistoryText.mathFilterLabel,
          };

          return Padding(
            padding: EdgeInsets.only(
              right: index == visibleFilters.length - 1
                  ? 0
                  : HistoryScreenStyles.filterSpacing,
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
        }, growable: false),
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
                          formattedDate: _formatRecordDate(record.createdAt),
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

class _HistoryBrailleDecoration extends StatelessWidget {
  const _HistoryBrailleDecoration();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: HistoryScreenStyles.headerDecorationOpacity,
      child: SizedBox(
        width: HistoryScreenStyles.headerDecorationWidth,
        child: Wrap(
          spacing: HistoryScreenStyles.headerDotSpacing,
          runSpacing: HistoryScreenStyles.headerDotSpacing,
          children: List<Widget>.generate(
            HistoryScreenStyles.headerDotCount,
            (_) => Container(
              width: HistoryScreenStyles.headerDotSize,
              height: HistoryScreenStyles.headerDotSize,
              decoration: const BoxDecoration(
                color: HistoryScreenStyles.surfaceColor,
                shape: BoxShape.circle,
              ),
            ),
            growable: false,
          ),
        ),
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
    required this.formattedDate,
    required this.onView,
    required this.onRename,
    required this.onDelete,
  });

  final HistoryRecord record;
  final String badge;
  final String brailleCode;
  final String formattedDate;

  final VoidCallback onView;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  bool get _hasVisibleBraille {
    return record.brailleContent.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HistoryScreenStyles.cardBackgroundColor,
      borderRadius: HistoryScreenStyles.cardRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onView,
        borderRadius: HistoryScreenStyles.cardRadius,
        child: Container(
          padding: HistoryScreenStyles.cardPadding,
          decoration: const BoxDecoration(
            borderRadius: HistoryScreenStyles.cardRadius,
            border: HistoryScreenStyles.cardBorder,
            boxShadow: HistoryScreenStyles.cardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _HistoryThumbnail(
                imagePath: record.sourceImagePath,
                recognizedContent: record.recognizedContent,
              ),
              const SizedBox(width: HistoryScreenStyles.cardContentSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      record.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HistoryScreenStyles.cardTitleStyle,
                    ),
                    const SizedBox(
                      height: HistoryScreenStyles.cardMetadataSpacing,
                    ),
                    Text(
                      '$badge · $brailleCode',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HistoryScreenStyles.cardMetadataStyle,
                    ),
                    const SizedBox(height: HistoryScreenStyles.cardDateSpacing),
                    Text(
                      formattedDate,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HistoryScreenStyles.cardDateStyle,
                    ),
                    const SizedBox(
                      height: HistoryScreenStyles.braillePreviewSpacing,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HistoryScreenStyles.brailleUnavailableStyle,
                      ),
                  ],
                ),
              ),
              PopupMenuButton<_HistoryAction>(
                tooltip: _HistoryText.moreActionsTooltip,
                padding: EdgeInsets.zero,
                color: HistoryScreenStyles.surfaceColor,
                elevation: 8,
                position: PopupMenuPosition.under,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(
                    color: HistoryScreenStyles.outlineColor,
                  ),
                ),
                onSelected: (_HistoryAction action) {
                  switch (action) {
                    case _HistoryAction.rename:
                      onRename();

                    case _HistoryAction.delete:
                      onDelete();
                  }
                },
                icon: const Icon(
                  HistoryScreenStyles.moreActionsIcon,
                  color: HistoryScreenStyles.textMutedColor,
                  size: HistoryScreenStyles.moreActionIconSize,
                ),
                itemBuilder: (BuildContext context) {
                  return const <PopupMenuEntry<_HistoryAction>>[
                    PopupMenuItem<_HistoryAction>(
                      value: _HistoryAction.rename,
                      child: Row(
                        children: <Widget>[
                          Icon(
                            HistoryScreenStyles.renameIcon,
                            color: HistoryScreenStyles.textSecondaryColor,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text(_HistoryText.renameLabel),
                        ],
                      ),
                    ),
                    PopupMenuItem<_HistoryAction>(
                      value: _HistoryAction.delete,
                      child: Row(
                        children: <Widget>[
                          Icon(
                            HistoryScreenStyles.deleteIcon,
                            color: Color(0xFFD92D20),
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text(
                            _HistoryText.deleteLabel,
                            style: TextStyle(color: Color(0xFFD92D20)),
                          ),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryThumbnail extends StatelessWidget {
  const _HistoryThumbnail({
    required this.imagePath,
    required this.recognizedContent,
  });

  final String? imagePath;
  final String recognizedContent;

  @override
  Widget build(BuildContext context) {
    final String normalizedPath = imagePath?.trim() ?? '';
    final File imageFile = File(normalizedPath);

    return Container(
      width: HistoryScreenStyles.previewWidth,
      height: HistoryScreenStyles.previewHeight,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: HistoryScreenStyles.previewBackgroundColor,
        borderRadius: HistoryScreenStyles.previewRadius,
        border: HistoryScreenStyles.previewBorder,
      ),
      child: normalizedPath.isNotEmpty && imageFile.existsSync()
          ? Image.file(
              imageFile,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stackTrace) {
                    return _buildFallback();
                  },
            )
          : _buildFallback(),
    );
  }

  Widget _buildFallback() {
    final String content = recognizedContent.trim();

    return Padding(
      padding: HistoryScreenStyles.previewPadding,
      child: Text(
        content.isEmpty ? _HistoryText.emptyRecognizedContent : content,
        maxLines: HistoryScreenStyles.previewMaximumLines,
        overflow: TextOverflow.ellipsis,
        style: HistoryScreenStyles.previewTextStyle,
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
