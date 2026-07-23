import 'package:flutter/material.dart';
import '../../styles/screens/scan/scan_screen_styles.dart';
import '../../widgets/app_header.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {

   return Scaffold(
  backgroundColor: ScanScreenStyles.backgroundColor,

     body: Column(
        children: [

          const AppHeader(),

          Expanded(
            child: SingleChildScrollView(
              padding: ScanScreenStyles.contentPadding,

              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              const SizedBox(
                height: ScanScreenStyles.topContentSpacing,
              ),

            const Text(
              "Scan Material",
              style: ScanScreenStyles.pageTitleStyle,
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              "Upload or capture learning materials for OCR recognition and Nemeth Braille translation.",
              style: ScanScreenStyles.pageDescriptionStyle,
            ),


            const SizedBox(
              height: ScanScreenStyles.sectionSpacing,
            ),


            // ==============================
            // Upload Area
            // ==============================

            Container(
              width: double.infinity,
             height: ScanScreenStyles.uploadAreaHeight,

              decoration: BoxDecoration(
                color: ScanScreenStyles.uploadAreaColor,

               borderRadius:
                  ScanScreenStyles.uploadAreaRadius,
              ),


              child: const Center(
                child: Icon(
                  Icons.document_scanner_outlined,
                 size: ScanScreenStyles.uploadIconSize,
                  color: ScanScreenStyles.uploadIconColor,
                ),
              ),
            ),


            const SizedBox(
              height: ScanScreenStyles.sectionSpacing,
            ),

            // ==============================
            // Buttons
            // ==============================

            Row(
              children: [

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.camera_alt_outlined,
                    ),
                    label: const Text(
                      "Camera",
                    ),
                  ),
                ),


                const SizedBox(
                  width: 12,
                ),


                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.upload_file_outlined,
                    ),
                    label: const Text(
                      "Upload",
                    ),
                  ),
                ),

                ],
               ),

              ],
             ),
           ),
          ),
        ],
      ),
    );
  }
}