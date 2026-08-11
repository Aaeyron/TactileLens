import 'package:flutter/material.dart';

import '../../models/materials/material_model.dart';
import '../../services/materials/material_service.dart';
import '../../styles/screens/materials/material_screen_styles.dart';
import '../../widgets/app_header.dart';
import '../../widgets/materials/material_card.dart';
import '../../widgets/materials/materials_empty_state.dart';
import '../../widgets/materials/upload_material_button.dart';
import 'material_detail_screen.dart';

enum _MaterialFilter { all, scanned, uploaded }

enum _MaterialSort { newest, oldest, title }

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
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

  bool _isScannedMaterial(MaterialModel material) {
    return material.recognizedContent.trim().isNotEmpty ||
        material.brailleContent.trim().isNotEmpty;
  }

  int get _scannedMaterialCount {
    return _materials.where(_isScannedMaterial).length;
  }

  int get _uploadedMaterialCount {
    return _materials.length - _scannedMaterialCount;
  }

  List<MaterialModel> get _visibleMaterials {
    final String query = _searchController.text.trim().toLowerCase();

    final List<MaterialModel> filtered = _materials
        .where((MaterialModel material) {
          final bool isScanned = _isScannedMaterial(material);

          final bool matchesFilter = switch (_selectedFilter) {
            _MaterialFilter.all => true,
            _MaterialFilter.scanned => isScanned,
            _MaterialFilter.uploaded => !isScanned,
          };

          if (!matchesFilter) {
            return false;
          }

          if (query.isEmpty) {
            return true;
          }

          return material.title.toLowerCase().contains(query) ||
              material.subject.toLowerCase().contains(query) ||
              material.description.toLowerCase().contains(query) ||
              material.recognizedContent.toLowerCase().contains(query);
        })
        .toList(growable: false);

    switch (_selectedSort) {
      case _MaterialSort.newest:
        filtered.sort(
          (MaterialModel first, MaterialModel second) =>
              second.uploadDate.compareTo(first.uploadDate),
        );

      case _MaterialSort.oldest:
        filtered.sort(
          (MaterialModel first, MaterialModel second) =>
              first.uploadDate.compareTo(second.uploadDate),
        );

      case _MaterialSort.title:
        filtered.sort(
          (MaterialModel first, MaterialModel second) =>
              first.title.toLowerCase().compareTo(second.title.toLowerCase()),
        );
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
          shape: const RoundedRectangleBorder(
            borderRadius: MaterialScreenStyles.dialogRadius,
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
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: MaterialScreenStyles.deleteButtonStyle,
              child: const Text(MaterialScreenStyles.deleteLabel),
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
      appBar: PreferredSize(
        preferredSize: MaterialScreenStyles.headerSize,
        child: Stack(
          children: <Widget>[
            const AppHeader(),
            const Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: MaterialScreenStyles.headerPadding,
                  child: Center(
                    child: Text(
                      MaterialScreenStyles.pageTitle,
                      style: MaterialScreenStyles.pageTitleStyle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: MaterialScreenStyles.primaryColor,
        onRefresh: _refreshMaterials,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: MaterialScreenStyles.contentPadding,
          children: <Widget>[
            const Text(
              MaterialScreenStyles.pageDescription,
              style: MaterialScreenStyles.pageDescriptionStyle,
            ),
            const SizedBox(height: MaterialScreenStyles.sectionSpacing),
            _buildSummary(),
            const SizedBox(height: MaterialScreenStyles.sectionSpacing),
            UploadMaterialButton(onUploadSuccess: _refreshMaterials),
            const SizedBox(height: MaterialScreenStyles.sectionSpacing),
            _buildSearchAndSort(),
            const SizedBox(height: MaterialScreenStyles.itemSpacing),
            _buildFilters(),
            const SizedBox(height: MaterialScreenStyles.sectionSpacing),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: MaterialScreenStyles.summaryPadding,
      decoration: const BoxDecoration(
        color: MaterialScreenStyles.summaryBackgroundColor,
        borderRadius: MaterialScreenStyles.summaryRadius,
        border: MaterialScreenStyles.summaryBorder,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _MaterialSummaryItem(
              value: _materials.length,
              label: MaterialScreenStyles.totalMaterialsLabel,
            ),
          ),
          const _MaterialSummaryDivider(),
          Expanded(
            child: _MaterialSummaryItem(
              value: _scannedMaterialCount,
              label: MaterialScreenStyles.scannedMaterialsLabel,
            ),
          ),
          const _MaterialSummaryDivider(),
          Expanded(
            child: _MaterialSummaryItem(
              value: _uploadedMaterialCount,
              label: MaterialScreenStyles.uploadedMaterialsLabel,
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
        const SizedBox(width: MaterialScreenStyles.itemSpacing),
        PopupMenuButton<_MaterialSort>(
          tooltip: MaterialScreenStyles.sortTooltip,
          initialValue: _selectedSort,
          onSelected: _selectSort,
          icon: const Icon(
            MaterialScreenStyles.sortIcon,
            size: MaterialScreenStyles.sortIconSize,
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
            label: MaterialScreenStyles.scannedFilterLabel,
            icon: MaterialScreenStyles.scannedFilterIcon,
            isSelected: _selectedFilter == _MaterialFilter.scanned,
            onPressed: () {
              setState(() {
                _selectedFilter = _MaterialFilter.scanned;
              });
            },
          ),
          const SizedBox(width: MaterialScreenStyles.filterSpacing),
          _MaterialFilterButton(
            label: MaterialScreenStyles.uploadedFilterLabel,
            icon: MaterialScreenStyles.uploadedFilterIcon,
            isSelected: _selectedFilter == _MaterialFilter.uploaded,
            onPressed: () {
              setState(() {
                _selectedFilter = _MaterialFilter.uploaded;
              });
            },
          ),
        ],
      ),
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
    return InkWell(
      onTap: onPressed,
      borderRadius: MaterialScreenStyles.filterRadius,
      child: Container(
        height: MaterialScreenStyles.filterHeight,
        padding: MaterialScreenStyles.filterPadding,
        decoration: BoxDecoration(
          color: isSelected
              ? MaterialScreenStyles.primaryColor
              : MaterialScreenStyles.surfaceColor,
          borderRadius: MaterialScreenStyles.filterRadius,
          border: Border.all(
            color: isSelected
                ? MaterialScreenStyles.primaryColor
                : MaterialScreenStyles.outlineColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: MaterialScreenStyles.filterIconSize,
              color: isSelected
                  ? MaterialScreenStyles.surfaceColor
                  : MaterialScreenStyles.textSecondaryColor,
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
    );
  }
}

class _MaterialSummaryItem extends StatelessWidget {
  const _MaterialSummaryItem({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(value.toString(), style: MaterialScreenStyles.summaryValueStyle),
        const SizedBox(height: MaterialScreenStyles.compactSpacing),
        Text(
          label,
          textAlign: TextAlign.center,
          style: MaterialScreenStyles.summaryLabelStyle,
        ),
      ],
    );
  }
}

class _MaterialSummaryDivider extends StatelessWidget {
  const _MaterialSummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: MaterialScreenStyles.summaryDividerHeight,
      color: MaterialScreenStyles.summaryDividerColor,
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
    return Padding(
      padding: MaterialScreenStyles.statePadding,
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
