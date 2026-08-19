import 'package:flutter/material.dart';

import '../../styles/widgets/scan/scan_upload_area_styles.dart';

class ScanUploadArea extends StatelessWidget {
  const ScanUploadArea({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: ScanUploadAreaStyles.height,
      decoration: const BoxDecoration(
        color: ScanUploadAreaStyles.backgroundColor,
        borderRadius: ScanUploadAreaStyles.borderRadius,
      ),
      child: const Center(
        child: Icon(
          ScanUploadAreaStyles.icon,
          size: ScanUploadAreaStyles.iconSize,
          color: ScanUploadAreaStyles.iconColor,
        ),
      ),
    );
  }
}
