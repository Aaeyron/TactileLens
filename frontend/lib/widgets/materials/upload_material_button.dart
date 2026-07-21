import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/materials/material_service.dart';
import '../../styles/screens/materials/material_styles.dart';

class UploadMaterialButton extends StatefulWidget {
  const UploadMaterialButton({
    super.key,
  });

  @override
  State<UploadMaterialButton> createState() =>
      _UploadMaterialButtonState();
}

class _UploadMaterialButtonState
    extends State<UploadMaterialButton> {
  final MaterialService _materialService =
      MaterialService();

  bool _isUploading = false;

  Future<void> _uploadMaterial() async {
    // ==========================
    // Select File
    // ==========================

      final result = await FilePicker.pickFiles(
      type: FileType.custom,
        allowedExtensions: [
        'pdf',
        'jpg',
        'jpeg',
        'png',
      ],
    );

    if (result == null ||
        result.files.single.path == null) {
      return;
    }

    final File selectedFile =
        File(result.files.single.path!);

    // ==========================
    // Material Details
    // ==========================

    final titleController =
        TextEditingController();

    final subjectController =
        TextEditingController();

    final descriptionController =
        TextEditingController();

    // ==========================
    // Show Upload Dialog
    // ==========================

    if (!mounted) {
  return;
}

final uploadData =
    await showDialog<Map<String, String>>(
  context: context,
  builder: (context) {
    return AlertDialog(
      title: const Text(
        'Upload Material',
      ),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
                // ==========================
                // Selected File
                // ==========================

                Text(
                  selectedFile.path
                      .split(Platform.pathSeparator)
                      .last,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                ),

                const SizedBox(
                  height: 16,
                ),

                // ==========================
                // Title
                // ==========================

                TextField(
                  controller:
                      titleController,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Material Title',
                    border:
                        OutlineInputBorder(),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                // ==========================
                // Subject
                // ==========================

                TextField(
                  controller:
                      subjectController,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Subject',
                    border:
                        OutlineInputBorder(),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                // ==========================
                // Description
                // ==========================

                TextField(
                  controller:
                      descriptionController,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Description',
                    border:
                        OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),

          actions: [

            // ==========================
            // Cancel
            // ==========================

            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child:
                  const Text('Cancel'),
            ),

            // ==========================
            // Continue
            // ==========================

            ElevatedButton(
              onPressed: () {
                if (titleController
                        .text
                        .trim()
                        .isEmpty ||
                    subjectController
                        .text
                        .trim()
                        .isEmpty) {
                  return;
                }

                Navigator.pop(
                  context,
                  {
                    'title':
                        titleController
                            .text
                            .trim(),
                    'subject':
                        subjectController
                            .text
                            .trim(),
                    'description':
                        descriptionController
                            .text
                            .trim(),
                  },
                );
              },
              child:
                  const Text('Upload'),
            ),
          ],
        );
      },
    );

    // ==========================
    // User Cancelled
    // ==========================

    if (uploadData == null) {
      return;
    }

    // ==========================
    // Start Upload
    // ==========================

    setState(() {
      _isUploading = true;
    });

    try {
      await _materialService.uploadMaterial(
        file: selectedFile,

        // TEMPORARY USER ID
        // We will connect this to
        // SessionManager later.
        userId: 1,

        title:
            uploadData['title']!,

        subject:
            uploadData['subject']!,

        description:
            uploadData['description'],
      );

      if (!mounted) {
        return;
      }

      // ==========================
      // Success Message
      // ==========================

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Material uploaded successfully.',
          ),
        ),
      );

    } catch (error) {

      if (!mounted) {
        return;
      }

      // ==========================
      // Error Message
      // ==========================

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Upload failed: $error',
          ),
        ),
      );

    } finally {

      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return SizedBox(
      width: double.infinity,
      height:
          MaterialsStyles.uploadButtonHeight,

      child: ElevatedButton.icon(
        onPressed:
            _isUploading
                ? null
                : _uploadMaterial,

        icon: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : Icon(
                Icons
                    .upload_file_outlined,
                size: MaterialsStyles
                    .uploadButtonIconSize,
              ),

        label: Text(
          _isUploading
              ? 'Uploading...'
              : 'Upload Material',

          style: MaterialsStyles
              .uploadButtonTextStyle,
        ),

        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              MaterialsStyles
                  .uploadButtonColor,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                MaterialsStyles
                    .uploadButtonRadius,
          ),

          elevation: 0,
        ),
      ),
    );
  }
}