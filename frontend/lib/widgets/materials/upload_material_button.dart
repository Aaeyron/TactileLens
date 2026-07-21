import 'package:flutter/material.dart';
import '../../styles/materials/materials_styles.dart';

class UploadMaterialButton extends StatelessWidget {
  const UploadMaterialButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: MaterialsStyles.uploadButtonHeight,

      child: ElevatedButton.icon(
        onPressed: () {
          // TODO: Add upload functionality later
        },

        icon: Icon(
          Icons.upload_file_outlined,
          size: MaterialsStyles.uploadButtonIconSize,
        ),

        label: const Text(
          "Upload Material",
          style: MaterialsStyles.uploadButtonTextStyle,
        ),

        style: ElevatedButton.styleFrom(
          backgroundColor:
              MaterialsStyles.uploadButtonColor,

          shape: RoundedRectangleBorder(
            borderRadius:
                MaterialsStyles.uploadButtonRadius,
          ),

          elevation: 0,
        ),
      ),
    );
  }
}