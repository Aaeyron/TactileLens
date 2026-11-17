import 'package:flutter/material.dart';

import '../../models/ai/scan_processing_mode.dart';
import '../../styles/screens/history/history_screen_styles.dart';

/// Where a saved scan was processed: "Online" or "On this device".
///
/// On a History card it is a short line under the date; with [detailed]
/// it is the full sentence for the scan's details. The icon is
/// decorative; TalkBack reads "Scanned online" / "Scanned on this device".
class HistoryScanSource extends StatelessWidget {
  const HistoryScanSource({
    super.key,
    required this.mode,
    this.detailed = false,
  });

  static const String onlineLabel = 'Online';
  static const String onDeviceLabel = 'On this device';

  static const String onlineDetail = 'Processed online';
  static const String onDeviceDetail = 'Processed on this device';

  static const String onlineSemantics = 'Scanned online';
  static const String onDeviceSemantics = 'Scanned on this device';

  final ScanProcessingMode mode;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    final bool online = mode == ScanProcessingMode.online;

    final String text = detailed
        ? (online ? onlineDetail : onDeviceDetail)
        : (online ? onlineLabel : onDeviceLabel);

    final TextStyle style = detailed
        ? HistoryScreenStyles.detailSourceStyle
        : HistoryScreenStyles.cardSourceStyle;

    return Semantics(
      label: online ? onlineSemantics : onDeviceSemantics,
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            online
                ? HistoryScreenStyles.onlineSourceIcon
                : HistoryScreenStyles.onDeviceSourceIcon,
            size: HistoryScreenStyles.sourceIconSize,
            color: HistoryScreenStyles.textSecondaryColor,
          ),
          const SizedBox(width: HistoryScreenStyles.sourceIconSpacing),
          // Wraps rather than cutting "On this device" short at large text.
          Flexible(child: Text(text, style: style)),
        ],
      ),
    );
  }
}
