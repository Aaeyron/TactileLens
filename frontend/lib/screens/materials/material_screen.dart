import 'package:flutter/material.dart';

import '../../models/materials/material_model.dart';
import '../../services/materials/material_service.dart';
import '../../widgets/app_header.dart';
import '../../widgets/materials/upload_material_button.dart';
import '../../widgets/materials/materials_empty_state.dart';
import '../../widgets/materials/material_card.dart';
import '../../styles/screens/materials/material_screen_styles.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final MaterialService _materialService = MaterialService();

  List<MaterialModel> _materials = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    try {
      final materials = await _materialService.getMaterials();

      if (!mounted) return;

      setState(() {
        _materials = materials;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMaterial(int id) async {
  try {
    await _materialService.deleteMaterial(id);

    if (!mounted) return;

    setState(() {
      _materials.removeWhere((material) => material.id == id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Material deleted successfully'),
      ),
    );
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to delete material'),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaterialScreenStyles.backgroundColor,
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: MaterialScreenStyles.contentPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Materials",
                      style: MaterialScreenStyles.pageTitleStyle,
                    ),
                    const SizedBox(
                      height: MaterialScreenStyles.pageTitleBottomSpacing,
                    ),
                    const Text(
                      "Manage your uploaded General Algebra learning materials for OCR and Nemeth Braille translation.",
                      style: MaterialScreenStyles.pageDescriptionStyle,
                    ),
                    const SizedBox(
                      height: MaterialScreenStyles.pageDescriptionBottomSpacing,
                    ),

                    UploadMaterialButton(
                      onUploadSuccess: _loadMaterials,
                    ),

                    const SizedBox(
                      height: MaterialScreenStyles.sectionSpacing,
                    ),

          // ==========================
          // Materials List Container
          // ==========================
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _materials.isEmpty
                  ? const MaterialsEmptyState()
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _materials.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final material = _materials[index];

                          return MaterialCard(
                          material: material,
                          onDelete: () {
                            if (material.id != null) {
                              _deleteMaterial(material.id!);
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}