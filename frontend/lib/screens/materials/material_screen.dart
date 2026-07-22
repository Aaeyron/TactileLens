import 'package:flutter/material.dart';

import '../../models/materials/material_model.dart';
import '../../services/materials/material_service.dart';
import '../../widgets/app_header.dart';
import '../../widgets/materials/upload_material_button.dart';
import '../../widgets/materials/materials_empty_state.dart';
import '../../styles/screens/materials/material_styles.dart';

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
      backgroundColor: MaterialsStyles.backgroundColor,
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: MaterialsStyles.contentPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Materials",
                      style: MaterialsStyles.pageTitleStyle,
                    ),
                    const SizedBox(
                      height: MaterialsStyles.pageTitleBottomSpacing,
                    ),
                    const Text(
                      "Manage your uploaded General Algebra learning materials for OCR and Nemeth Braille translation.",
                      style: MaterialsStyles.pageDescriptionStyle,
                    ),
                    const SizedBox(
                      height: MaterialsStyles.pageDescriptionBottomSpacing,
                    ),

                    UploadMaterialButton(
                      onUploadSuccess: _loadMaterials,
                    ),

                    const SizedBox(
                      height: MaterialsStyles.sectionSpacing,
                    ),

                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(),
                      )
                    else if (_materials.isEmpty)
                      const MaterialsEmptyState()
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _materials.length,
                        itemBuilder: (context, index) {
                          final material = _materials[index];

                          return Card(
                            child: ListTile(
                              title: Text(material.title),
                              subtitle: Text(material.subject),
                              trailing: Text(material.fileType),
                            ),
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