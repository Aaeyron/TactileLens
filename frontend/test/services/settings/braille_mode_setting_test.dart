import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/braille/braille_mode.dart';
import 'package:mobile/services/settings/braille_mode_settings.dart';
import 'package:mobile/services/settings/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    BrailleModeSettings.defaultMode.value = BrailleMode.defaultMode;
  });

  test('the default mode is Braille 2', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    expect(await SettingsService.getBrailleMode(), BrailleMode.contracted);
  });

  test('the old Contracted UEB switch value is ignored', () async {
    // The old switch defaulted to "off" but never changed translation, so
    // its value must not turn on Braille 1.
    SharedPreferences.setMockInitialValues(<String, Object>{
      'settings_contracted_ueb': false,
    });

    expect(await SettingsService.getBrailleMode(), BrailleMode.contracted);
  });

  test('a chosen mode is remembered and becomes the default', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await SettingsService.setBrailleMode(BrailleMode.uncontracted);

    final SharedPreferences preferences = await SharedPreferences.getInstance();

    expect(preferences.getString('settings_braille_mode'), 'uncontracted');
    expect(await SettingsService.getBrailleMode(), BrailleMode.uncontracted);
    expect(BrailleModeSettings.defaultMode.value, BrailleMode.uncontracted);
  });

  test('an unknown stored value means Braille 2', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'settings_braille_mode': 'grade-3',
    });

    expect(await SettingsService.getBrailleMode(), BrailleMode.contracted);
  });

  test('resetting settings returns to Braille 2', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'settings_braille_mode': 'uncontracted',
      'settings_contracted_ueb': true,
    });
    BrailleModeSettings.defaultMode.value = BrailleMode.uncontracted;

    await SettingsService.resetSettings();

    final SharedPreferences preferences = await SharedPreferences.getInstance();

    expect(preferences.containsKey('settings_braille_mode'), isFalse);
    expect(preferences.containsKey('settings_contracted_ueb'), isFalse);
    expect(BrailleModeSettings.defaultMode.value, BrailleMode.contracted);
    expect(await SettingsService.getBrailleMode(), BrailleMode.contracted);
  });
}
