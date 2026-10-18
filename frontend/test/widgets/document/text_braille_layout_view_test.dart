import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/ai/scan_document_result.dart';
import 'package:mobile/widgets/document/document_layout_view.dart';

// Real Liblouis output (en-ueb-g2.ctb with unicode.dis), where each space
// between words is one blank cell (U+2800).
const String _sentence = 'Solve for the value of x and the answer.';
const String _sentenceBraille = '⠠⠎⠕⠇⠧⠑⠀⠿⠀⠮⠀⠧⠁⠇⠥⠑⠀⠷⠀⠰⠭⠀⠯⠀⠮⠀⠁⠝⠎⠺⠻⠲';

const String _twoLines = 'Step one\n2. Next line';
const String _twoLinesBraille = '⠠⠌⠑⠏⠀⠐⠕\n⠼⠃⠲⠀⠠⠝⠑⠭⠞⠀⠇⠔⠑';

DocumentBlock _block({
  required String content,
  required String braille,
  String type = 'text',
  String code = 'ueb',
  bool isFormula = false,
}) {
  return DocumentBlock(
    id: 0,
    order: 0,
    type: type,
    rawContent: content,
    normalizedContent: content,
    boundingBox: const <double>[],
    polygonPoints: const <List<double>>[],
    isText: !isFormula,
    isFormula: isFormula,
    isTable: false,
    tableRows: const <List<String>>[],
    brailleContent: braille,
    brailleCode: code,
    brailleSuccess: braille.isNotEmpty,
    brailleError: '',
  );
}

List<DocumentPage> _pages(List<DocumentBlock> blocks) {
  return <DocumentPage>[
    DocumentPage(pageIndex: 0, width: 0, height: 0, blocks: blocks),
  ];
}

Widget _host(
  List<DocumentBlock> blocks, {
  double width = 360,
  double textScale = 1,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(width, 2000),
        textScaler: TextScaler.linear(textScale),
      ),
      child: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: width,
            child: TextBrailleLayoutView(pages: _pages(blocks)),
          ),
        ),
      ),
    ),
  );
}

/// The Braille of each word starts in the word's column, directly below it.
void _expectBrailleBeneathWords(
  WidgetTester tester,
  List<WordBraillePair> pairs,
) {
  // Words like "the" appear more than once; match the n-th occurrence.
  final Map<String, int> seen = <String, int>{};

  int occurrence(String value) {
    final int index = seen[value] ?? 0;
    seen[value] = index + 1;
    return index;
  }

  for (final WordBraillePair pair in pairs) {
    final Rect word = tester.getRect(
      find.text(pair.word).at(occurrence(pair.word)),
    );
    final Rect braille = tester.getRect(
      find.text(pair.braille).at(occurrence(pair.braille)),
    );

    expect(braille.left, word.left, reason: '"${pair.word}" column');
    expect(braille.top, greaterThanOrEqualTo(word.bottom));
  }
}

