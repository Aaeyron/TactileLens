import 'dart:io';
import 'package:flutter/material.dart';

import '../../models/materials/material_model.dart';
import '../../models/materials/material_folder_model.dart';
import '../../services/materials/material_service.dart';
import '../../services/materials/material_folder_service.dart';
import '../../styles/screens/materials/material_screen_styles.dart';
import '../../widgets/app_header.dart';
import '../../widgets/materials/materials_empty_state.dart';
import 'material_preview_screen.dart';

abstract final class _MaterialText {
  static const String pageTitle = 'Materials';
  static const String pageDescription =
      'View, organize, and manage your accessible learning materials.';
  static const String searchHint = 'Search Materials';

  static const String allFilterLabel = 'All';
  static const String imagesFilterLabel = 'Images';
  static const String pdfFilterLabel = 'PDF';
  static const String documentsFilterLabel = 'Documents';

  static const String foldersTitle = 'Folders';
  static const String noFoldersLabel = 'No folders created yet.';
  static const String folderEmptyTitle = 'This folder is empty';
  static const String folderEmptyDescription =
      'Move scanned materials into this folder to keep them organized.';
  static const String closeFolderTooltip = 'Close folder';
  static const String recentMaterialsTitle = 'Materials';
  static const String viewAllLabel = 'Clear filters';
  static const String itemSingular = 'Item';
  static const String itemPlural = 'Items';

  static const String mathNemethLabel = 'Math • Nemeth';
  static const String textUebLabel = 'Text • UEB';

  static const String loadingLabel = 'Loading your materials...';
  static const String errorTitle = 'Unable to load materials';
  static const String errorDescription = 'Check your connection and try again.';
  static const String emptySearchTitle = 'No matching materials';
  static const String emptySearchDescription =
      'Try another search term or material type.';
  static const String retryLabel = 'Try Again';

  static const String createFolderDialogTitle = 'Create Folder';
  static const String folderNameHint = 'Enter a folder name';
  static const String createFolderLabel = 'Create';
  static const String createFolderSuccessMessage =
      'Folder created successfully.';
  static const String createFolderFailureMessage =
      'Unable to create the folder.';

  static const String deleteDialogTitle = 'Delete Material';
  static const String deleteDialogDescription =
      'Are you sure you want to permanently delete this material? '
      'This action cannot be undone.';
  static const String cancelLabel = 'Cancel';
  static const String deleteLabel = 'Delete';
  static const String previewLabel = 'Preview';
  static const String deleteSuccessMessage = 'Material deleted successfully.';
  static const String deleteFailureMessage = 'Unable to delete the material.';

  static const String clearSearchTooltip = 'Clear material search';
  static const String sortTooltip = 'Sort materials';
  static const String materialOptionsTooltip = 'Material options';
  static const String newestSortLabel = 'Newest first';
  static const String oldestSortLabel = 'Oldest first';
  static const String titleSortLabel = 'Title A–Z';

  static const String moveToFolderLabel = 'Move to folder';
  static const String moveDialogTitle = 'Move to Folder';

  static const String moveDialogDescription =
      'Choose where you want to organize this material.';

  static const String unfiledLabel = 'Unfiled';
  static const String unfiledDescription = 'Keep this material outside folders';

  static const String moveLabel = 'Move';

  static const String moveSuccessMessage = 'Material moved successfully.';

  static const String removeFromFolderSuccessMessage =
      'Material removed from the folder.';

  static const String moveFailureMessage = 'Unable to move the material.';

  static const String noFoldersAvailableMessage =
      'Create a folder first before organizing this material.';
}

enum _MaterialFilter { all, images, pdf, documents }

enum _MaterialSort { newest, oldest, title }

enum _MaterialMenuAction { preview, moveToFolder, delete }

class _FolderSelectionResult {
  const _FolderSelectionResult({required this.folderId});

  final int? folderId;
}

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<MaterialsScreen> createState() {
    return _MaterialsScreenState();
  }
}

