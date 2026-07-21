import 'package:flutter/material.dart';

import '../../models/materials/material_model.dart';
import '../../styles/materials/materials_styles.dart';

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
          MaterialsStyles.materialCardPadding,
        ),

        decoration: BoxDecoration(
          color: MaterialsStyles.materialCardColor,
          borderRadius:
              MaterialsStyles.materialCardRadius,
          boxShadow:
              MaterialsStyles.materialCardShadow,
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
                  MaterialsStyles.materialIconContainerSize,

              height:
                  MaterialsStyles.materialIconContainerSize,

              decoration: BoxDecoration(
                color:
                    MaterialsStyles
                        .materialIconBackgroundColor,

                borderRadius:
                    MaterialsStyles
                        .materialIconRadius,
              ),

              child: Icon(
                _getFileIcon(
                  material.fileType,
                ),

                size:
                    MaterialsStyles
                        .materialIconSize,

                color:
                    MaterialsStyles
                        .materialIconColor,
              ),
            ),

            const SizedBox(
              width:
                  MaterialsStyles
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
                        MaterialsStyles
                            .materialTitleStyle,
                  ),

                  const SizedBox(
                    height:
                        MaterialsStyles
                            .materialTitleFileSpacing,
                  ),

                  // File Name
                  Text(
                    material.fileName,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        MaterialsStyles
                            .materialFileNameStyle,
                  ),

                  const SizedBox(
                    height:
                        MaterialsStyles
                            .materialInfoSpacing,
                  ),

                  // Subject
                  Text(
                    'Subject: ${material.subject}',
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        MaterialsStyles
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
                        MaterialsStyles
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
                    MaterialsStyles
                        .materialActionIconSize,

                color:
                    MaterialsStyles
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
                            MaterialsStyles
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