import 'package:flutter/material.dart';

import '../../models/materials/material_model.dart';
import '../../styles/widgets/materials/material_widget_styles.dart';

class MaterialCard extends StatelessWidget {
  final MaterialModel material;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const MaterialCard({
    super.key,
    required this.material,
    this.onDelete,
    this.onTap,
  });

  // ============================================================
  // Format File Size
  // ============================================================

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // ============================================================
  // Format Upload Date
  // ============================================================

  String _formatUploadDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  // ============================================================
  // Get File Icon
  // ============================================================

  IconData _getFileIcon(String fileType) {
    final type = fileType.toLowerCase();

    if (type.contains('pdf')) {
      return Icons.picture_as_pdf_outlined;
    }

    if (type.contains('word') ||
        type.contains('document') ||
        type.contains('doc')) {
      return Icons.description_outlined;
    }

    if (type.contains('image')) {
      return Icons.image_outlined;
    }

    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(
          MaterialWidgetStyles.materialCardPadding,
        ),

        decoration: BoxDecoration(
          color: MaterialWidgetStyles.materialCardColor,
          borderRadius:
              MaterialWidgetStyles.materialCardRadius,
          boxShadow:
              MaterialWidgetStyles.materialCardShadow,
        ),

        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // ==================================================
            // File Icon
            // ==================================================

            Container(
              width:
                  MaterialWidgetStyles.materialIconContainerSize,

              height:
                  MaterialWidgetStyles.materialIconContainerSize,

              decoration: BoxDecoration(
                color:
                    MaterialWidgetStyles
                        .materialIconBackgroundColor,

                borderRadius:
                    MaterialWidgetStyles
                        .materialIconRadius,
              ),

              child: Icon(
                _getFileIcon(
                  material.fileType,
                ),

                size:
                    MaterialWidgetStyles
                        .materialIconSize,

                color:
                    MaterialWidgetStyles
                        .materialIconColor,
              ),
            ),

            const SizedBox(
              width:
                  MaterialWidgetStyles
                      .materialIconTextSpacing,
            ),

            // ==================================================
            // Material Information
            // ==================================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  // Material Title
                  Text(
                    material.title,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        MaterialWidgetStyles
                            .materialTitleStyle,
                  ),

                  const SizedBox(
                    height:
                        MaterialWidgetStyles
                            .materialTitleFileSpacing,
                  ),

                  // File Name
                  Text(
                    material.fileName,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        MaterialWidgetStyles
                            .materialFileNameStyle,
                  ),

                  const SizedBox(
                    height:
                        MaterialWidgetStyles
                            .materialInfoSpacing,
                  ),

                  // Subject
                  Text(
                    'Subject: ${material.subject}',
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        MaterialWidgetStyles
                            .materialInfoStyle,
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  // File Details
                  Text(
                    '${material.fileType} • '
                    '${_formatFileSize(material.fileSize)} • '
                    '${_formatUploadDate(material.uploadDate)}',

                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        MaterialWidgetStyles
                            .materialInfoStyle,
                  ),
                ],
              ),
            ),

            // ==================================================
            // More Actions
            // ==================================================

            PopupMenuButton<String>(
              padding: EdgeInsets.zero,

              icon: const Icon(
                Icons.more_vert,
                size:
                    MaterialWidgetStyles
                        .materialActionIconSize,

                color:
                    MaterialWidgetStyles
                        .materialActionIconColor,
              ),

              onSelected: (value) {
                if (value == 'delete') {
                  onDelete?.call();
                }
              },

              itemBuilder: (context) => [

                const PopupMenuItem<String>(
                  value: 'delete',

                  child: Row(
                    children: [

                      Icon(
                        Icons.delete_outline,
                        color:
                            MaterialWidgetStyles
                                .materialDeleteIconColor,
                      ),

                      SizedBox(
                        width: 10,
                      ),

                      Text(
                        'Delete',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}