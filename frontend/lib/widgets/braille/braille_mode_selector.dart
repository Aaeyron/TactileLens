import 'package:flutter/material.dart';

import '../../models/braille/braille_mode.dart';
import '../../services/braille/braille_mode_translator.dart';
import '../../styles/widgets/braille/braille_mode_selector_styles.dart';

/// How the two modes are drawn.
enum BrailleModeSelectorLayout {
  /// Compact choice chips (History detail, Settings).
  chips,

  /// Two full buttons at least 48dp tall, the selected one filled with a
  /// check icon and the other outlined (scan result, material preview).
  buttons,
}

/// Braille 1 / Braille 2 choice with a short note when Braille 1 is not
/// available. The choices wrap, so they fit at large system font sizes.
class BrailleModeSelector extends StatelessWidget {
  const BrailleModeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.availability = BrailleModeAvailability.available,
    this.showFallbackNote = false,
    this.layout = BrailleModeSelectorLayout.chips,
  });

  final BrailleMode selected;
  final ValueChanged<BrailleMode> onChanged;
  final BrailleModeAvailability availability;
  final BrailleModeSelectorLayout layout;

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
              _buildChoice(
                label: BrailleModeSelectorStyles.uncontractedLabel,
                selected: selected == BrailleMode.uncontracted,
                onSelected: canUseBraille1
                    ? () => onChanged(BrailleMode.uncontracted)
                    : null,
              ),
              _buildChoice(
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

  Widget _buildChoice({
    required String label,
    required bool selected,
    required VoidCallback? onSelected,
  }) {
    return switch (layout) {
      BrailleModeSelectorLayout.chips => _ModeChip(
        label: label,
        selected: selected,
        onSelected: onSelected,
      ),
      BrailleModeSelectorLayout.buttons => _ModeButton(
        label: label,
        selected: selected,
        onPressed: onSelected,
      ),
    };
  }
}

/// A mode as a full button. Selected is filled with a check icon; not
/// selected is outlined with no icon, so the state does not rely on color.
class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;

  /// Null disables the button.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final Widget text = Text(
      label,
      textAlign: TextAlign.center,
      style: BrailleModeSelectorStyles.chipLabelStyle,
    );

    final Widget button = selected
        ? FilledButton.icon(
            onPressed: onPressed,
            style: BrailleModeSelectorStyles.selectedButtonStyle,
            icon: const Icon(
              BrailleModeSelectorStyles.selectedIcon,
              size: BrailleModeSelectorStyles.buttonIconSize,
            ),
            label: text,
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: BrailleModeSelectorStyles.unselectedButtonStyle,
            child: text,
          );

    // One screen reader node: the label, button role, and selected state.
    return MergeSemantics(
      child: Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: button,
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
