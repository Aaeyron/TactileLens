import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/ai/scan_processing_mode.dart';
import 'package:mobile/services/settings/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('a new install scans online and has not seen the notice', () async {
    expect(await SettingsService.getScanMode(), ScanProcessingMode.online);
    expect(await SettingsService.getOnlinePrivacyAccepted(), isFalse);
  });

  test('the scan mode is remembered', () async {
    await SettingsService.setScanMode(ScanProcessingMode.onDevice);
    expect(await SettingsService.getScanMode(), ScanProcessingMode.onDevice);

    await SettingsService.setScanMode(ScanProcessingMode.online);
    expect(await SettingsService.getScanMode(), ScanProcessingMode.online);
  });

  test('accepting the privacy notice is remembered', () async {
    await SettingsService.setOnlinePrivacyAccepted(true);
    expect(await SettingsService.getOnlinePrivacyAccepted(), isTrue);
  });

  test('an unknown stored mode means Online', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'settings_scan_mode': 'cloud',
    });

    expect(await SettingsService.getScanMode(), ScanProcessingMode.online);
  });

  test(
    'resetting settings forgets the mode and shows the notice again',
    () async {
      await SettingsService.setScanMode(ScanProcessingMode.onDevice);
      await SettingsService.setOnlinePrivacyAccepted(true);

      await SettingsService.resetSettings();

      expect(await SettingsService.getScanMode(), ScanProcessingMode.online);
      expect(await SettingsService.getOnlinePrivacyAccepted(), isFalse);
    },
  );
}