class _MaterialsScreenState extends State<MaterialsScreen>
    with SingleTickerProviderStateMixin {
  final MaterialService _materialService = MaterialService();
  final MaterialFolderService _folderService = MaterialFolderService();
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  final TextEditingController _searchController = TextEditingController();

  List<MaterialModel> _materials = <MaterialModel>[];
  List<MaterialFolderModel> _folders = <MaterialFolderModel>[];

  _MaterialFilter _selectedFilter = _MaterialFilter.all;
  _MaterialSort _selectedSort = _MaterialSort.newest;

  bool _isLoading = true;
  bool _isDeleting = false;
  bool _isCreatingFolder = false;
  bool _isMovingMaterial = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _initializeEntranceAnimation();
    _searchController.addListener(_handleSearchChanged);
    _loadMaterials();
  }

  void _initializeEntranceAnimation() {
    _entranceController = AnimationController(
      vsync: this,
      duration: MaterialScreenStyles.entranceAnimationDuration,
    );

    final CurvedAnimation curve = CurvedAnimation(
      parent: _entranceController,
      curve: MaterialScreenStyles.entranceAnimationCurve,
    );

    _fadeAnimation = Tween<double>(
      begin: MaterialScreenStyles.entranceFadeBegin,
      end: MaterialScreenStyles.entranceFadeEnd,
    ).animate(curve);

    _slideAnimation = Tween<Offset>(
      begin: MaterialScreenStyles.entranceSlideBegin,
      end: Offset.zero,
    ).animate(curve);

    Future<void>.delayed(MaterialScreenStyles.entranceAnimationDelay, () {
      if (mounted) {
        _entranceController.forward();
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();

    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();

    _materialService.dispose();
    _folderService.dispose();

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

  bool _matchesSelectedFilter(MaterialModel material) {
    return switch (_selectedFilter) {
      _MaterialFilter.all => true,
      _MaterialFilter.images => _isImageMaterial(material),
      _MaterialFilter.pdf => _isPdfMaterial(material),
      _MaterialFilter.documents =>
        !_isImageMaterial(material) && !_isPdfMaterial(material),
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

  Future<void> _loadMaterials() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<MaterialModel> materials = await _materialService
          .getMaterials();

      final List<MaterialFolderModel> folders = await _folderService
          .getFolders();

      if (!mounted) {
        return;
      }

      setState(() {
        _materials = materials;
        _folders = folders;
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
    } on MaterialFolderServiceException catch (error) {
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
        _errorMessage = _MaterialText.errorDescription;
      });
    }
  }

  Future<void> _refreshMaterials() async {
    try {
      final List<MaterialModel> materials = await _materialService
          .getMaterials();

      final List<MaterialFolderModel> folders = await _folderService
          .getFolders();

      if (!mounted) {
        return;
      }

      setState(() {
        _materials = materials;
        _folders = folders;
        _errorMessage = null;
      });
    } on MaterialServiceException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } on MaterialFolderServiceException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showMessage(_MaterialText.errorDescription);
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
            _MaterialText.deleteDialogTitle,
            style: MaterialScreenStyles.dialogTitleStyle,
          ),
          content: const Text(
            _MaterialText.deleteDialogDescription,
            style: MaterialScreenStyles.dialogDescriptionStyle,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(_MaterialText.cancelLabel),
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
              label: const Text(_MaterialText.deleteLabel),
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

      await _refreshMaterials();

      if (!mounted) {
        return;
      }

      _showMessage(_MaterialText.deleteSuccessMessage);
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

      _showMessage(_MaterialText.deleteFailureMessage);
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

  List<MaterialModel> _materialsInsideFolder(int folderId) {
    final List<MaterialModel> folderMaterials = _materials
        .where((MaterialModel material) => material.folderId == folderId)
        .toList(growable: false);

    folderMaterials.sort((MaterialModel first, MaterialModel second) {
      return second.uploadDate.compareTo(first.uploadDate);
    });

    return folderMaterials;
  }

  Future<void> _handleMaterialMenuAction(
    MaterialModel material,
    _MaterialMenuAction action,
  ) async {
    switch (action) {
      case _MaterialMenuAction.preview:
        await _openMaterialPreview(material);

      case _MaterialMenuAction.moveToFolder:
        await _showMoveToFolderDialog(material);

      case _MaterialMenuAction.delete:
        await _requestDelete(material);
    }
  }

  Future<void> _closeFolderAndRunAction(
    BuildContext folderContext,
    Future<void> Function() action,
  ) async {
    Navigator.of(folderContext).pop();

    await Future<void>.delayed(MaterialScreenStyles.dialogAnimationDuration);

    if (!mounted) {
      return;
    }

    await action();
  }

  Future<void> _showFolderContents(MaterialFolderModel folder) async {
    final int? folderId = folder.id;

    if (folderId == null) {
      return;
    }

    final List<MaterialModel> folderMaterials = _materialsInsideFolder(
      folderId,
    );

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: MaterialScreenStyles.dialogBarrierColor,
      transitionDuration: MaterialScreenStyles.dialogAnimationDuration,
      pageBuilder:
          (
            BuildContext folderContext,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  widthFactor: 1,
                  heightFactor: 0.84,
                  child: Material(
                    color: MaterialScreenStyles.surfaceColor,
                    clipBehavior: Clip.antiAlias,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(26),
                      ),
                    ),
                    child: Column(
                      children: <Widget>[
                        const SizedBox(height: 10),
                        Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: MaterialScreenStyles.outlineColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 42,
                                height: 42,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF4D8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  MaterialScreenStyles.folderIcon,
                                  color:
                                      MaterialScreenStyles.folderSelectedColor,
                                  size: 27,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      folder.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: MaterialScreenStyles
                                          .materialTitleStyle,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${folderMaterials.length} '
                                      '${folderMaterials.length == 1 ? _MaterialText.itemSingular : _MaterialText.itemPlural}',
                                      style: MaterialScreenStyles.metadataStyle,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: _MaterialText.closeFolderTooltip,
                                onPressed: () {
                                  Navigator.of(folderContext).pop();
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: folderMaterials.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 32),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Icon(
                                          Icons.folder_open_rounded,
                                          size: 54,
                                          color:
                                              MaterialScreenStyles.folderColor,
                                        ),
                                        SizedBox(height: 14),
                                        Text(
                                          _MaterialText.folderEmptyTitle,
                                          textAlign: TextAlign.center,
                                          style: MaterialScreenStyles
                                              .stateTitleStyle,
                                        ),
                                        SizedBox(height: 7),
                                        Text(
                                          _MaterialText.folderEmptyDescription,
                                          textAlign: TextAlign.center,
                                          style: MaterialScreenStyles
                                              .stateDescriptionStyle,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    18,
                                    16,
                                    30,
                                  ),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: folderMaterials.length,
                                  separatorBuilder:
                                      (BuildContext context, int index) {
                                        return const SizedBox(
                                          height: MaterialScreenStyles
                                              .materialCardSpacing,
                                        );
                                      },
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                        final MaterialModel material =
                                            folderMaterials[index];

                                        return _RecentMaterialCard(
                                          title: _materialTitle(material),
                                          category: _formatMaterialType(
                                            material,
                                          ),
                                          date: _formatDateTime(
                                            context,
                                            material.uploadDate,
                                          ),
                                          isImage: _isImageMaterial(material),
                                          filePath: material.filePath,
                                          fileUrl: _materialService.getFileUrl(
                                            material.filePath,
                                          ),
                                          onPressed: () async {
                                            await _closeFolderAndRunAction(
                                              folderContext,
                                              () => _openMaterialPreview(
                                                material,
                                              ),
                                            );
                                          },
                                          onMenuSelected:
                                              (
                                                _MaterialMenuAction action,
                                              ) async {
                                                await _closeFolderAndRunAction(
                                                  folderContext,
                                                  () =>
                                                      _handleMaterialMenuAction(
                                                        material,
                                                        action,
                                                      ),
                                                );
                                              },
                                        );
                                      },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
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
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            final Animation<Offset> slideAnimation = Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curvedAnimation);

            return FadeTransition(
              opacity: curvedAnimation,
              child: SlideTransition(position: slideAnimation, child: child),
            );
          },
    );
  }

  Future<void> _showMoveToFolderDialog(MaterialModel material) async {
    final int? materialId = material.id;

    if (materialId == null || _isMovingMaterial) {
      return;
    }

    final List<MaterialFolderModel> availableFolders = _folders
        .where((MaterialFolderModel folder) => folder.id != null)
        .toList(growable: false);

    if (availableFolders.isEmpty && material.folderId == null) {
      _showMessage(_MaterialText.noFoldersAvailableMessage);
      return;
    }

    int? selectedFolderId = material.folderId;

    final _FolderSelectionResult?
    result = await showGeneralDialog<_FolderSelectionResult>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: MaterialScreenStyles.dialogBarrierColor,
      transitionDuration: MaterialScreenStyles.dialogAnimationDuration,
      pageBuilder:
          (
            BuildContext dialogContext,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setDialogState) {
                final int optionCount = availableFolders.length + 1;

                return AlertDialog(
                  backgroundColor: MaterialScreenStyles.surfaceColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius: MaterialScreenStyles.dialogRadius,
                    side: BorderSide(color: MaterialScreenStyles.outlineColor),
                  ),
                  title: const Text(
                    _MaterialText.moveDialogTitle,
                    style: MaterialScreenStyles.dialogTitleStyle,
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          _MaterialText.moveDialogDescription,
                          style: MaterialScreenStyles.dialogDescriptionStyle,
                        ),
                        const SizedBox(
                          height: MaterialScreenStyles
                              .folderPickerDescriptionSpacing,
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight:
                                MaterialScreenStyles.folderPickerMaximumHeight,
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: optionCount,
                            separatorBuilder:
                                (BuildContext context, int index) {
                                  return const SizedBox(
                                    height: MaterialScreenStyles
                                        .folderPickerOptionSpacing,
                                  );
                                },
                            itemBuilder: (BuildContext context, int index) {
                              final bool isUnfiled = index == 0;

                              final int? folderId = isUnfiled
                                  ? null
                                  : availableFolders[index - 1].id;

                              final String title = isUnfiled
                                  ? _MaterialText.unfiledLabel
                                  : availableFolders[index - 1].name;

                              final bool isSelected =
                                  selectedFolderId == folderId;

                              return Material(
                                color: isSelected
                                    ? MaterialScreenStyles
                                          .folderPickerSelectedColor
                                    : MaterialScreenStyles
                                          .folderPickerBackgroundColor,
                                borderRadius: MaterialScreenStyles
                                    .folderPickerOptionRadius,
                                child: InkWell(
                                  onTap: () {
                                    setDialogState(() {
                                      selectedFolderId = folderId;
                                    });
                                  },
                                  borderRadius: MaterialScreenStyles
                                      .folderPickerOptionRadius,
                                  child: Container(
                                    padding: MaterialScreenStyles
                                        .folderPickerOptionPadding,
                                    decoration: BoxDecoration(
                                      borderRadius: MaterialScreenStyles
                                          .folderPickerOptionRadius,
                                      border: Border.all(
                                        color: isSelected
                                            ? MaterialScreenStyles.primaryColor
                                            : MaterialScreenStyles.outlineColor,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Icon(
                                          isUnfiled
                                              ? MaterialScreenStyles.unfiledIcon
                                              : MaterialScreenStyles.folderIcon,
                                          color: isSelected
                                              ? MaterialScreenStyles
                                                    .primaryColor
                                              : MaterialScreenStyles
                                                    .folderColor,
                                        ),
                                        const SizedBox(
                                          width: MaterialScreenStyles
                                              .folderPickerIconSpacing,
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: MaterialScreenStyles
                                                    .folderPickerTitleStyle,
                                              ),
                                              if (isUnfiled)
                                                const Text(
                                                  _MaterialText
                                                      .unfiledDescription,
                                                  style: MaterialScreenStyles
                                                      .folderPickerDescriptionStyle,
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(
                                            MaterialScreenStyles
                                                .selectedFolderIcon,
                                            color: MaterialScreenStyles
                                                .primaryColor,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      child: const Text(_MaterialText.cancelLabel),
                    ),
                    FilledButton(
                      style: MaterialScreenStyles.createFolderButtonStyle,
                      onPressed: () {
                        Navigator.of(dialogContext).pop(
                          _FolderSelectionResult(folderId: selectedFolderId),
                        );
                      },
                      child: const Text(_MaterialText.moveLabel),
                    ),
                  ],
                );
              },
            );
          },
      transitionBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final CurvedAnimation curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: MaterialScreenStyles.dialogEntranceCurve,
              reverseCurve: MaterialScreenStyles.dialogExitCurve,
            );

            final Animation<double> scaleAnimation = Tween<double>(
              begin: MaterialScreenStyles.dialogInitialScale,
              end: 1,
            ).animate(curvedAnimation);

            return FadeTransition(
              opacity: curvedAnimation,
              child: ScaleTransition(scale: scaleAnimation, child: child),
            );
          },
    );

    if (!mounted || result == null) {
      return;
    }

    if (result.folderId == material.folderId) {
      return;
    }

    await _moveMaterialToFolder(material: material, folderId: result.folderId);
  }

  Future<void> _moveMaterialToFolder({
    required MaterialModel material,
    required int? folderId,
  }) async {
    final int? materialId = material.id;

    if (materialId == null || _isMovingMaterial) {
      return;
    }

    setState(() {
      _isMovingMaterial = true;
    });

    try {
      final MaterialModel updatedMaterial = await _materialService
          .moveMaterialToFolder(materialId: materialId, folderId: folderId);

      final List<MaterialFolderModel> updatedFolders = await _folderService
          .getFolders();

      if (!mounted) {
        return;
      }

      setState(() {
        _materials = _materials
            .map((MaterialModel existing) {
              return existing.id == updatedMaterial.id
                  ? updatedMaterial
                  : existing;
            })
            .toList(growable: false);

        _folders = updatedFolders;
        _isMovingMaterial = false;
      });

      _showMessage(
        folderId == null
            ? _MaterialText.removeFromFolderSuccessMessage
            : _MaterialText.moveSuccessMessage,
      );
    } on MaterialServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isMovingMaterial = false;
      });

      _showMessage(error.message);
    } on MaterialFolderServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isMovingMaterial = false;
      });

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isMovingMaterial = false;
      });

      _showMessage(_MaterialText.moveFailureMessage);
    }
  }

  Future<void> _showCreateFolderDialog() async {
    if (_isCreatingFolder) {
      return;
    }

    String enteredFolderName = '';

    final String? folderName = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: MaterialScreenStyles.dialogBarrierColor,
      transitionDuration: MaterialScreenStyles.dialogAnimationDuration,
      pageBuilder:
          (
            BuildContext dialogContext,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return AlertDialog(
              backgroundColor: MaterialScreenStyles.surfaceColor,
              shape: const RoundedRectangleBorder(
                borderRadius: MaterialScreenStyles.dialogRadius,
                side: BorderSide(color: MaterialScreenStyles.outlineColor),
              ),
              title: const Text(
                _MaterialText.createFolderDialogTitle,
                style: MaterialScreenStyles.dialogTitleStyle,
              ),
              content: TextField(
                autofocus: true,
                maxLength: MaterialScreenStyles.maximumFolderNameLength,
                textCapitalization: TextCapitalization.words,
                decoration: MaterialScreenStyles.folderNameDecoration.copyWith(
                  hintText: _MaterialText.folderNameHint,
                ),
                onChanged: (String value) {
                  enteredFolderName = value;
                },
                onSubmitted: (String value) {
                  final String normalizedName = value.trim();

                  if (normalizedName.isEmpty) {
                    return;
                  }

                  Navigator.of(dialogContext).pop(normalizedName);
                },
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text(_MaterialText.cancelLabel),
                ),
                FilledButton(
                  style: MaterialScreenStyles.createFolderButtonStyle,
                  onPressed: () {
                    final String normalizedName = enteredFolderName.trim();

                    if (normalizedName.isEmpty) {
                      return;
                    }

                    Navigator.of(dialogContext).pop(normalizedName);
                  },
                  child: const Text(_MaterialText.createFolderLabel),
                ),
              ],
            );
          },
      transitionBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final CurvedAnimation curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: MaterialScreenStyles.dialogEntranceCurve,
              reverseCurve: MaterialScreenStyles.dialogExitCurve,
            );

            final Animation<double> scaleAnimation = Tween<double>(
              begin: MaterialScreenStyles.dialogInitialScale,
              end: 1,
            ).animate(curvedAnimation);

            return FadeTransition(
              opacity: curvedAnimation,
              child: ScaleTransition(scale: scaleAnimation, child: child),
            );
          },
    );

    if (!mounted || folderName == null || folderName.trim().isEmpty) {
      return;
    }

    await _createFolder(folderName);
  }

  Future<void> _createFolder(String name) async {
    setState(() {
      _isCreatingFolder = true;
    });

    try {
      final MaterialFolderModel folder = await _folderService.createFolder(
        name,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _folders = <MaterialFolderModel>[..._folders, folder]
          ..sort((MaterialFolderModel first, MaterialFolderModel second) {
            return first.name.toLowerCase().compareTo(
              second.name.toLowerCase(),
            );
          });

        _isCreatingFolder = false;
      });

      _showMessage(_MaterialText.createFolderSuccessMessage);
    } on MaterialFolderServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCreatingFolder = false;
      });

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCreatingFolder = false;
      });

      _showMessage(_MaterialText.createFolderFailureMessage);
    }
  }

  String _formatMaterialType(MaterialModel material) {
    if (_containsMath(material)) {
      return _MaterialText.mathNemethLabel;
    }

    return _MaterialText.textUebLabel;
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
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: RefreshIndicator(
                  color: MaterialScreenStyles.primaryColor,
                  onRefresh: _refreshMaterials,
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: MaterialScreenStyles.contentPadding,
                    children: <Widget>[
                      Container(
                        width: double.infinity,
                        padding: MaterialScreenStyles.pageHeaderPadding,
                        decoration: const BoxDecoration(
                          color: MaterialScreenStyles.pageHeaderBackgroundColor,
                          borderRadius: MaterialScreenStyles.pageHeaderRadius,
                          border: MaterialScreenStyles.pageHeaderBorder,
                          boxShadow: MaterialScreenStyles.pageHeaderShadow,
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _MaterialText.pageTitle,
                              style: MaterialScreenStyles.pageTitleStyle,
                            ),
                            SizedBox(
                              height:
                                  MaterialScreenStyles.pageDescriptionSpacing,
                            ),
                            Text(
                              _MaterialText.pageDescription,
                              style: MaterialScreenStyles.pageDescriptionStyle,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: MaterialScreenStyles.searchTopSpacing,
                      ),
                      _buildSearchAndSort(),
                      const SizedBox(
                        height: MaterialScreenStyles.filterTopSpacing,
                      ),
                      _buildFilters(),
                      const SizedBox(
                        height: MaterialScreenStyles.sectionSpacing,
                      ),
                      _buildFoldersSection(),
                      const SizedBox(
                        height: MaterialScreenStyles.sectionSpacing,
                      ),
                      _buildRecentHeader(),
                      const SizedBox(
                        height: MaterialScreenStyles.sectionContentSpacing,
                      ),
                      _buildContent(),
                      const SizedBox(
                        height: MaterialScreenStyles.bottomSpacing,
                      ),
                    ],
                  ),
                ),
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
                hintText: _MaterialText.searchHint,
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: _MaterialText.clearSearchTooltip,
                        onPressed: _searchController.clear,
                        icon: const Icon(MaterialScreenStyles.clearSearchIcon),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: MaterialScreenStyles.searchHeight,
          height: MaterialScreenStyles.searchHeight,
          decoration: BoxDecoration(
            color: MaterialScreenStyles.surfaceColor,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: MaterialScreenStyles.outlineColor,
              width: 1,
            ),
          ),
          child: PopupMenuButton<_MaterialSort>(
            tooltip: _MaterialText.sortTooltip,
            initialValue: _selectedSort,
            padding: EdgeInsets.zero,
            onSelected: (_MaterialSort value) {
              setState(() {
                _selectedSort = value;
              });
            },
            icon: const Icon(
              MaterialScreenStyles.sortIcon,
              color: MaterialScreenStyles.textSecondaryColor,
              size: 21,
            ),
            itemBuilder: (BuildContext context) {
              return const <PopupMenuEntry<_MaterialSort>>[
                PopupMenuItem<_MaterialSort>(
                  value: _MaterialSort.newest,
                  child: Text(_MaterialText.newestSortLabel),
                ),
                PopupMenuItem<_MaterialSort>(
                  value: _MaterialSort.oldest,
                  child: Text(_MaterialText.oldestSortLabel),
                ),
                PopupMenuItem<_MaterialSort>(
                  value: _MaterialSort.title,
                  child: Text(_MaterialText.titleSortLabel),
                ),
              ];
            },
          ),
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

              final String label = switch (filter) {
                _MaterialFilter.all => _MaterialText.allFilterLabel,
                _MaterialFilter.images => _MaterialText.imagesFilterLabel,
                _MaterialFilter.pdf => _MaterialText.pdfFilterLabel,
                _MaterialFilter.documents => _MaterialText.documentsFilterLabel,
              };

              return Padding(
                padding: const EdgeInsets.only(
                  right: MaterialScreenStyles.filterSpacing,
                ),
                child: _FilterButton(
                  label: label,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                _MaterialText.foldersTitle,
                style: MaterialScreenStyles.sectionTitleStyle,
              ),
            ),
            Tooltip(
              message: _MaterialText.createFolderDialogTitle,
              child: _isCreatingFolder
                  ? const SizedBox.square(
                      dimension: MaterialScreenStyles.addFolderButtonSize,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: MaterialScreenStyles.primaryColor,
                        ),
                      ),
                    )
                  : IconButton(
                      tooltip: _MaterialText.createFolderDialogTitle,
                      onPressed: _showCreateFolderDialog,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(
                        width: MaterialScreenStyles.addFolderButtonSize,
                        height: MaterialScreenStyles.addFolderButtonSize,
                      ),
                      icon: const Icon(
                        Icons.add_rounded,
                        size: MaterialScreenStyles.addFolderButtonIconSize,
                        color: MaterialScreenStyles.primaryColor,
                      ),
                    ),
            ),
          ],
        ),
        const SizedBox(
          height: MaterialScreenStyles.folderSectionContentSpacing,
        ),
        if (_folders.isEmpty)
          Container(
            width: double.infinity,
            height: MaterialScreenStyles.emptyFolderHeight,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: MaterialScreenStyles.surfaceColor,
              borderRadius: MaterialScreenStyles.folderSectionRadius,
              border: MaterialScreenStyles.cardBorder,
            ),
            child: const Text(
              _MaterialText.noFoldersLabel,
              textAlign: TextAlign.center,
              style: MaterialScreenStyles.emptyFolderStyle,
            ),
          )
        else
          SizedBox(
            height: MaterialScreenStyles.folderCardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _folders.length,
              separatorBuilder: (BuildContext context, int index) {
                return const SizedBox(
                  width: MaterialScreenStyles.folderSpacing,
                );
              },
              itemBuilder: (BuildContext context, int index) {
                final MaterialFolderModel folder = _folders[index];

                return _FolderCard(
                  folder: folder,
                  cardIndex: index,
                  isSelected: false,
                  onPressed: () {
                    _showFolderContents(folder);
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
            _MaterialText.recentMaterialsTitle,
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
          child: const Text(_MaterialText.viewAllLabel),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const _MaterialStateView(
        icon: MaterialScreenStyles.folderIcon,
        title: _MaterialText.loadingLabel,
        showProgressIndicator: true,
      );
    }

    if (_errorMessage != null) {
      return _MaterialStateView(
        icon: MaterialScreenStyles.errorIcon,
        title: _MaterialText.errorTitle,
        description: _errorMessage,
        actionLabel: _MaterialText.retryLabel,
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
        title: _MaterialText.emptySearchTitle,
        description: _MaterialText.emptySearchDescription,
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
            filePath: material.filePath,
            fileUrl: _materialService.getFileUrl(material.filePath),
            onPressed: () {
              _openMaterialPreview(material);
            },
            onMenuSelected: (_MaterialMenuAction action) {
              switch (action) {
                case _MaterialMenuAction.preview:
                  _openMaterialPreview(material);

                case _MaterialMenuAction.moveToFolder:
                  _showMoveToFolderDialog(material);

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

  bool _isPdfMaterial(MaterialModel material) {
    final String type = material.fileType.toLowerCase();

    return type.contains('pdf');
  }
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
      shape: RoundedRectangleBorder(
        borderRadius: MaterialScreenStyles.filterRadius,
        side: BorderSide(
          color: isSelected
              ? MaterialScreenStyles.primaryColor
              : MaterialScreenStyles.outlineColor,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
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
    required this.cardIndex,
    required this.isSelected,
    required this.onPressed,
  });

  final MaterialFolderModel folder;
  final int cardIndex;
  final bool isSelected;
  final VoidCallback onPressed;

  bool get _usesWarmPalette => cardIndex % 3 == 0;

  Color get _backgroundColor {
    if (isSelected) {
      return MaterialScreenStyles.selectedFolderBackgroundColor;
    }

    return _usesWarmPalette
        ? MaterialScreenStyles.warmFolderBackgroundColor
        : MaterialScreenStyles.purpleFolderBackgroundColor;
  }

  Color get _outlineColor {
    if (isSelected) {
      return MaterialScreenStyles.primaryBrightColor;
    }

    return _usesWarmPalette
        ? MaterialScreenStyles.warmFolderOutlineColor
        : MaterialScreenStyles.purpleFolderOutlineColor;
  }

  Color get _folderIconColor {
    return _usesWarmPalette
        ? MaterialScreenStyles.warmFolderColor
        : MaterialScreenStyles.purpleFolderColor;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: MaterialScreenStyles.folderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        borderRadius: MaterialScreenStyles.folderRadius,
        child: AnimatedContainer(
          duration: MaterialScreenStyles.folderSelectionDuration,
          width: MaterialScreenStyles.folderCardWidth,
          padding: MaterialScreenStyles.folderPadding,
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: MaterialScreenStyles.folderRadius,
            border: Border.all(
              color: _outlineColor,
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                MaterialScreenStyles.folderIcon,
                size: MaterialScreenStyles.folderIconSize,
                color: _folderIconColor,
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
                '${folder.itemCount == 1 ? _MaterialText.itemSingular : _MaterialText.itemPlural}',
                maxLines: 1,
                textAlign: TextAlign.center,
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
    required this.filePath,
    required this.fileUrl,
    required this.onPressed,
    required this.onMenuSelected,
  });

  final String title;
  final String category;
  final String date;
  final bool isImage;
  final String filePath;
  final String fileUrl;
  final VoidCallback onPressed;
  final ValueChanged<_MaterialMenuAction> onMenuSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MaterialScreenStyles.materialCardHeight,
      child: Material(
        color: MaterialScreenStyles.recentCardBackgroundColor,
        borderRadius: MaterialScreenStyles.materialCardRadius,
        clipBehavior: Clip.antiAlias,
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _MaterialThumbnail(
                  isImage: isImage,
                  filePath: filePath,
                  fileUrl: fileUrl,
                ),
                const SizedBox(
                  width: MaterialScreenStyles.materialContentSpacing,
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                      Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MaterialScreenStyles.materialCategoryStyle,
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
                SizedBox(
                  width: MaterialScreenStyles.materialMenuButtonSize,
                  height: MaterialScreenStyles.materialMenuButtonSize,
                  child: PopupMenuButton<_MaterialMenuAction>(
                    tooltip: _MaterialText.materialOptionsTooltip,
                    padding: MaterialScreenStyles.materialMenuPadding,
                    onSelected: onMenuSelected,
                    icon: const Icon(
                      MaterialScreenStyles.moreIcon,
                      size: MaterialScreenStyles.materialMenuIconSize,
                      color: MaterialScreenStyles.textSecondaryColor,
                    ),
                    itemBuilder: (BuildContext context) {
                      return const <PopupMenuEntry<_MaterialMenuAction>>[
                        PopupMenuItem<_MaterialMenuAction>(
                          value: _MaterialMenuAction.preview,
                          child: ListTile(
                            leading: Icon(MaterialScreenStyles.previewIcon),
                            title: Text(_MaterialText.previewLabel),
                          ),
                        ),
                        PopupMenuItem<_MaterialMenuAction>(
                          value: _MaterialMenuAction.moveToFolder,
                          child: ListTile(
                            leading: Icon(
                              MaterialScreenStyles.moveToFolderIcon,
                            ),
                            title: Text(_MaterialText.moveToFolderLabel),
                          ),
                        ),
                        PopupMenuItem<_MaterialMenuAction>(
                          value: _MaterialMenuAction.delete,
                          child: ListTile(
                            leading: Icon(
                              MaterialScreenStyles.deleteIcon,
                              color: MaterialScreenStyles.primaryColor,
                            ),
                            title: Text(_MaterialText.deleteLabel),
                          ),
                        ),
                      ];
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MaterialThumbnail extends StatelessWidget {
  const _MaterialThumbnail({
    required this.isImage,
    required this.filePath,
    required this.fileUrl,
  });

  final bool isImage;
  final String filePath;
  final String fileUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MaterialScreenStyles.thumbnailWidth,
      height: MaterialScreenStyles.thumbnailHeight,
      decoration: const BoxDecoration(
        color: MaterialScreenStyles.thumbnailBackgroundColor,
        borderRadius: MaterialScreenStyles.thumbnailRadius,
        border: MaterialScreenStyles.thumbnailBorder,
      ),
      clipBehavior: Clip.antiAlias,
      child: isImage ? _buildImage() : _buildFallback(),
    );
  }

  Widget _buildImage() {
    final File localFile = File(filePath);

    return Image.file(
      localFile,
      fit: MaterialScreenStyles.thumbnailImageFit,
      alignment: Alignment.center,
      filterQuality: MaterialScreenStyles.thumbnailFilterQuality,
      gaplessPlayback: true,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
            if (fileUrl.trim().isEmpty) {
              return _buildFallback();
            }

            return Image.network(
              fileUrl,
              fit: MaterialScreenStyles.thumbnailImageFit,
              alignment: Alignment.center,
              filterQuality: MaterialScreenStyles.thumbnailFilterQuality,
              gaplessPlayback: true,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stackTrace) {
                    return _buildFallback();
                  },
            );
          },
    );
  }

  Widget _buildFallback() {
    return const Center(
      child: Icon(
        MaterialScreenStyles.documentIcon,
        color: MaterialScreenStyles.primaryBrightColor,
        size: MaterialScreenStyles.thumbnailIconSize,
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
