import 'package:flutter/material.dart';

import '../../models/materials/material_model.dart';
import '../../services/materials/material_service.dart';
import '../../styles/widgets/materials/material_widget_styles.dart';

class MaterialPreview extends StatelessWidget {
  final MaterialModel material;

  const MaterialPreview({
    super.key,
    required this.material,
  });

  IconData _getFileIcon(String fileType) {
    final type = fileType.toLowerCase();

    if (type.contains('pdf')) {
      return Icons.picture_as_pdf_outlined;
    }

    if (type.contains('image') ||
    type.contains('jpg') ||
    type.contains('jpeg') ||
    type.contains('png')) {
  return Icons.image_outlined;
}

    return Icons.insert_drive_file_outlined;
  }

  @override
Widget build(BuildContext context) {

  print("FILE PATH: ${material.filePath}");
  print("FILE URL: ${MaterialService().getFileUrl(material.filePath)}");
  print("FILE TYPE: ${material.fileType}");

  final type = material.fileType.toLowerCase();

    final isImage =
        type.contains('image') ||
        type.contains('jpg') ||
        type.contains('jpeg') ||
        type.contains('png');

  return Container(
      width: MaterialWidgetStyles.materialPreviewWidth,
      height: MaterialWidgetStyles.materialPreviewHeight,

      decoration: BoxDecoration(
      color: MaterialWidgetStyles.materialPreviewBackgroundColor,
      borderRadius:
          MaterialWidgetStyles.materialPreviewRadius,
      border: Border.all(
        color:
            MaterialWidgetStyles.materialPreviewBorderColor,
        width:
            MaterialWidgetStyles.materialPreviewBorderWidth,
      ),
    ),

      child: isImage
    ? ClipRRect(
        borderRadius:
            MaterialWidgetStyles.materialPreviewRadius,

        child: Image.network(
                MaterialService().getFileUrl(material.filePath),
                fit: BoxFit.cover,

                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.error,
                    ),
                  );
                },
              ),
          )
          : Center(
              child: Icon(
                _getFileIcon(material.fileType),
                size: MaterialWidgetStyles.materialPreviewIconSize,
                color: MaterialWidgetStyles.materialPreviewIconColor,
              ),
            ),
    );
  }
}