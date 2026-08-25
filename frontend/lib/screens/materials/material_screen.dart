import 'package:flutter/material.dart';

import '../../models/materials/material_model.dart';
import '../../services/materials/material_service.dart';
import '../../styles/screens/materials/material_screen_styles.dart';
import '../../widgets/app_header.dart';
import '../../widgets/materials/materials_empty_state.dart';
import 'material_detail_screen.dart';

enum _MaterialFilter { all, text, math, ueb, nemeth }

enum _MaterialSort { newest, oldest, title }

enum _MaterialMenuAction { preview, delete }

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<MaterialsScreen> createState() {
    return _MaterialsScreenState();
  }
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final MaterialService _materialService = MaterialService();
  final TextEditingController _searchController = TextEditingController();

  List<MaterialModel> _materials = <MaterialModel>[];

  _MaterialFilter _selectedFilter = _MaterialFilter.all;
  _MaterialSort _selectedSort = _MaterialSort.newest;

  bool _isLoading = true;
  bool _isDeleting = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_handleSearchChanged);
    _loadMaterials();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();

    _materialService.dispose();

    super.dispose();
  }

  void _handleSearchChanged() {
    setState(() {});
  }

  bool _containsMath(MaterialModel material) {
    final String content = material.recognizedContent.toLowerCase();

    return content.contains(r'\frac') ||
        content.contains(r'\sqrt') ||
        content.contains(r'\sum') ||
        content.contains(r'\int') ||
        content.contains('=') ||
        content.contains('^') ||
        RegExp(r'\d+\s*[+\-*/]\s*\d+').hasMatch(content);
  }

  bool _hasBraille(MaterialModel material) {
    return material.brailleContent.trim().isNotEmpty;
  }

  bool _matchesSelectedFilter(MaterialModel material) {
    final bool containsMath = _containsMath(material);
    final bool hasBraille = _hasBraille(material);

    return switch (_selectedFilter) {
      _MaterialFilter.all => true,
      _MaterialFilter.text => !containsMath,
      _MaterialFilter.math => containsMath,
      _MaterialFilter.ueb => !containsMath && hasBraille,
      _MaterialFilter.nemeth => containsMath && hasBraille,
    };
  }

  List<MaterialModel> get _visibleMaterials {
    final String query = _searchController.text.trim().toLowerCase();

    final List<MaterialModel> filtered = _materials
        .where((MaterialModel material) {
          if (!_matchesSelectedFilter(material)) {
            return false;
          }

          if (query.isEmpty) {
            return true;
          }

          return material.title.toLowerCase().contains(query) ||
              material.subject.toLowerCase().contains(query) ||
              material.description.toLowerCase().contains(query) ||
              material.recognizedContent.toLowerCase().contains(query) ||
              material.fileName.toLowerCase().contains(query);
        })
        .toList(growable: false);

    switch (_selectedSort) {
      case _MaterialSort.newest:
        filtered.sort((MaterialModel first, MaterialModel second) {
          return second.uploadDate.compareTo(first.uploadDate);
        });

      case _MaterialSort.oldest:
        filtered.sort((MaterialModel first, MaterialModel second) {
          return first.uploadDate.compareTo(second.uploadDate);
        });

      case _MaterialSort.title:
        filtered.sort((MaterialModel first, MaterialModel second) {
          return first.title.toLowerCase().compareTo(
            second.title.toLowerCase(),
          );
        });
    }

    return filtered;
  }

  List<_SubjectFolder> get _subjectFolders {
    final Map<String, int> counts = <String, int>{};

    for (final MaterialModel material in _materials) {
      final String subject = material.subject.trim();

      if (subject.isEmpty) {
        continue;
      }

      counts.update(subject, (int count) => count + 1, ifAbsent: () => 1);
    }

    final List<MapEntry<String, int>> entries = counts.entries.toList()
      ..sort((MapEntry<String, int> first, MapEntry<String, int> second) {
        final int countComparison = second.value.compareTo(first.value);

        if (countComparison != 0) {
          return countComparison;
        }

        return first.key.toLowerCase().compareTo(second.key.toLowerCase());
      });

    return entries
        .take(MaterialScreenStyles.maximumVisibleFolders)
        .map(
          (MapEntry<String, int> entry) =>
              _SubjectFolder(name: entry.key, itemCount: entry.value),
        )
        .toList(growable: false);
  }

  Future<void> _loadMaterials() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<MaterialModel> materials = await _materialService
          .getMaterials();

      if (!mounted) {
        return;
      }

      setState(() {
        _materials = materials;
        _isLoading = false;
      });
    } on MaterialServiceException catch (error) {
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
        _errorMessage = MaterialScreenStyles.errorDescription;
      });
    }
  }

  Future<void> _refreshMaterials() async {
    try {
      final List<MaterialModel> materials = await _materialService
          .getMaterials();

      if (!mounted) {
        return;
      }

      setState(() {
        _materials = materials;
        _errorMessage = null;
      });
    } on MaterialServiceException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showMessage(MaterialScreenStyles.errorDescription);
      }
    }
  }

  Future<void> _openMaterialPreview(MaterialModel material) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return MaterialDetailScreen(material: material);
        },
      ),
    );

    if (mounted) {
      await _refreshMaterials();
    }
  }

  Future<void> _requestDelete(MaterialModel material) async {
    if (material.id == null || _isDeleting) {
      return;
    }

    final bool confirmed = await _showDeleteConfirmation();

    if (!mounted || !confirmed) {
      return;
    }

    await _deleteMaterial(material.id!);
  }

  Future<bool> _showDeleteConfirmation() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: MaterialScreenStyles.surfaceColor,
          shape: const RoundedRectangleBorder(
            borderRadius: MaterialScreenStyles.dialogRadius,
            side: BorderSide(color: MaterialScreenStyles.outlineColor),
          ),
          title: const Text(
            MaterialScreenStyles.deleteDialogTitle,
            style: MaterialScreenStyles.dialogTitleStyle,
          ),
          content: const Text(
            MaterialScreenStyles.deleteDialogDescription,
            style: MaterialScreenStyles.dialogDescriptionStyle,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(MaterialScreenStyles.cancelLabel),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: MaterialScreenStyles.deleteButtonStyle,
              icon: const Icon(
                MaterialScreenStyles.deleteIcon,
                size: MaterialScreenStyles.dialogButtonIconSize,
              ),
              label: const Text(MaterialScreenStyles.deleteLabel),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Future<void> _deleteMaterial(int id) async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await _materialService.deleteMaterial(id);

      if (!mounted) {
        return;
      }

      setState(() {
        _materials = _materials
            .where((MaterialModel material) => material.id != id)
            .toList(growable: false);
        _isDeleting = false;
      });

      _showMessage(MaterialScreenStyles.deleteSuccessMessage);
    } on MaterialServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isDeleting = false;
      });

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isDeleting = false;
      });

      _showMessage(MaterialScreenStyles.deleteFailureMessage);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: MaterialScreenStyles.snackBarDuration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: MaterialScreenStyles.primaryColor,
          content: Text(message),
        ),
      );
  }

  void _selectFolder(String subject) {
    _searchController.text = subject;
    _searchController.selection = TextSelection.collapsed(
      offset: subject.length,
    );
  }

  String _formatMaterialType(MaterialModel material) {
    if (_containsMath(material)) {
      return MaterialScreenStyles.mathNemethLabel;
    }

    return MaterialScreenStyles.textUebLabel;
  }

  String _formatDateTime(BuildContext context, DateTime value) {
    final DateTime localDate = value.toLocal();
    final MaterialLocalizations localizations = MaterialLocalizations.of(
      context,
    );

    final String date = localizations.formatMediumDate(localDate);
    final String time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(localDate),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

    return '$date, $time';
  }

  String _materialTitle(MaterialModel material) {
    final String title = material.title.trim();

    return title.isEmpty ? material.fileName : title;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: MaterialScreenStyles.backgroundColor,
      body: Column(
        children: <Widget>[
          const AppHeader(),
          Expanded(
            child: RefreshIndicator(
              color: MaterialScreenStyles.primaryColor,
              onRefresh: _refreshMaterials,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: MaterialScreenStyles.contentPadding,
                children: <Widget>[
                  const Text(
                    MaterialScreenStyles.pageTitle,
                    style: MaterialScreenStyles.pageTitleStyle,
                  ),
                  const SizedBox(height: MaterialScreenStyles.searchTopSpacing),
                  _buildSearchAndSort(),
                  const SizedBox(height: MaterialScreenStyles.filterTopSpacing),
                  _buildFilters(),
                  const SizedBox(height: MaterialScreenStyles.sectionSpacing),
                  _buildFoldersSection(),
                  const SizedBox(height: MaterialScreenStyles.sectionSpacing),
                  _buildRecentHeader(),
                  const SizedBox(
                    height: MaterialScreenStyles.sectionContentSpacing,
                  ),
                  _buildContent(),
                  const SizedBox(height: MaterialScreenStyles.bottomSpacing),
                ],
              ),
            ),
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
            height: MaterialScreenStyles.searchHeight,
            child: TextField(
              controller: _searchController,
              style: MaterialScreenStyles.searchTextStyle,
              decoration: MaterialScreenStyles.searchDecoration.copyWith(
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: MaterialScreenStyles.clearSearchTooltip,
                        onPressed: _searchController.clear,
                        icon: const Icon(MaterialScreenStyles.clearSearchIcon),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(width: MaterialScreenStyles.sortButtonSpacing),
        PopupMenuButton<_MaterialSort>(
          tooltip: MaterialScreenStyles.sortTooltip,
          initialValue: _selectedSort,
          onSelected: (_MaterialSort value) {
            setState(() {
              _selectedSort = value;
            });
          },
          icon: const Icon(
            MaterialScreenStyles.sortIcon,
            color: MaterialScreenStyles.textMutedColor,
          ),
          itemBuilder: (BuildContext context) {
            return const <PopupMenuEntry<_MaterialSort>>[
              PopupMenuItem<_MaterialSort>(
                value: _MaterialSort.newest,
                child: Text(MaterialScreenStyles.newestSortLabel),
              ),
              PopupMenuItem<_MaterialSort>(
                value: _MaterialSort.oldest,
                child: Text(MaterialScreenStyles.oldestSortLabel),
              ),
              PopupMenuItem<_MaterialSort>(
                value: _MaterialSort.title,
                child: Text(MaterialScreenStyles.titleSortLabel),
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
        children: _MaterialFilter.values
            .map((_MaterialFilter filter) {
              final bool isSelected = filter == _selectedFilter;

              return Padding(
                padding: const EdgeInsets.only(
                  right: MaterialScreenStyles.filterSpacing,
                ),
                child: _FilterButton(
                  label: switch (filter) {
                    _MaterialFilter.all => MaterialScreenStyles.allFilterLabel,
                    _MaterialFilter.text =>
                      MaterialScreenStyles.textFilterLabel,
                    _MaterialFilter.math =>
                      MaterialScreenStyles.mathFilterLabel,
                    _MaterialFilter.ueb => MaterialScreenStyles.uebFilterLabel,
                    _MaterialFilter.nemeth =>
                      MaterialScreenStyles.nemethFilterLabel,
                  },
                  isSelected: isSelected,
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

  Widget _buildFoldersSection() {
    final List<_SubjectFolder> folders = _subjectFolders;

    if (_isLoading || folders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          MaterialScreenStyles.foldersTitle,
          style: MaterialScreenStyles.sectionTitleStyle,
        ),
        const SizedBox(height: MaterialScreenStyles.sectionContentSpacing),
        SizedBox(
          height: MaterialScreenStyles.folderCardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: folders.length,
            separatorBuilder: (BuildContext context, int index) {
              return const SizedBox(width: MaterialScreenStyles.folderSpacing);
            },
            itemBuilder: (BuildContext context, int index) {
              final _SubjectFolder folder = folders[index];

              return _FolderCard(
                folder: folder,
                index: index,
                onPressed: () {
                  _selectFolder(folder.name);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentHeader() {
    return Row(
      children: <Widget>[
        const Expanded(
          child: Text(
            MaterialScreenStyles.recentMaterialsTitle,
            style: MaterialScreenStyles.sectionTitleStyle,
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _selectedFilter = _MaterialFilter.all;
              _searchController.clear();
            });
          },
          style: MaterialScreenStyles.viewAllButtonStyle,
          child: const Text(MaterialScreenStyles.viewAllLabel),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const _MaterialStateView(
        icon: MaterialScreenStyles.folderIcon,
        title: MaterialScreenStyles.loadingLabel,
        showProgressIndicator: true,
      );
    }

    if (_errorMessage != null) {
      return _MaterialStateView(
        icon: MaterialScreenStyles.errorIcon,
        title: MaterialScreenStyles.errorTitle,
        description: _errorMessage,
        actionLabel: MaterialScreenStyles.retryLabel,
        onActionPressed: _loadMaterials,
      );
    }

    if (_materials.isEmpty) {
      return const MaterialsEmptyState();
    }

    final List<MaterialModel> materials = _visibleMaterials;

    if (materials.isEmpty) {
      return const _MaterialStateView(
        icon: MaterialScreenStyles.emptySearchIcon,
        title: MaterialScreenStyles.emptySearchTitle,
        description: MaterialScreenStyles.emptySearchDescription,
      );
    }

    return Column(
      children: List<Widget>.generate(materials.length, (int index) {
        final MaterialModel material = materials[index];

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == materials.length - 1
                ? 0
                : MaterialScreenStyles.materialCardSpacing,
          ),
          child: _RecentMaterialCard(
            title: _materialTitle(material),
            category: _formatMaterialType(material),
            date: _formatDateTime(context, material.uploadDate),
            isImage: _isImageMaterial(material),
            onPressed: () {
              _openMaterialPreview(material);
            },
            onMenuSelected: (_MaterialMenuAction action) {
              switch (action) {
                case _MaterialMenuAction.preview:
                  _openMaterialPreview(material);

                case _MaterialMenuAction.delete:
                  _requestDelete(material);
              }
            },
          ),
        );
      }, growable: false),
    );
  }

  bool _isImageMaterial(MaterialModel material) {
    final String type = material.fileType.toLowerCase();

    return type.contains('image') ||
        type.contains('jpg') ||
        type.contains('jpeg') ||
        type.contains('png');
  }
}

class _SubjectFolder {
  const _SubjectFolder({required this.name, required this.itemCount});

  final String name;
  final int itemCount;
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
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
          ? MaterialScreenStyles.primaryColor
          : MaterialScreenStyles.filterBackgroundColor,
      borderRadius: MaterialScreenStyles.filterRadius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: MaterialScreenStyles.filterRadius,
        child: Container(
          height: MaterialScreenStyles.filterHeight,
          padding: MaterialScreenStyles.filterPadding,
          alignment: Alignment.center,
          child: Text(
            label,
            style: isSelected
                ? MaterialScreenStyles.selectedFilterTextStyle
                : MaterialScreenStyles.filterTextStyle,
          ),
        ),
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.folder,
    required this.index,
    required this.onPressed,
  });

  final _SubjectFolder folder;
  final int index;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bool highlighted = index > 0;

    return Material(
      color: highlighted
          ? MaterialScreenStyles.blueFolderBackgroundColor
          : MaterialScreenStyles.yellowFolderBackgroundColor,
      borderRadius: MaterialScreenStyles.folderRadius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: MaterialScreenStyles.folderRadius,
        child: Container(
          width: MaterialScreenStyles.folderCardWidth,
          padding: MaterialScreenStyles.folderPadding,
          decoration: BoxDecoration(
            borderRadius: MaterialScreenStyles.folderRadius,
            border: Border.all(
              color: highlighted
                  ? MaterialScreenStyles.blueFolderOutlineColor
                  : MaterialScreenStyles.yellowFolderOutlineColor,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                MaterialScreenStyles.folderIcon,
                size: MaterialScreenStyles.folderIconSize,
                color: highlighted
                    ? MaterialScreenStyles.primaryBrightColor
                    : MaterialScreenStyles.yellowFolderColor,
              ),
              const SizedBox(height: MaterialScreenStyles.folderIconSpacing),
              Text(
                folder.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: MaterialScreenStyles.folderTitleStyle,
              ),
              const SizedBox(height: MaterialScreenStyles.folderCountSpacing),
              Text(
                '${folder.itemCount} '
                '${folder.itemCount == 1 ? MaterialScreenStyles.itemSingular : MaterialScreenStyles.itemPlural}',
                style: MaterialScreenStyles.folderCountStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentMaterialCard extends StatelessWidget {
  const _RecentMaterialCard({
    required this.title,
    required this.category,
    required this.date,
    required this.isImage,
    required this.onPressed,
    required this.onMenuSelected,
  });

  final String title;
  final String category;
  final String date;
  final bool isImage;
  final VoidCallback onPressed;
  final ValueChanged<_MaterialMenuAction> onMenuSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MaterialScreenStyles.recentCardBackgroundColor,
      borderRadius: MaterialScreenStyles.materialCardRadius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: MaterialScreenStyles.materialCardRadius,
        child: Container(
          padding: MaterialScreenStyles.materialCardPadding,
          decoration: const BoxDecoration(
            borderRadius: MaterialScreenStyles.materialCardRadius,
            border: MaterialScreenStyles.cardBorder,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: MaterialScreenStyles.thumbnailWidth,
                height: MaterialScreenStyles.thumbnailHeight,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: MaterialScreenStyles.thumbnailBackgroundColor,
                  borderRadius: MaterialScreenStyles.thumbnailRadius,
                ),
                child: Icon(
                  isImage
                      ? MaterialScreenStyles.imageIcon
                      : MaterialScreenStyles.documentIcon,
                  color: MaterialScreenStyles.primaryBrightColor,
                  size: MaterialScreenStyles.thumbnailIconSize,
                ),
              ),
              const SizedBox(
                width: MaterialScreenStyles.materialContentSpacing,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MaterialScreenStyles.materialTitleStyle,
                    ),
                    const SizedBox(
                      height: MaterialScreenStyles.categorySpacing,
                    ),
                    Container(
                      padding: MaterialScreenStyles.categoryPadding,
                      decoration: const BoxDecoration(
                        color: MaterialScreenStyles.primaryColor,
                        borderRadius: MaterialScreenStyles.categoryRadius,
                      ),
                      child: Text(
                        category,
                        style: MaterialScreenStyles.categoryStyle,
                      ),
                    ),
                    const SizedBox(
                      height: MaterialScreenStyles.metadataSpacing,
                    ),
                    Text(
                      date,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MaterialScreenStyles.metadataStyle,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_MaterialMenuAction>(
                tooltip: MaterialScreenStyles.materialOptionsTooltip,
                onSelected: onMenuSelected,
                icon: const Icon(
                  MaterialScreenStyles.moreIcon,
                  color: MaterialScreenStyles.textSecondaryColor,
                ),
                itemBuilder: (BuildContext context) {
                  return const <PopupMenuEntry<_MaterialMenuAction>>[
                    PopupMenuItem<_MaterialMenuAction>(
                      value: _MaterialMenuAction.preview,
                      child: ListTile(
                        leading: Icon(MaterialScreenStyles.previewIcon),
                        title: Text(MaterialScreenStyles.previewLabel),
                      ),
                    ),
                    PopupMenuItem<_MaterialMenuAction>(
                      value: _MaterialMenuAction.delete,
                      child: ListTile(
                        leading: Icon(
                          MaterialScreenStyles.deleteIcon,
                          color: MaterialScreenStyles.primaryColor,
                        ),
                        title: Text(MaterialScreenStyles.deleteLabel),
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

class _MaterialStateView extends StatelessWidget {
  const _MaterialStateView({
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
    return Container(
      width: double.infinity,
      padding: MaterialScreenStyles.statePadding,
      decoration: const BoxDecoration(
        color: MaterialScreenStyles.surfaceColor,
        borderRadius: MaterialScreenStyles.stateRadius,
        border: MaterialScreenStyles.cardBorder,
      ),
      child: Column(
        children: <Widget>[
          if (showProgressIndicator)
            const CircularProgressIndicator(
              color: MaterialScreenStyles.primaryColor,
            )
          else
            Icon(
              icon,
              size: MaterialScreenStyles.stateIconSize,
              color: MaterialScreenStyles.primaryColor,
            ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: MaterialScreenStyles.stateTitleStyle,
          ),
          if (description != null) ...<Widget>[
            const SizedBox(height: 7),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: MaterialScreenStyles.stateDescriptionStyle,
            ),
          ],
          if (actionLabel != null && onActionPressed != null) ...<Widget>[
            const SizedBox(height: 18),
            FilledButton(onPressed: onActionPressed, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
