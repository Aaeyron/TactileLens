import 'package:flutter/material.dart';
import '../../widgets/app_header.dart';
import '../../widgets/materials/upload_material_button.dart';
import '../../widgets/materials/materials_empty_state.dart';
import '../../styles/screens/materials/material_styles.dart';

class MaterialsScreen extends StatelessWidget {
  const MaterialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaterialsStyles.backgroundColor,

      body: Column(
        children: [

          // ==========================
          // Top Header
          // ==========================
          const AppHeader(),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: MaterialsStyles.contentPadding,
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                    // ==========================
                    // Page Title
                    // ==========================
                    const Text(
                      "Materials",
                      style: MaterialsStyles.pageTitleStyle,
                    ),

                     const SizedBox(
                      height: MaterialsStyles.pageTitleBottomSpacing,
                  ),

                    // ==========================
                    // Page Description
                    // ==========================
                    const Text(
                    "Manage your uploaded General Algebra learning materials for OCR and Nemeth Braille translation.",
                    style: MaterialsStyles.pageDescriptionStyle,
                  ),

                    const SizedBox(
                    height: MaterialsStyles.pageDescriptionBottomSpacing,
                  ),

                    // ==========================
                    // Upload Material Button
                    // ==========================
                    const UploadMaterialButton(),

                    const SizedBox(
                      height: MaterialsStyles.sectionSpacing,
                    ),

                    // ==========================
                    // Empty Materials State
                    // ==========================
                    const MaterialsEmptyState(),

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