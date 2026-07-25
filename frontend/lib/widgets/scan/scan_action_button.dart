import 'package:flutter/material.dart';

import '../../styles/widgets/scan/scan_widget_styles.dart';

class ScanActionButton extends StatelessWidget {
  final VoidCallback onCameraPressed;
  final VoidCallback onUploadPressed;

  const ScanActionButton({
    super.key,
    required this.onCameraPressed,
    required this.onUploadPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [

          // ============================================================
          // Upload Button (Left)
          // ============================================================

          GestureDetector(
            onTap: onUploadPressed,

            child: Container(
              width: 56,
              height: 56,

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),

              child: const Icon(
                Icons.upload_file_outlined,
                size: 28,
                color: Color(0xFF0D47A1),
              ),
            ),
          ),

          const Spacer(),

          // ============================================================
          // Camera Capture Button (Center)
          // ============================================================

          GestureDetector(
            onTap: onCameraPressed,

            child: Container(
              width: 82,
              height: 82,

              decoration: const BoxDecoration(
                color: Color(0xFF0D47A1),
                shape: BoxShape.circle,
              ),

              child: Center(
                child: Container(
                  width: 68,
                  height: 68,

                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),

                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,

                      decoration: const BoxDecoration(
                        color: Color(0xFF0D47A1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const Spacer(),

          // ============================================================
          // Empty Space (Right)
          // Keeps the capture button perfectly centered.
          // ============================================================

          const SizedBox(
            width: 56,
          ),
        ],
      ),
    );
  }
}