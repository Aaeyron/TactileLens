import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/ai/scan_document_result.dart';
import 'package:mobile/models/braille/braille_mode.dart';
import 'package:mobile/services/braille/braille_mode_translator.dart';
import 'package:mobile/services/braille/offline_braille_service.dart';
import 'package:mobile/widgets/document/document_layout_view.dart';

import '../../fixtures/braille_modes.dart';

// A formula the AI service held for review (written for this test).
const String _heldLatex =
    r'$$ \begin{aligned}&2y+3\quad&Add three\\&5\quad&Answer\end{aligned} $$';
const String _heldReason =
    r'unsupported LaTeX: \quad, aligned environment; '
    'contains English text (3 words: Add, three, Answer)';

// What the AI service now sends as normalized_content for that block.
const String _heldReadable = '2y + 3 Add three\n5 Answer';

final BrailleModeFixture _text = brailleModeFixtures.first;

/// [readable] is the display text; records saved before readable text
/// existed have the LaTeX there instead.
DocumentBlock _heldBlock({String readable = _heldReadable}) {
  return DocumentBlock.fromJson(
    <String, dynamic>{
      'id': 1,
      'order': 2,
      'type': 'display_formula',
      'raw_content': _heldLatex,
      'normalized_content': readable,
      'is_text': false,
      'is_formula': true,
      'is_table': false,
      'braille_content': '',
      'braille_code': 'nemeth',
      'braille_success': false,
      'braille_error': 'Needs review: $_heldReason',
      'needs_review': true,
      'review_reason': _heldReason,
    },
    fallbackId: 1,
    fallbackOrder: 2,
  );
}

DocumentBlock _textBlock() {
  return DocumentBlock(
    id: 0,
    order: 1,
    type: 'text',
    rawContent: _text.text,
    normalizedContent: _text.text,
    boundingBox: const <double>[],
    polygonPoints: const <List<double>>[],
    isText: true,
    isFormula: false,
    isTable: false,
    tableRows: const <List<String>>[],
    brailleContent: _text.contracted,
    brailleCode: 'ueb',
    brailleSuccess: true,
    brailleError: '',
  );
}

