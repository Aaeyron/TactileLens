import 'package:flutter/material.dart';

import '../../models/ai/scan_processing_mode.dart';
import '../../styles/screens/scan/scan_screen_styles.dart';

abstract final class ScanModeText {
  static const String onlineLabel = 'Online';
  static const String onDeviceLabel = 'On-device';

  static const String selectorLabel = 'Where to scan';

  static const String onlineHint =
      'Scanned on the TactileLens server. Needs internet; can take up to '
      '3 minutes.';

  static const String onDeviceHint =
      'Scanned on this phone. Works without internet; results may differ '
      'from online scans.';

  static const String guestHint =
      'Guest scans are always processed on this phone.';

  static const String privacyTitle = 'Online scanning';

  static const String privacyMessage =
      'Online scans are processed by a third-party service. For sensitive '
      'documents, use On-device.';

  static const String continueOnline = 'Continue online';
  static const String useOnDevice = 'Use On-device';
}

/// Online / On-device choice for signed-in teachers.
class ScanModeSelector extends StatelessWidget {
  const ScanModeSelector({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final ScanProcessingMode mode;
  final ValueChanged<ScanProcessingMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          label: ScanModeText.selectorLabel,
          container: true,
          child: SegmentedButton<ScanProcessingMode>(
            style: ScanScreenStyles.scanModeButtonStyle,
            showSelectedIcon: false,
            segments: const <ButtonSegment<ScanProcessingMode>>[
              ButtonSegment<ScanProcessingMode>(
                value: ScanProcessingMode.online,
                icon: Icon(ScanScreenStyles.onlineModeIcon),
                label: Text(ScanModeText.onlineLabel),
              ),
              ButtonSegment<ScanProcessingMode>(
                value: ScanProcessingMode.onDevice,
                icon: Icon(ScanScreenStyles.onDeviceModeIcon),
                label: Text(ScanModeText.onDeviceLabel),
              ),
            ],
            selected: <ScanProcessingMode>{mode},
            onSelectionChanged: (Set<ScanProcessingMode> selection) {
              onChanged(selection.single);
            },
          ),
        ),
        const SizedBox(height: ScanScreenStyles.scanModeSpacing),
        Text(
          mode == ScanProcessingMode.online
              ? ScanModeText.onlineHint
              : ScanModeText.onDeviceHint,
          textAlign: TextAlign.center,
          style: ScanScreenStyles.scanModeHintStyle,
        ),
      ],
    );
  }
}

/// Shown before the first online scan. Returns the mode the teacher
/// picked, or null if they closed the notice without choosing.
Future<ScanProcessingMode?> showOnlinePrivacyNotice(BuildContext context) {
  return showDialog<ScanProcessingMode>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: ScanScreenStyles.dialogBackgroundColor,
        icon: const Icon(
          ScanScreenStyles.privacyNoticeIcon,
          color: ScanScreenStyles.primaryColor,
        ),
        title: const Text(
          ScanModeText.privacyTitle,
          style: ScanScreenStyles.dialogTitleStyle,
        ),
        content: const Text(
          ScanModeText.privacyMessage,
          style: ScanScreenStyles.dialogBodyStyle,
        ),
        actions: <Widget>[
          TextButton(
            style: ScanScreenStyles.dialogSecondaryButtonStyle,
            onPressed: () {
              Navigator.of(dialogContext).pop(ScanProcessingMode.onDevice);
            },
            child: const Text(ScanModeText.useOnDevice),
          ),
          FilledButton(
            style: ScanScreenStyles.dialogPrimaryButtonStyle,
            onPressed: () {
              Navigator.of(dialogContext).pop(ScanProcessingMode.online);
            },
            child: const Text(ScanModeText.continueOnline),
          ),
        ],
      );
    },
  );
}
