import 'dart:io';
import 'package:flutter/material.dart';

import '../../models/materials/material_model.dart';
import '../../styles/widgets/materials/material_widget_styles.dart';
import '../../utils/session_manager.dart';
import 'material_file_image.dart';

class MaterialPreview extends StatelessWidget {
  final MaterialModel material;

  const MaterialPreview({super.key, required this.material});

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

  Widget _buildImage() {
    return FutureBuilder<bool>(
      future: SessionManager.isGuest(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final bool isGuest = snapshot.data!;

        if (!isGuest && material.id != null) {
          return MaterialFileImage(
            materialId: material.id!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: Icon(Icons.error));
            },
          );
        }

        return Image.file(
          File(material.filePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(child: Icon(Icons.error));
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
        borderRadius: MaterialWidgetStyles.materialPreviewRadius,
        border: Border.all(
          color: MaterialWidgetStyles.materialPreviewBorderColor,
          width: MaterialWidgetStyles.materialPreviewBorderWidth,
        ),
      ),

      child: isImage
          ? ClipRRect(
              borderRadius: MaterialWidgetStyles.materialPreviewRadius,
              child: _buildImage(),
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
