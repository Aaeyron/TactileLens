import 'package:flutter/material.dart';

import '../../styles/widgets/common/header_braille_dots_styles.dart';

/// The decorative Braille dots shown in the corner of every header bar.
///
/// One widget for all headers, so the dots look the same everywhere.
/// Decorative only: hidden from screen readers, never tappable, no
/// animation. Fixed size ([HeaderBrailleDotsStyles.width] x
/// [HeaderBrailleDotsStyles.height]), so it never changes a header's layout.
class HeaderBrailleDots extends StatelessWidget {
  const HeaderBrailleDots({super.key});

  @override
  Widget build(BuildContext context) {
    const Widget dot = SizedBox.square(
      dimension: HeaderBrailleDotsStyles.dotSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: HeaderBrailleDotsStyles.dotColor,
          shape: BoxShape.circle,
        ),
      ),
    );

    final Widget row = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (
          int column = 0;
          column < HeaderBrailleDotsStyles.columns;
          column++
        ) ...<Widget>[
          if (column > 0)
            const SizedBox(width: HeaderBrailleDotsStyles.dotSpacing),
          dot,
        ],
      ],
    );

    return ExcludeSemantics(
      child: IgnorePointer(
        child: Opacity(
          opacity: HeaderBrailleDotsStyles.opacity,
          child: SizedBox(
            width: HeaderBrailleDotsStyles.width,
            height: HeaderBrailleDotsStyles.height,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (
                  int line = 0;
                  line < HeaderBrailleDotsStyles.rows;
                  line++
                ) ...<Widget>[
                  if (line > 0)
                    const SizedBox(height: HeaderBrailleDotsStyles.dotSpacing),
                  row,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
