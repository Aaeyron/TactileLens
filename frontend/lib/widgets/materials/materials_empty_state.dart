import 'package:flutter/material.dart';
import '../../styles/screens/materials/material_styles.dart';

class MaterialsEmptyState extends StatelessWidget {
  const MaterialsEmptyState({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MaterialsStyles.emptyCardHeight,
      padding: MaterialsStyles.emptyCardPadding,

      decoration: BoxDecoration(
        color: MaterialsStyles.emptyCardColor,
        borderRadius: MaterialsStyles.emptyCardRadius,
        boxShadow: MaterialsStyles.emptyCardShadow,
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          // ==========================
          // Empty State Icon
          // ==========================
          Container(
            width: MaterialsStyles.emptyIconContainerSize,
            height: MaterialsStyles.emptyIconContainerSize,

            decoration: BoxDecoration(
              color:
                  MaterialsStyles.emptyIconBackgroundColor,

              borderRadius:
                  MaterialsStyles.emptyIconRadius,
            ),

            child: Icon(
              Icons.folder_open_outlined,
              size: MaterialsStyles.emptyIconSize,
              color: MaterialsStyles.emptyIconColor,
            ),
          ),


          const SizedBox(
            height: MaterialsStyles.emptyIconTextSpacing,
          ),


          // ==========================
          // Empty State Title
          // ==========================
          const Text(
            "No Materials Yet",
            style: MaterialsStyles.emptyTitleStyle,
            textAlign: TextAlign.center,
          ),


          const SizedBox(
            height: MaterialsStyles.emptySubtitleTopSpacing,
          ),


          // ==========================
          // Empty State Description
          // ==========================
          const Text(
            "Upload your General Algebra materials to organize and prepare them for OCR and Nemeth Braille translation.",
            style: MaterialsStyles.emptySubtitleStyle,
            textAlign: TextAlign.center,
          ),

        ],
      ),
    );
  }
}