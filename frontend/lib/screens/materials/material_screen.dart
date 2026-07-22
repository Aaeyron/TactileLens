import 'package:flutter/material.dart';

import '../../models/materials/material_model.dart';
import '../../services/materials/material_service.dart';
import '../../widgets/app_header.dart';
import '../../widgets/materials/upload_material_button.dart';
import '../../widgets/materials/materials_empty_state.dart';
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
          Container(
            height: MaterialScreenStyles.materialsListHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: MaterialScreenStyles.materialsListBackgroundColor,
              borderRadius: MaterialScreenStyles.materialsListRadius,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _materials.isEmpty
                    ? const MaterialsEmptyState()
                    : ListView.builder(
                        padding: MaterialScreenStyles.materialsListPadding,
                        itemCount: _materials.length,
                        itemBuilder: (context, index) {
                          final material = _materials[index];

                          return Card(
                            margin: MaterialScreenStyles.materialCardMargin,
                            child: ListTile(
                              title: Text(material.title),
                              subtitle: Text(material.subject),
                              trailing: Text(material.fileType),
                            ),
                          );
                        },
                      ),
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