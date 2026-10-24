import 'package:flutter/widgets.dart';

/// How every form treats the on-screen keyboard.
///
/// The keyboard closes only when the teacher means it to: the keyboard's
/// Done button, the system Back button, or submitting the form. Scrolling
/// never closes it (with `onDrag`, a tap whose finger slid a few pixels
/// counted as a drag and closed the keyboard mid-typing), and a tap
/// outside a form dialog or sheet never closes it, so typed text is not
/// lost. Cancel and the Back button still close dialogs and sheets.
abstract final class FormKeyboard {
  /// For the scroll view that holds a form or a search field.
  static const ScrollViewKeyboardDismissBehavior dismissBehavior =
      ScrollViewKeyboardDismissBehavior.manual;

  /// For dialogs and bottom sheets that contain text fields.
  static const bool closeOnTapOutside = false;

  /// For every form field: when it is focused, it scrolls far enough above
  /// the keyboard that the error text under it (at 2x text size) is also
  /// visible. Flutter's default keeps only 20 px.
  static const EdgeInsets scrollPadding = EdgeInsets.fromLTRB(20, 20, 20, 96);
}
