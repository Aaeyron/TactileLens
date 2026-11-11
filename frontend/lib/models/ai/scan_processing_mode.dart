/// Where a scan is processed.
///
/// Online scans go through the TactileLens server and PaddleOCR-VL;
/// on-device scans use the bundled ONNX models and never leave the phone.
/// Guests always scan on the device.
enum ScanProcessingMode {
  online('online'),
  onDevice('on_device');

  const ScanProcessingMode(this.wireName);

  /// Stored in settings.
  final String wireName;

  /// Missing or unknown values mean [online], the default for signed-in
  /// users.
  static ScanProcessingMode fromWireName(Object? value) {
    return ScanProcessingMode.values.firstWhere(
      (ScanProcessingMode mode) => mode.wireName == value,
      orElse: () => ScanProcessingMode.online,
    );
  }

  /// Start of the pipeline version on-device scans save
  /// (`OfflineOcrService.pipelineVersion`, 'offline-onnx-v1').
  static const String onDevicePipelinePrefix = 'offline-';

  /// Where a saved scan was processed, from its stored pipeline version:
  /// on-device versions start with [onDevicePipelinePrefix], any other
  /// version came from the server. Null for records saved without one.
  static ScanProcessingMode? fromPipelineVersion(String? pipelineVersion) {
    final String version = pipelineVersion?.trim() ?? '';

    if (version.isEmpty) {
      return null;
    }

    return version.startsWith(onDevicePipelinePrefix)
        ? ScanProcessingMode.onDevice
        : ScanProcessingMode.online;
  }
}
