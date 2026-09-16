import 'package:shared_preferences/shared_preferences.dart';

enum AppTextSize { defaultSize, large, extraLarge }

enum RecognitionPreference { faster, moreAccurate }

class SettingsService {
  SettingsService._();

  static const String _textSizeKey = 'settings_text_size';
  static const String _highContrastKey = 'settings_high_contrast';
  static const String _reduceAnimationsKey = 'settings_reduce_animations';
  static const String _hapticFeedbackKey = 'settings_haptic_feedback';
  static const String _preserveLayoutKey = 'settings_preserve_layout';
  static const String _autoSaveScansKey = 'settings_auto_save_scans';
  static const String _contractedUebKey = 'settings_contracted_ueb';
  static const String _recognitionPreferenceKey =
      'settings_recognition_preference';

  static Future<SharedPreferences> get _preferences async {
    return SharedPreferences.getInstance();
  }

  // ==========================
  // Text Size
  // ==========================

  static Future<AppTextSize> getTextSize() async {
    final SharedPreferences preferences = await _preferences;
    final String? storedValue = preferences.getString(_textSizeKey);

    return AppTextSize.values.firstWhere(
      (AppTextSize value) => value.name == storedValue,
      orElse: () => AppTextSize.defaultSize,
    );
  }

  static Future<void> setTextSize(AppTextSize value) async {
    final SharedPreferences preferences = await _preferences;
    await preferences.setString(_textSizeKey, value.name);
  }

  // ==========================
  // Accessibility
  // ==========================

  static Future<bool> getHighContrastEnabled() async {
    final SharedPreferences preferences = await _preferences;
    return preferences.getBool(_highContrastKey) ?? false;
  }

  static Future<void> setHighContrastEnabled(bool value) async {
    final SharedPreferences preferences = await _preferences;
    await preferences.setBool(_highContrastKey, value);
  }

  static Future<bool> getReduceAnimationsEnabled() async {
    final SharedPreferences preferences = await _preferences;
    return preferences.getBool(_reduceAnimationsKey) ?? false;
  }

  static Future<void> setReduceAnimationsEnabled(bool value) async {
    final SharedPreferences preferences = await _preferences;
    await preferences.setBool(_reduceAnimationsKey, value);
  }

  static Future<bool> getHapticFeedbackEnabled() async {
    final SharedPreferences preferences = await _preferences;
    return preferences.getBool(_hapticFeedbackKey) ?? true;
  }

  static Future<void> setHapticFeedbackEnabled(bool value) async {
    final SharedPreferences preferences = await _preferences;
    await preferences.setBool(_hapticFeedbackKey, value);
  }

  // ==========================
  // Scanning
  // ==========================

  static Future<bool> getPreserveLayoutEnabled() async {
    final SharedPreferences preferences = await _preferences;
    return preferences.getBool(_preserveLayoutKey) ?? true;
  }

  static Future<void> setPreserveLayoutEnabled(bool value) async {
    final SharedPreferences preferences = await _preferences;
    await preferences.setBool(_preserveLayoutKey, value);
  }

  static Future<bool> getAutoSaveScansEnabled() async {
    final SharedPreferences preferences = await _preferences;
    return preferences.getBool(_autoSaveScansKey) ?? true;
  }

  static Future<void> setAutoSaveScansEnabled(bool value) async {
    final SharedPreferences preferences = await _preferences;
    await preferences.setBool(_autoSaveScansKey, value);
  }

  static Future<RecognitionPreference> getRecognitionPreference() async {
    final SharedPreferences preferences = await _preferences;
    final String? storedValue = preferences.getString(
      _recognitionPreferenceKey,
    );

    return RecognitionPreference.values.firstWhere(
      (RecognitionPreference value) => value.name == storedValue,
      orElse: () => RecognitionPreference.faster,
    );
  }

  static Future<void> setRecognitionPreference(
    RecognitionPreference value,
  ) async {
    final SharedPreferences preferences = await _preferences;
    await preferences.setString(_recognitionPreferenceKey, value.name);
  }

  // ==========================
  // Braille
  // ==========================

  static Future<bool> getContractedUebEnabled() async {
    final SharedPreferences preferences = await _preferences;
    return preferences.getBool(_contractedUebKey) ?? false;
  }

  static Future<void> setContractedUebEnabled(bool value) async {
    final SharedPreferences preferences = await _preferences;
    await preferences.setBool(_contractedUebKey, value);
  }

  // ==========================
  // Reset
  // ==========================

  static Future<void> resetSettings() async {
    final SharedPreferences preferences = await _preferences;

    await Future.wait(<Future<bool>>[
      preferences.remove(_textSizeKey),
      preferences.remove(_highContrastKey),
      preferences.remove(_reduceAnimationsKey),
      preferences.remove(_hapticFeedbackKey),
      preferences.remove(_preserveLayoutKey),
      preferences.remove(_autoSaveScansKey),
      preferences.remove(_contractedUebKey),
      preferences.remove(_recognitionPreferenceKey),
    ]);
  }
}
