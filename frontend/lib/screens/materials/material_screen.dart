import 'package:flutter/material.dart';

import '../../models/materials/material_model.dart';
import '../../services/materials/material_service.dart';
import '../../styles/screens/materials/material_screen_styles.dart';
import '../../widgets/materials/material_card.dart';
import '../../widgets/materials/materials_empty_state.dart';
import '../../widgets/materials/upload_material_button.dart';
import 'material_detail_screen.dart';

enum _MaterialFilter { all, pdf, image, document }

enum _MaterialSort { newest, oldest, title }

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

  bool _isPdfMaterial(MaterialModel material) {
    final String type = material.fileType.toLowerCase();

    return type.contains(MaterialScreenStyles.pdfType);
  }

  bool _isImageMaterial(MaterialModel material) {
    final String type = material.fileType.toLowerCase();

    return type.contains(MaterialScreenStyles.imageType) ||
        type.contains(MaterialScreenStyles.jpgType) ||
        type.contains(MaterialScreenStyles.jpegType) ||
        type.contains(MaterialScreenStyles.pngType);
  }

  bool _isDocumentMaterial(MaterialModel material) {
    return !_isPdfMaterial(material) && !_isImageMaterial(material);
  }

  bool _matchesSelectedFilter(MaterialModel material) {
    return switch (_selectedFilter) {
      _MaterialFilter.all => true,
      _MaterialFilter.pdf => _isPdfMaterial(material),
      _MaterialFilter.image => _isImageMaterial(material),
      _MaterialFilter.document => _isDocumentMaterial(material),
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
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(MaterialScreenStyles.errorDescription);
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
            side: BorderSide(
              color: MaterialScreenStyles.outlineColor,
              width: MaterialScreenStyles.cardBorderWidth,
            ),
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
              style: MaterialScreenStyles.dialogCancelButtonStyle,
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

  Future<void> _openMaterialPreview(MaterialModel material) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return MaterialDetailScreen(material: material);
        },
      ),
    );

    if (!mounted) {
      return;
    }

    await _refreshMaterials();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: MaterialScreenStyles.snackBarDuration,
          behavior: MaterialScreenStyles.snackBarBehavior,
          backgroundColor: MaterialScreenStyles.primaryColor,
          margin: MaterialScreenStyles.snackBarMargin,
          shape: const RoundedRectangleBorder(
            borderRadius: MaterialScreenStyles.snackBarRadius,
          ),
          content: Text(message, style: MaterialScreenStyles.snackBarTextStyle),
        ),
      );
  }

  void _selectSort(_MaterialSort sort) {
    setState(() {
      _selectedSort = sort;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaterialScreenStyles.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: MaterialScreenStyles.primaryColor,
          onRefresh: _refreshMaterials,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: MaterialScreenStyles.contentPadding,
            children: <Widget>[
              _buildBrandHeader(),
              const SizedBox(height: MaterialScreenStyles.heroTopSpacing),
              _buildPageIntroduction(),
              const SizedBox(height: MaterialScreenStyles.searchTopSpacing),
              _buildSearchAndSort(),
              const SizedBox(height: MaterialScreenStyles.filterTopSpacing),
              _buildFilters(),
              const SizedBox(height: MaterialScreenStyles.sectionSpacing),
              _buildMaterialsHeader(),
              const SizedBox(
                height: MaterialScreenStyles.materialsHeaderSpacing,
              ),
              _buildContent(),
              const SizedBox(height: MaterialScreenStyles.uploadTopSpacing),
              UploadMaterialButton(onUploadSuccess: _refreshMaterials),
              const SizedBox(height: MaterialScreenStyles.bottomSpacing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Row(
      children: <Widget>[
        ClipRRect(
          borderRadius: MaterialScreenStyles.logoRadius,
          child: Image.asset(
            MaterialScreenStyles.logoAsset,
            width: MaterialScreenStyles.logoSize,
            height: MaterialScreenStyles.logoSize,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: MaterialScreenStyles.logoTextSpacing),
        const Expanded(
          child: Text(
            MaterialScreenStyles.appName,
            style: MaterialScreenStyles.appNameStyle,
          ),
        ),
        Container(
          width: MaterialScreenStyles.headerStatusButtonSize,
          height: MaterialScreenStyles.headerStatusButtonSize,
          decoration: const BoxDecoration(
            color: MaterialScreenStyles.surfaceColor,
            shape: BoxShape.circle,
            border: MaterialScreenStyles.smallContainerBorder,
            boxShadow: MaterialScreenStyles.smallContainerShadow,
          ),
          child: const Icon(
            MaterialScreenStyles.headerStatusIcon,
            size: MaterialScreenStyles.headerStatusIconSize,
            color: MaterialScreenStyles.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPageIntroduction() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    tooltip: MaterialScreenStyles.backTooltip,
                    onPressed: widget.onBack,
                    style: MaterialScreenStyles.backButtonStyle,
                    icon: const Icon(
                      MaterialScreenStyles.backIcon,
                      size: MaterialScreenStyles.backIconSize,
                    ),
                  ),
                  const SizedBox(width: MaterialScreenStyles.backTitleSpacing),
                  const Expanded(
                    child: Text(
                      MaterialScreenStyles.pageTitle,
                      style: MaterialScreenStyles.pageTitleStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: MaterialScreenStyles.pageDescriptionSpacing,
              ),
              const Text(
                MaterialScreenStyles.pageDescription,
                style: MaterialScreenStyles.pageDescriptionStyle,
              ),
            ],
          ),
        ),
        const SizedBox(width: MaterialScreenStyles.heroContentSpacing),
        Container(
          width: MaterialScreenStyles.heroIconContainerSize,
          height: MaterialScreenStyles.heroIconContainerSize,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: MaterialScreenStyles.surfaceColor,
            borderRadius: MaterialScreenStyles.heroIconRadius,
            border: MaterialScreenStyles.cardBorder,
            boxShadow: MaterialScreenStyles.cardShadow,
          ),
          child: const Icon(
            MaterialScreenStyles.heroIcon,
            size: MaterialScreenStyles.heroIconSize,
            color: MaterialScreenStyles.primaryBrightColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndSort() {
    return Container(
      height: MaterialScreenStyles.searchHeight,
      decoration: const BoxDecoration(
        color: MaterialScreenStyles.surfaceColor,
        borderRadius: MaterialScreenStyles.searchRadius,
        border: MaterialScreenStyles.cardBorder,
        boxShadow: MaterialScreenStyles.searchShadow,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
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
          const VerticalDivider(
            width: MaterialScreenStyles.searchDividerWidth,
            indent: MaterialScreenStyles.searchDividerIndent,
            endIndent: MaterialScreenStyles.searchDividerIndent,
            color: MaterialScreenStyles.dividerColor,
          ),
          PopupMenuButton<_MaterialSort>(
            tooltip: MaterialScreenStyles.sortTooltip,
            initialValue: _selectedSort,
            onSelected: _selectSort,
            icon: const Icon(
              MaterialScreenStyles.sortIcon,
              size: MaterialScreenStyles.sortIconSize,
              color: MaterialScreenStyles.primaryBrightColor,
            ),
            style: MaterialScreenStyles.sortButtonStyle,
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
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          _MaterialFilterButton(
            label: MaterialScreenStyles.allFilterLabel,
            icon: MaterialScreenStyles.allFilterIcon,
            isSelected: _selectedFilter == _MaterialFilter.all,
            onPressed: () {
              setState(() {
                _selectedFilter = _MaterialFilter.all;
              });
            },
          ),
          const SizedBox(width: MaterialScreenStyles.filterSpacing),
          _MaterialFilterButton(
            label: MaterialScreenStyles.pdfFilterLabel,
            icon: MaterialScreenStyles.pdfFilterIcon,
            isSelected: _selectedFilter == _MaterialFilter.pdf,
            onPressed: () {
              setState(() {
                _selectedFilter = _MaterialFilter.pdf;
              });
            },
          ),
          const SizedBox(width: MaterialScreenStyles.filterSpacing),
          _MaterialFilterButton(
            label: MaterialScreenStyles.imageFilterLabel,
            icon: MaterialScreenStyles.imageFilterIcon,
            isSelected: _selectedFilter == _MaterialFilter.image,
            onPressed: () {
              setState(() {
                _selectedFilter = _MaterialFilter.image;
              });
            },
          ),
          const SizedBox(width: MaterialScreenStyles.filterSpacing),
          _MaterialFilterButton(
            label: MaterialScreenStyles.documentFilterLabel,
            icon: MaterialScreenStyles.documentFilterIcon,
            isSelected: _selectedFilter == _MaterialFilter.document,
            onPressed: () {
              setState(() {
                _selectedFilter = _MaterialFilter.document;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsHeader() {
    final int count = _visibleMaterials.length;

    return Row(
      children: <Widget>[
        const Expanded(
          child: Text(
            MaterialScreenStyles.materialsSectionTitle,
            style: MaterialScreenStyles.sectionTitleStyle,
          ),
        ),
        Text(
          '$count '
          '${count == 1 ? MaterialScreenStyles.materialCountSingular : MaterialScreenStyles.materialCountPlural}',
          style: MaterialScreenStyles.countTextStyle,
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const _MaterialStateView(
        icon: MaterialScreenStyles.allFilterIcon,
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
                ? MaterialScreenStyles.zero
                : MaterialScreenStyles.cardSpacing,
          ),
          child: MaterialCard(
            material: material,
            onTap: () {
              _openMaterialPreview(material);
            },
            onDelete: () {
              _requestDelete(material);
            },
          ),
        );
      }, growable: false),
    );
  }
}

class _MaterialFilterButton extends StatelessWidget {
  const _MaterialFilterButton({
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
    return Material(
      color: isSelected
          ? MaterialScreenStyles.primaryBrightColor
          : MaterialScreenStyles.surfaceColor,
      borderRadius: MaterialScreenStyles.filterRadius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: MaterialScreenStyles.filterRadius,
        child: Container(
          height: MaterialScreenStyles.filterHeight,
          padding: MaterialScreenStyles.filterPadding,
          decoration: BoxDecoration(
            borderRadius: MaterialScreenStyles.filterRadius,
            border: Border.all(
              color: isSelected
                  ? MaterialScreenStyles.primaryBrightColor
                  : MaterialScreenStyles.outlineColor,
              width: MaterialScreenStyles.filterBorderWidth,
            ),
            boxShadow: MaterialScreenStyles.filterShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: MaterialScreenStyles.filterIconSize,
                color: isSelected
                    ? MaterialScreenStyles.surfaceColor
                    : MaterialScreenStyles.primaryBrightColor,
              ),
              const SizedBox(width: MaterialScreenStyles.compactSpacing),
              Text(
                label,
                style: isSelected
                    ? MaterialScreenStyles.selectedFilterTextStyle
                    : MaterialScreenStyles.filterTextStyle,
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
        borderRadius: MaterialScreenStyles.stateCardRadius,
        border: MaterialScreenStyles.cardBorder,
        boxShadow: MaterialScreenStyles.cardShadow,
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
          const SizedBox(height: MaterialScreenStyles.itemSpacing),
          Text(
            title,
            textAlign: TextAlign.center,
            style: MaterialScreenStyles.stateTitleStyle,
          ),
          if (description != null) ...<Widget>[
            const SizedBox(height: MaterialScreenStyles.compactSpacing),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: MaterialScreenStyles.stateDescriptionStyle,
            ),
          ],
          if (actionLabel != null && onActionPressed != null) ...<Widget>[
            const SizedBox(height: MaterialScreenStyles.itemSpacing),
            FilledButton(
              onPressed: onActionPressed,
              style: MaterialScreenStyles.retryButtonStyle,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