List<DocumentPage> _pages(List<DocumentBlock> blocks) {
  return <DocumentPage>[
    DocumentPage(pageIndex: 0, width: 0, height: 0, blocks: blocks),
  ];
}

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('model', () {
    test('a held block keeps its reason through save and load', () {
      final DocumentBlock held = _heldBlock();

      expect(held.isHeldForReview, isTrue);
      expect(held.hasBraille, isFalse);

      final Map<String, dynamic> json = held.toJson();
      expect(json['needs_review'], isTrue);
      expect(json['review_reason'], _heldReason);

      final DocumentBlock reloaded = DocumentBlock.fromJson(
        json,
        fallbackId: 0,
        fallbackOrder: 0,
      );
      expect(reloaded.isHeldForReview, isTrue);
      expect(reloaded.reviewReason, _heldReason);
    });

    test('other records keep their shape', () {
      expect(_textBlock().toJson().containsKey('review_reason'), isFalse);
    });

    test('an offline needs-review flag alone is not a held block', () {
      final DocumentBlock offlineFlagged = DocumentBlock.fromJson(
        <String, dynamic>{
          'type': 'text',
          'raw_content': 'Total',
          'braille_content': '⠠⠞⠕⠞⠁⠇',
          'braille_code': 'ueb',
          'needs_review': true,
        },
        fallbackId: 0,
        fallbackOrder: 0,
      );

      expect(offlineFlagged.needsReview, isTrue);
      expect(offlineFlagged.isHeldForReview, isFalse);
    });
  });

  group('flagged offline blocks keep their Braille', () {
    // An offline text line read with low confidence (written for this test).
    DocumentBlock flagged({
      String braille = '⠠⠞⠕⠞⠁⠇⠀⠙⠥⠑',
      bool success = true,
    }) {
      return DocumentBlock(
        id: 3,
        order: 3,
        type: 'text',
        rawContent: 'Total due',
        normalizedContent: 'Total due',
        boundingBox: const <double>[],
        polygonPoints: const <List<double>>[],
        isText: true,
        isFormula: false,
        isTable: false,
        tableRows: const <List<String>>[],
        brailleContent: braille,
        brailleCode: 'ueb',
        brailleSuccess: success,
        brailleError: '',
        needsReview: true,
        reviewReason: 'low OCR confidence',
      );
    }

    test('a reason with Braille is flagged, not held', () {
      expect(flagged().isFlaggedForReview, isTrue);
      expect(flagged().isHeldForReview, isFalse);
    });

    test('a reason without Braille is still held', () {
      final DocumentBlock failed = flagged(braille: '', success: false);

      expect(failed.isHeldForReview, isTrue);
      expect(failed.isFlaggedForReview, isFalse);
      expect(_heldBlock().isHeldForReview, isTrue);
      expect(_heldBlock().isFlaggedForReview, isFalse);
    });

    testWidgets('Text and Braille shows the text, its Braille and the note', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        _host(
          TextBrailleLayoutView(
            pages: _pages(<DocumentBlock>[_textBlock(), flagged()]),
          ),
        ),
      );

      expect(find.text('Total'), findsOneWidget);
      expect(find.text('⠠⠞⠕⠞⠁⠇'), findsOneWidget);
      expect(find.text(flaggedForReviewNote), findsOneWidget);
      expect(find.text('Reason: low OCR confidence'), findsOneWidget);
      expect(find.text(heldForReviewNote), findsNothing);
      expect(
        find.bySemanticsLabel(RegExp('^Needs review: check this part')),
        findsOneWidget,
      );

      semantics.dispose();
    });

    testWidgets('the readable view shows the text and the note', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          DocumentLayoutView(
            pages: _pages(<DocumentBlock>[_textBlock(), flagged()]),
            useBraille: false,
          ),
        ),
      );

      expect(find.textContaining('Total due'), findsOneWidget);
      expect(find.text(flaggedForReviewNote), findsOneWidget);
      expect(find.text('Reason: low OCR confidence'), findsOneWidget);
    });

    testWidgets('the Braille view still includes its Braille', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          DocumentLayoutView(
            pages: _pages(<DocumentBlock>[flagged()]),
            useBraille: true,
          ),
        ),
      );

      expect(find.text('⠠⠞⠕⠞⠁⠇⠀⠙⠥⠑'), findsOneWidget);
    });
  });

  group('display', () {
    testWidgets(
      'Text and Braille shows the readable text and the note, no Braille',
      (WidgetTester tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();

        await tester.pumpWidget(
          _host(
            TextBrailleLayoutView(
              pages: _pages(<DocumentBlock>[_textBlock(), _heldBlock()]),
            ),
          ),
        );

        expect(find.text(_heldReadable), findsOneWidget);
        // The LaTeX is only shown on request.
        expect(find.text(_heldLatex), findsNothing);
        expect(find.text(heldForReviewNote), findsOneWidget);

        // TalkBack reads the readable text, not LaTeX. Selectable text is
        // exposed to screen readers as the node's value.
        final SemanticsNode readableNode = tester.getSemantics(
          find.text(_heldReadable),
        );
        expect(
          '${readableNode.label} ${readableNode.value}',
          contains('2y + 3 Add three'),
        );
        expect(
          '${readableNode.label} ${readableNode.value}',
          isNot(contains(r'\begin')),
        );
        expect(find.text('Reason: $_heldReason'), findsOneWidget);

        // TalkBack reads the note.
        expect(
          find.bySemanticsLabel(RegExp('^Needs review: no Braille')),
          findsOneWidget,
        );

        // The ordinary text block still shows its Braille.
        expect(
          find.textContaining(_text.contracted.split('⠀').first),
          findsWidgets,
        );

        semantics.dispose();
      },
    );

    testWidgets('the readable view shows the note too', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          DocumentLayoutView(
            pages: _pages(<DocumentBlock>[_textBlock(), _heldBlock()]),
            useBraille: false,
          ),
        ),
      );

      expect(find.text(_heldReadable), findsOneWidget);
      expect(find.text(heldForReviewNote), findsOneWidget);
    });

    testWidgets('Show original reveals the LaTeX and hides it again', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        _host(
          TextBrailleLayoutView(pages: _pages(<DocumentBlock>[_heldBlock()])),
        ),
      );

      expect(find.text(_heldLatex), findsNothing);
      expect(
        tester.getSemantics(find.text(showOriginalLabel)),
        isSemantics(isButton: true, label: showOriginalLabel),
      );
      expect(
        tester
            .getSize(find.widgetWithText(TextButton, showOriginalLabel))
            .height,
        greaterThanOrEqualTo(48),
      );

      await tester.tap(find.text(showOriginalLabel));
      await tester.pump();

      expect(find.text(_heldLatex), findsOneWidget);
      expect(find.text(_heldReadable), findsOneWidget);

      await tester.tap(find.text(hideOriginalLabel));
      await tester.pump();

      expect(find.text(_heldLatex), findsNothing);

      semantics.dispose();
    });

    testWidgets('older records with only LaTeX show it, without a toggle', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          TextBrailleLayoutView(
            pages: _pages(<DocumentBlock>[_heldBlock(readable: _heldLatex)]),
          ),
        ),
      );

      expect(find.text(_heldLatex), findsOneWidget);
      expect(find.text(showOriginalLabel), findsNothing);
      expect(find.text(heldForReviewNote), findsOneWidget);
    });
  });

  group('Braille 1', () {
    test('a held block is never translated and stays held', () async {
      final List<String> sent = <String>[];

      final BrailleModeTranslator translator = BrailleModeTranslator(
        translateLines: (List<String> lines, BrailleMode mode) async {
          sent.addAll(lines);
          return lines
              .map(
                (String line) => OfflineBrailleResult(
                  success: true,
                  code: 'ueb',
                  content: _text.uncontracted,
                  error: null,
                ),
              )
              .toList();
        },
        isSupported: () => true,
      );

      final BrailleModeView view = await translator.viewFor(
        _pages(<DocumentBlock>[_textBlock(), _heldBlock()]),
        BrailleMode.uncontracted,
      );

      expect(sent, <String>[_text.text]);
      expect(view.fellBack, isFalse);

      final DocumentBlock held = view.pages.single.blocks.last;
      expect(held.isHeldForReview, isTrue);
      expect(held.brailleContent, isEmpty);
    });

    test('a record with only held blocks offers no Braille 1', () {
      final BrailleModeTranslator translator = BrailleModeTranslator(
        translateLines: (List<String> lines, BrailleMode mode) async =>
            <OfflineBrailleResult>[],
        isSupported: () => true,
      );

      expect(
        translator.availabilityOf(_pages(<DocumentBlock>[_heldBlock()])),
        BrailleModeAvailability.noSourceText,
      );
    });
  });
}
