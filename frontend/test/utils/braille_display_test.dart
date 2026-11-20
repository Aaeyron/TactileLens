import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/utils/braille_display.dart';

/// "A rectangle has a length of 12 centimeters and a width of 5
/// centimeters." in Braille 2, as Liblouis writes it (U+2800 between
/// words).
const String _sentence =
    '⠠⠁⠀⠗⠑⠉⠞⠁⠝⠛⠇⠑⠀⠓⠁⠎⠀⠁⠀⠇⠢⠛⠹⠀⠷⠀⠼⠁⠃⠀⠉⠢⠞⠊⠍⠑⠞⠻⠎⠀⠯⠀⠁⠀⠺⠊⠙⠹⠀⠷⠀⠼⠑⠀'
    '⠉⠢⠞⠊⠍⠑⠞⠻⠎⠲';

/// The lines [text] is broken into at [width] logical pixels.
List<String> _lines(String text, double width) {
  final TextPainter painter = TextPainter(
    text: TextSpan(text: text, style: const TextStyle(fontSize: 20)),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: width);

  final List<String> lines = <String>[];
  int offset = 0;

  while (offset < text.length) {
    final TextRange range = painter.getLineBoundary(
      TextPosition(offset: offset),
    );
    lines.add(text.substring(range.start, range.end));
    if (range.end <= offset) {
      break;
    }
    offset = range.end;
  }

  painter.dispose();
  return lines;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('before: Flutter splits Braille words across lines', () {
    // Shows the problem this fixes: some line ends inside a word.
    final List<String> lines = _lines(_sentence, 300);

    expect(lines.length, greaterThan(1));
    expect(
      lines.take(lines.length - 1).any((String line) => !line.endsWith('⠀')),
      isTrue,
    );
  });

  // Wide enough for the longest word (10 cells); a narrower line has to
  // break inside that word whatever we do.
  for (final double width in <double>[220, 300, 400]) {
    test('displayed Braille only breaks between words ($width px)', () {
      final String displayed = brailleForDisplay(_sentence);
      final List<String> lines = _lines(displayed, width);

      expect(lines.length, greaterThan(1));

      // Every line but the last ends at a blank cell (+ the invisible break).
      for (final String line in lines.take(lines.length - 1)) {
        expect(brailleFromDisplay(line), endsWith('⠀'), reason: line);
      }

      // Nothing lost or added once the break marks are removed.
      expect(brailleFromDisplay(lines.join()), _sentence);
    });
  }

  test('display marks are removed again exactly', () {
    for (final String braille in <String>[
      _sentence,
      '',
      '⠼⠁⠃',
      '⠼⠁⠲⠀⠠⠁⠙⠙⠀⠮⠀⠝⠥⠍⠃⠻⠎⠲\n⠼⠃⠲⠀⠠⠎⠥⠃⠞⠗⠁⠉⠞⠲',
    ]) {
      expect(brailleFromDisplay(brailleForDisplay(braille)), braille);
    }
  });

  testWidgets('Copy from selectable Braille gives the Braille unchanged', (
    WidgetTester tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SelectableText(
            brailleForDisplay(_sentence),
            contextMenuBuilder: brailleContextMenu,
          ),
        ),
      ),
    );

    final EditableTextState state = tester.state<EditableTextState>(
      find.byType(EditableText),
    );
    state.selectAll(SelectionChangedCause.toolbar);
    await tester.pump();

    await copyDisplayedBraille(state);

    expect(copied, _sentence);
    expect(copied, isNot(contains('​')));
  });
}