void main() {
  group('pairWordsWithBraille', () {
    test('pairs each word with the Braille group in the same place', () {
      final List<List<WordBraillePair>>? lines = pairWordsWithBraille(
        _sentence,
        _sentenceBraille,
      );

      expect(lines, hasLength(1));
      expect(lines!.single, hasLength(9));
      expect(lines.single.first, (word: 'Solve', braille: '⠠⠎⠕⠇⠧⠑'));
      expect(lines.single[1], (word: 'for', braille: '⠿'));
      expect(lines.single.last, (word: 'answer.', braille: '⠁⠝⠎⠺⠻⠲'));
    });

    test('keeps the lines of the text', () {
      final List<List<WordBraillePair>>? lines = pairWordsWithBraille(
        _twoLines,
        _twoLinesBraille,
      );

      expect(lines, hasLength(2));
      expect(lines![0].map((WordBraillePair pair) => pair.word), <String>[
        'Step',
        'one',
      ]);
      expect(lines[1].first, (word: '2.', braille: '⠼⠃⠲'));
    });

    test('treats repeated blank cells and spaces as one gap', () {
      expect(
        pairWordsWithBraille('Hello   world', '⠠⠓⠑⠇⠇⠕⠀⠀⠀⠸⠺'),
        <List<WordBraillePair>>[
          <WordBraillePair>[
            (word: 'Hello', braille: '⠠⠓⠑⠇⠇⠕'),
            (word: 'world', braille: '⠸⠺'),
          ],
        ],
      );
    });

    test('returns null when the counts differ', () {
      expect(pairWordsWithBraille('one two three', '⠐⠕⠀⠞⠺⠕'), isNull);
      expect(pairWordsWithBraille('', ''), isNull);
    });
  });

  testWidgets('UEB text shows each word with its Braille beneath', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(<DocumentBlock>[
        _block(content: _sentence, braille: _sentenceBraille),
      ]),
    );

    final List<WordBraillePair> pairs = pairWordsWithBraille(
      _sentence,
      _sentenceBraille,
    )!.single;

    _expectBrailleBeneathWords(tester, pairs);

    // The whole Braille string is never shown as one piece here.
    expect(find.text(_sentenceBraille), findsNothing);
  });

  testWidgets('a block whose counts differ is shown as one unit', (
    WidgetTester tester,
  ) async {
    const String shortBraille = '⠠⠎⠕⠇⠧⠑⠀⠿⠀⠮';

    await tester.pumpWidget(
      _host(<DocumentBlock>[_block(content: _sentence, braille: shortBraille)]),
    );

    expect(find.text(shortBraille), findsOneWidget);
    expect(find.text('⠠⠎⠕⠇⠧⠑'), findsNothing);

    // The text is above its Braille.
    final Rect braille = tester.getRect(find.text(shortBraille));
    final Rect text = tester.getRect(find.byType(SelectableText));

    expect(braille.top, greaterThanOrEqualTo(text.bottom));
  });

  testWidgets('a formula keeps its rendered view with its Braille beneath', (
    WidgetTester tester,
  ) async {
    const String nemeth = '⠰⠭⠀⠬⠀⠼⠆⠀⠀⠨⠅⠀⠀⠼⠢';

    await tester.pumpWidget(
      _host(<DocumentBlock>[
        _block(
          content: r'x + 2 = 5',
          braille: nemeth,
          type: 'display_formula',
          code: 'nemeth',
          isFormula: true,
        ),
      ]),
    );

    expect(find.byType(Math), findsOneWidget);
    expect(find.text(nemeth), findsOneWidget);
    expect(find.text('⠰⠭'), findsNothing);

    expect(
      tester.getRect(find.text(nemeth)).top,
      greaterThanOrEqualTo(tester.getRect(find.byType(Math)).bottom),
    );
  });

  testWidgets('at the largest font size words wrap with their Braille', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        <DocumentBlock>[_block(content: _sentence, braille: _sentenceBraille)],
        width: 320,
        textScale: 2,
      ),
    );

    // A layout overflow would fail the test here.
    expect(tester.takeException(), isNull);

    final List<WordBraillePair> pairs = pairWordsWithBraille(
      _sentence,
      _sentenceBraille,
    )!.single;

    _expectBrailleBeneathWords(tester, pairs);

    final double firstRowTop = tester.getRect(find.text('Solve')).top;
    final double lastRowTop = tester.getRect(find.text('answer.')).top;

    expect(lastRowTop, greaterThan(firstRowTop), reason: 'words wrapped');
  });

  testWidgets('screen readers read each word but not its Braille', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _host(<DocumentBlock>[
        _block(content: _sentence, braille: _sentenceBraille),
      ]),
    );

    expect(find.bySemanticsLabel('Solve'), findsOneWidget);
    expect(find.bySemanticsLabel('answer.'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('[⠁-⣿]')), findsNothing);

    semantics.dispose();
  });

  test('only pages with per-block Braille use the combined view', () {
    expect(
      TextBrailleLayoutView.canDisplay(
        _pages(<DocumentBlock>[_block(content: _sentence, braille: '')]),
      ),
      isFalse,
    );
    expect(
      TextBrailleLayoutView.canDisplay(
        _pages(<DocumentBlock>[
          _block(content: _sentence, braille: _sentenceBraille),
        ]),
      ),
      isTrue,
    );
  });
}
