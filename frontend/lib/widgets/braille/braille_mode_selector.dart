import 'package:flutter/material.dart';

import '../../models/braille/braille_mode.dart';
import '../../services/braille/braille_mode_translator.dart';
import '../../styles/widgets/braille/braille_mode_selector_styles.dart';

/// Braille 1 / Braille 2 choice with a short note when Braille 1 is not
/// available. The chips wrap, so they fit at large system font sizes.
class BrailleModeSelector extends StatelessWidget {
  const BrailleModeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.availability = BrailleModeAvailability.available,
    this.showFallbackNote = false,
  });

  final BrailleMode selected;
  final ValueChanged<BrailleMode> onChanged;
  final BrailleModeAvailability availability;

  /// Braille 1 was requested but could not be created.
  final bool showFallbackNote;

  String? get _note {
    switch (availability) {
      case BrailleModeAvailability.unsupportedPlatform:
        return BrailleModeSelectorStyles.unsupportedPlatformNote;
      case BrailleModeAvailability.noSourceText:
        return BrailleModeSelectorStyles.noSourceTextNote;
      case BrailleModeAvailability.mathOnly:
        return BrailleModeSelectorStyles.mathOnlyNote;
      case BrailleModeAvailability.available:
        return showFallbackNote ? BrailleModeSelectorStyles.fallbackNote : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? note = _note;
    final bool canUseBraille1 =
        availability == BrailleModeAvailability.available;

    return Semantics(
      container: true,
      label: BrailleModeSelectorStyles.semanticLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            spacing: BrailleModeSelectorStyles.chipSpacing,
            runSpacing: BrailleModeSelectorStyles.chipSpacing,
            children: <Widget>[
              _ModeChip(
                label: BrailleModeSelectorStyles.uncontractedLabel,
                selected: selected == BrailleMode.uncontracted,
                onSelected: canUseBraille1
                    ? () => onChanged(BrailleMode.uncontracted)
                    : null,
              ),
              _ModeChip(
                label: BrailleModeSelectorStyles.contractedLabel,
                selected: selected == BrailleMode.contracted,
                onSelected: () => onChanged(BrailleMode.contracted),
              ),
            ],
          ),
          if (note != null) ...<Widget>[
            const SizedBox(height: BrailleModeSelectorStyles.noteSpacing),
            Text(note, style: BrailleModeSelectorStyles.noteStyle),
          ],
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;

  /// Null disables the chip.
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onSelected = this.onSelected;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected == null ? null : (_) => onSelected(),
      showCheckmark: false,
      labelStyle: BrailleModeSelectorStyles.chipLabelStyle.copyWith(
        color: onSelected == null
            ? BrailleModeSelectorStyles.mutedColor
            : selected
            ? BrailleModeSelectorStyles.primaryColor
            : BrailleModeSelectorStyles.textColor,
      ),
      backgroundColor: BrailleModeSelectorStyles.surfaceColor,
      selectedColor: BrailleModeSelectorStyles.selectedBackgroundColor,
      side: BorderSide(
        color: selected
            ? BrailleModeSelectorStyles.primaryColor
            : BrailleModeSelectorStyles.outlineColor,
      ),
    );
  }
}
