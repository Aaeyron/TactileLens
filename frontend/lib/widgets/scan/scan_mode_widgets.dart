import 'package:flutter/material.dart';

import '../../models/ai/scan_document_result.dart';
import '../../models/ai/scan_processing_mode.dart';
import '../../services/ai/ai_service.dart';
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

  static const String processedOnline = 'Processed online (PaddleOCR-VL).';

  static const String processedOnDevice = 'Processed on this device.';

  static const String processedOnDeviceAfterOnline =
      'Processed on this device, because the online scan did not finish.';

  static const String onlineFailedTitle = 'Online scan did not finish';
  static const String scanLimitTitle = 'Online scan limit reached';
  static const String hostedQuotaTitle = 'Online scanning is unavailable today';

  static const String offerOnDevice =
      'You can scan this page on this device instead. On-device results may '
      'differ from online scans.';

  static const String scanOnDevice = 'Scan on this device';
  static const String notNow = 'Not now';

  static const String scanInProgress =
      'A scan is already running for your account. Wait for it to finish, '
      'then try again.';
}

/// Which mode produced [result], shown on every result.
String processedByLabel(ScanDocumentResult result) {
  if (result.processingMode == ScanProcessingMode.online) {
    return ScanModeText.processedOnline;
  }

  return result.fellBackFromOnline
      ? ScanModeText.processedOnDeviceAfterOnline
      : ScanModeText.processedOnDevice;
}

/// Title and message offering to scan on the device after [error].
({String title, String message}) onlineFailureText(AIServiceException error) {
  final String title = error.isScanLimit
      ? ScanModeText.scanLimitTitle
      : error.code == 'hosted_ocr_quota'
      ? ScanModeText.hostedQuotaTitle
      : ScanModeText.onlineFailedTitle;

  final Duration? wait = error.retryAfter;
  final String waitText = error.isScanLimit && wait != null
      ? ' Online scanning is available again in about '
            '${_minutes(wait)}.'
      : '';

  return (
    title: title,
    message: '${error.message}$waitText\n\n${ScanModeText.offerOnDevice}',
  );
}

String _minutes(Duration wait) {
  final int minutes = (wait.inSeconds / 60).ceil();
  return minutes == 1 ? '1 minute' : '$minutes minutes';
}

/// Asks whether to scan on the device after an online scan failed with a
/// fallback recommended. True only if the teacher chose it.
Future<bool> showOnlineFailedDialog(
  BuildContext context,
  AIServiceException error,
) async {
  final ({String title, String message}) text = onlineFailureText(error);

  final bool? scanOnDevice = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: ScanScreenStyles.dialogBackgroundColor,
        icon: const Icon(
          ScanScreenStyles.onlineFailedIcon,
          color: ScanScreenStyles.primaryColor,
        ),
        title: Text(text.title, style: ScanScreenStyles.dialogTitleStyle),
        content: Text(text.message, style: ScanScreenStyles.dialogBodyStyle),
        actions: <Widget>[
          TextButton(
            style: ScanScreenStyles.dialogSecondaryButtonStyle,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(ScanModeText.notNow),
          ),
          FilledButton(
            style: ScanScreenStyles.dialogPrimaryButtonStyle,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(ScanModeText.scanOnDevice),
          ),
        ],
      );
    },
  );

  return scanOnDevice ?? false;
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
