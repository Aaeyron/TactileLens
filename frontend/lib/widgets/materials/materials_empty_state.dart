import 'package:flutter/material.dart';
import '../../styles/widgets/materials/material_widget_styles.dart';

class MaterialsEmptyState extends StatelessWidget {
  const MaterialsEmptyState({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MaterialWidgetStyles.emptyCardHeight,
      padding: MaterialWidgetStyles.emptyCardPadding,

      decoration: BoxDecoration(
        color: MaterialWidgetStyles.emptyCardColor,
        borderRadius: MaterialWidgetStyles.emptyCardRadius,
        boxShadow: MaterialWidgetStyles.emptyCardShadow,
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          // ==========================
          // Empty State Icon
          // ==========================
          Container(
            width: MaterialWidgetStyles.emptyIconContainerSize,
            height: MaterialWidgetStyles.emptyIconContainerSize,

            decoration: BoxDecoration(
              color:
                  MaterialWidgetStyles.emptyIconBackgroundColor,

              borderRadius:
                  MaterialWidgetStyles.emptyIconRadius,
            ),

            child: Icon(
              Icons.folder_open_outlined,
              size: MaterialWidgetStyles.emptyIconSize,
              color: MaterialWidgetStyles.emptyIconColor,
            ),
          ),


          const SizedBox(
            height: MaterialWidgetStyles.emptyIconTextSpacing,
          ),


          // ==========================
          // Empty State Title
          // ==========================
          const Text(
            "No Materials Yet",
            style: MaterialWidgetStyles.emptyTitleStyle,
            textAlign: TextAlign.center,
          ),


          const SizedBox(
            height: MaterialWidgetStyles.emptySubtitleTopSpacing,
          ),


          // ==========================
          // Empty State Description
          // ==========================
          const Text(
            "Upload your General Algebra materials to organize and prepare them for OCR and Nemeth Braille translation.",
            style: MaterialWidgetStyles.emptySubtitleStyle,
            textAlign: TextAlign.center,
          ),

        ],
      ),
    );
  }
}