import 'package:flutter/foundation.dart';

import '../../models/braille/braille_mode.dart';

/// The default Braille mode, available synchronously to every screen so a
/// scan opens directly in the chosen mode.
abstract final class BrailleModeSettings {
  static final ValueNotifier<BrailleMode> defaultMode =
      ValueNotifier<BrailleMode>(BrailleMode.defaultMode);
}
