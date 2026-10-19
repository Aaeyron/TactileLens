import 'package:flutter/material.dart';

import '../../styles/widgets/braille/braille_mode_selector_styles.dart';

enum _CopyChoice { text, braille }

/// A compact "Copy" menu for the Text and Braille section header, so the
/// mode buttons can use the space the copy buttons had.
class TextBrailleCopyMenu extends StatelessWidget {
  const TextBrailleCopyMenu({
    super.key,
    required this.onCopyText,
    required this.onCopyBraille,
  });

  /// Null disables the item (nothing to copy).
  final VoidCallback? onCopyText;

  /// Copies the Braille mode on screen. Null disables the item, for
  /// example while Braille 1 is being prepared.
  final VoidCallback? onCopyBraille;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_CopyChoice>(
      tooltip: BrailleModeSelectorStyles.copyMenuTooltip,
      icon: const Icon(
        BrailleModeSelectorStyles.copyIcon,
        color: BrailleModeSelectorStyles.primaryColor,
      ),
      onSelected: (_CopyChoice choice) {
        switch (choice) {
          case _CopyChoice.text:
            onCopyText?.call();
          case _CopyChoice.braille:
            onCopyBraille?.call();
        }
      },
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<_CopyChoice>>[
          PopupMenuItem<_CopyChoice>(
            value: _CopyChoice.text,
            enabled: onCopyText != null,
            child: const _CopyItem(
              label: BrailleModeSelectorStyles.copyTextLabel,
            ),
          ),
          PopupMenuItem<_CopyChoice>(
            value: _CopyChoice.braille,
            enabled: onCopyBraille != null,
            child: const _CopyItem(
              label: BrailleModeSelectorStyles.copyBrailleLabel,
            ),
          ),
        ];
      },
    );
  }
}

class _CopyItem extends StatelessWidget {
  const _CopyItem({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(BrailleModeSelectorStyles.copyIcon, size: 20),
        const SizedBox(width: BrailleModeSelectorStyles.chipSpacing),
        Flexible(child: Text(label)),
      ],
    );
  }
}
