import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Showing Braille on screen without splitting a word across lines.
///
/// Liblouis writes the space between words as the blank cell U+2800. In
/// Unicode line breaking that is a letter, not a space, so a long Braille
/// line was broken anywhere, in the middle of a word or a number. A
/// zero-width space after each blank cell gives the line a place to break
/// between words and is invisible.
///
/// Only what is drawn changes: saved, copied and shared Braille never
/// contains the zero-width space.
const String _blankCell = '⠀';
const String _breakOpportunity = '​';

/// [braille] ready to draw: it can wrap only between words.
String brailleForDisplay(String braille) {
  return braille.replaceAll(_blankCell, '$_blankCell$_breakOpportunity');
}

/// Undoes [brailleForDisplay], for text copied from the screen.
String brailleFromDisplay(String text) {
  return text.replaceAll(_breakOpportunity, '');
}

/// Context menu for selectable Braille drawn with [brailleForDisplay]: the
/// usual buttons, but Copy puts the Braille on the clipboard without the
/// zero-width spaces.
Widget brailleContextMenu(
  BuildContext context,
  EditableTextState editableTextState,
) {
  final List<ContextMenuButtonItem> items = editableTextState
      .contextMenuButtonItems
      .map((ContextMenuButtonItem item) {
        if (item.type != ContextMenuButtonType.copy) {
          return item;
        }

        return item.copyWith(
          onPressed: () => copyDisplayedBraille(editableTextState),
        );
      })
      .toList(growable: false);

  return AdaptiveTextSelectionToolbar.buttonItems(
    anchors: editableTextState.contextMenuAnchors,
    buttonItems: items,
  );
}

/// Copies the selected Braille without the zero-width spaces.
@visibleForTesting
Future<void> copyDisplayedBraille(EditableTextState editableTextState) async {
  final TextEditingValue value = editableTextState.textEditingValue;
  final String selected = value.selection.textInside(value.text);

  await Clipboard.setData(ClipboardData(text: brailleFromDisplay(selected)));

  editableTextState.hideToolbar();
}
