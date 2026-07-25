import 'package:flutter/material.dart';

import '../../styles/widgets/scan/scan_widget_styles.dart';

class ScanUploadArea extends StatelessWidget {
  const ScanUploadArea({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: ScanWidgetStyles.uploadAreaHeight,

      decoration: BoxDecoration(
        color: ScanWidgetStyles.uploadAreaColor,
        borderRadius: ScanWidgetStyles.uploadAreaRadius,
      ),

      child: const Center(
        child: Icon(
          ScanWidgetStyles.uploadAreaIcon,
          size: ScanWidgetStyles.uploadIconSize,
          color: ScanWidgetStyles.uploadIconColor,
        ),
      ),
    );
  }
}