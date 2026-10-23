import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'models/braille/braille_mode.dart';
import 'services/settings/braille_mode_settings.dart';
import 'services/settings/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The app is portrait only, whatever the phone's rotation setting.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  // Known before the first screen, so a scan opens directly in the
  // remembered Braille mode. Missing, unreadable or slow means Braille 2,
  // so start-up can never hang here.
  try {
    BrailleModeSettings.defaultMode.value =
        await SettingsService.getBrailleMode().timeout(
          const Duration(seconds: 2),
        );
  } catch (_) {
    BrailleModeSettings.defaultMode.value = BrailleMode.defaultMode;
  }

  runApp(const TactileLensApp());
}
