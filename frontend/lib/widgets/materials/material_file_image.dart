import 'package:flutter/material.dart';

import '../../services/materials/material_service.dart';

class MaterialFileImage extends StatefulWidget {
  const MaterialFileImage({
    super.key,
    required this.materialId,
    required this.fit,
    required this.errorBuilder,
    this.cacheWidth,
  });

  final int materialId;
  final BoxFit fit;
  final ImageErrorWidgetBuilder errorBuilder;

  /// Decode width in physical pixels. Set it for small previews so the
  /// image is not decoded at full resolution.
  final int? cacheWidth;

  @override
  State<MaterialFileImage> createState() => _MaterialFileImageState();
}

class _MaterialFileImageState extends State<MaterialFileImage> {
  final MaterialService _materialService = MaterialService();
  late final Future<Map<String, String>> _headersFuture;

  @override
  void initState() {
    super.initState();
    _headersFuture = _materialService.getMaterialFileHeaders();
  }

  @override
  void dispose() {
    _materialService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _headersFuture,
      builder:
          (BuildContext context, AsyncSnapshot<Map<String, String>> snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData) {
              return widget.errorBuilder(
                context,
                snapshot.error ?? StateError('The file could not be loaded.'),
                null,
              );
            }

            return Image.network(
              _materialService.getMaterialFileUrl(widget.materialId),
              headers: snapshot.data,
              cacheWidth: widget.cacheWidth,
              fit: widget.fit,
              errorBuilder: widget.errorBuilder,
            );
          },
    );
  }
}
