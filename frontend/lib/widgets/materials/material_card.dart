import 'package:flutter/material.dart';

import '../../models/materials/material_model.dart';
import '../../styles/widgets/materials/material_widget_styles.dart';
import 'material_preview.dart';

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
  // Format Upload Date
  // ============================================================

  String _formatUploadDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
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

          border: Border(
            left: BorderSide(
              color: Color(0xFF0D47A1), // your app's dark blue
              width: 4,
            ),
          ),
        ),

        // ==================================================
        // STACK FOR TOP-RIGHT 3 DOTS
        // ==================================================

        child: Stack(
          children: [

            // ==================================================
            // MAIN CONTENT
            // ==================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center,

              children: [

                // Material Preview
                MaterialPreview(
                  material: material,
                ),

                const SizedBox(
                  width: MaterialWidgetStyles.materialIconTextSpacing,
                ),

                // Material Information
                Expanded(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      // Material Title
                      Transform.translate(
                      offset: const Offset(0, -20),
                      child: Text(
                        material.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MaterialWidgetStyles.materialTitleStyle,
                      ),
                    ),

                      const SizedBox(
                        height: 8,
                      ),

                      // Subject
                      Transform.translate(
                      offset: const Offset(0, -15),
                      child: Text(
                        material.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MaterialWidgetStyles.materialSubjectStyle,
                      ),
                    ),

                      const SizedBox(
                        height: 6,
                      ),

                      // Upload Date
                      Transform.translate(
                        offset: const Offset(0, 10),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatUploadDate(material.uploadDate),
                              style: MaterialWidgetStyles.materialDateStyle,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Extra space so text does not overlap the 3 dots
                const SizedBox(width: 30),
              ],
            ),

            // ==================================================
            // 3 DOTS AT TOP-RIGHT
            // ==================================================

           Positioned(
            top: -15,
            right: -20,
            child: PopupMenuButton<String>(
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

                        SizedBox(width: 10),

                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
                        ),

            // ==================================================
            // PREVIEW ARROW AT BOTTOM-RIGHT
            // ==================================================

            Positioned(
              bottom: 10,
              right: 4,
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 22,
                    color: Color(0xFF0D47A1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}