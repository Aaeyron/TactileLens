import 'package:flutter/material.dart';

import '../../models/materials/material_model.dart';
import '../../styles/widgets/materials/material_widget_styles.dart';
import 'material_preview.dart';

class MaterialCard extends StatelessWidget {
  const MaterialCard({
    super.key,
    required this.material,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  final MaterialModel material;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  String _formatUploadDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MaterialWidgetStyles.materialCardPadding),
      decoration: BoxDecoration(
        color: MaterialWidgetStyles.materialCardColor,
        borderRadius: MaterialWidgetStyles.materialCardRadius,
        boxShadow: MaterialWidgetStyles.materialCardShadow,
        border: const Border(
          left: BorderSide(color: Color(0xFF0D47A1), width: 4),
        ),
      ),
      child: Stack(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              MaterialPreview(material: material),
              const SizedBox(
                width: MaterialWidgetStyles.materialIconTextSpacing,
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Transform.translate(
                      offset: const Offset(0, -20),
                      child: Text(
                        material.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MaterialWidgetStyles.materialTitleStyle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Transform.translate(
                      offset: const Offset(0, -15),
                      child: Text(
                        material.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MaterialWidgetStyles.materialSubjectStyle,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Transform.translate(
                      offset: const Offset(0, 10),
                      child: Row(
                        children: <Widget>[
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
              const SizedBox(width: 48),
            ],
          ),

          // Opens the Edit and Delete actions.
          Positioned(
            top: 0,
            right: 0,
            child: SizedBox(
              width: 48,
              height: 48,
              child: PopupMenuButton<String>(
                tooltip: 'Material actions',
                padding: EdgeInsets.zero,
                position: PopupMenuPosition.over,
                color: Colors.white,
                elevation: 8,
                surfaceTintColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFF0D47A1), width: 1.2),
                ),
                icon: const Icon(
                  Icons.more_vert_rounded,
                  size: MaterialWidgetStyles.materialActionIconSize,
                  color: MaterialWidgetStyles.materialActionIconColor,
                ),
                onSelected: (String action) {
                  switch (action) {
                    case 'edit':
                      onEdit?.call();
                      break;
                    case 'delete':
                      onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) {
                  return <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF0D47A1)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: <Widget>[
                            Icon(
                              Icons.edit_outlined,
                              color: Color(0xFF0D47A1),
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Edit',
                              style: TextStyle(
                                color: Color(0xFF0D47A1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF0D47A1)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: <Widget>[
                            Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFF0D47A1),
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: Color(0xFF0D47A1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
              ),
            ),
          ),

          // Only this arrow opens the material preview.
          Positioned(
            right: 0,
            bottom: 4,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 3,
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 22,
                    color: Color(0xFF0D47A1),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
