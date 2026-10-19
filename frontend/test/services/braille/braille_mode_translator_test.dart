import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/ai/scan_document_result.dart';
import 'package:mobile/models/braille/braille_mode.dart';
import 'package:mobile/services/braille/braille_mode_translator.dart';
import 'package:mobile/services/braille/braille_save_payload.dart';
import 'package:mobile/services/braille/offline_braille_service.dart';
import 'package:mobile/widgets/document/document_layout_view.dart';

import '../../fixtures/braille_modes.dart';

const String _nemeth = '⠰⠭⠀⠬⠀⠼⠆⠀⠀⠨⠅⠀⠀⠼⠢';

DocumentBlock _ueb(String text, String braille, {int id = 0}) {
  return DocumentBlock(
    id: id,
    order: id,
    type: 'text',
    rawContent: text,
    normalizedContent: text,
    boundingBox: const <double>[],
    polygonPoints: const <List<double>>[],
    isText: true,
    isFormula: false,
    isTable: false,
    tableRows: const <List<String>>[],
    brailleContent: braille,
    brailleCode: 'ueb',
    brailleSuccess: braille.isNotEmpty,
    brailleError: '',
  );
}

DocumentBlock _formula() {
  return const DocumentBlock(
    id: 9,
    order: 9,
    type: 'display_formula',
    rawContent: 'x + 2 = 5',
    normalizedContent: 'x + 2 = 5',
    boundingBox: <double>[],
    polygonPoints: <List<double>>[],
    isText: false,
    isFormula: true,
    isTable: false,
    tableRows: <List<String>>[],
    brailleContent: _nemeth,
    brailleCode: 'nemeth',
    brailleSuccess: true,
    brailleError: '',
  );
}

List<DocumentPage> _pages(List<DocumentBlock> blocks) {
  return <DocumentPage>[
    DocumentPage(pageIndex: 0, width: 0, height: 0, blocks: blocks),
  ];
}

/// A translator that answers from the fixtures (Liblouis 3.38.0 output)
/// and records every batch it receives.
class _FixtureTranslator {
  final List<List<String>> batches = <List<String>>[];

  Future<List<OfflineBrailleResult>> call(
    List<String> lines,
    BrailleMode mode,
  ) async {
    batches.add(List<String>.of(lines));

    return lines.map((String line) {
      final BrailleModeFixture fixture = brailleModeFixtures.firstWhere(
        (BrailleModeFixture item) => item.text == line,
      );

      return OfflineBrailleResult(
        success: true,
        code: 'ueb',
        content: mode == BrailleMode.uncontracted
            ? fixture.uncontracted
            : fixture.contracted,
        error: null,
      );
    }).toList();
  }
}

BrailleModeTranslator _translator(
  _FixtureTranslator fake, {
  bool supported = true,
  int batchSize = 64,
}) {
  return BrailleModeTranslator(
    translateLines: fake.call,
    isSupported: () => supported,
    batchSize: batchSize,
  );
}

void main() {
  final List<DocumentBlock> fixtureBlocks = <DocumentBlock>[
    for (int index = 0; index < brailleModeFixtures.length; index++)
      _ueb(
        brailleModeFixtures[index].text,
        brailleModeFixtures[index].contracted,
        id: index,
      ),
  ];

  group('Braille 2', () {
    test('returns the stored pages untouched, without translating', () async {
      final _FixtureTranslator fake = _FixtureTranslator();
      final List<DocumentPage> pages = _pages(fixtureBlocks);

      final BrailleModeView view = await _translator(
        fake,
      ).viewFor(pages, BrailleMode.contracted);

      expect(identical(view.pages, pages), isTrue);
      expect(view.mode, BrailleMode.contracted);
      expect(view.fellBack, isFalse);
      expect(fake.batches, isEmpty);
    });
  });

  group('Braille 1 (fixtures match Liblouis 3.38.0, not expert-validated)', () {
    test('every fixture sentence becomes its Braille 1', () async {
      final _FixtureTranslator fake = _FixtureTranslator();

      final BrailleModeView view = await _translator(
        fake,
      ).viewFor(_pages(fixtureBlocks), BrailleMode.uncontracted);

      expect(view.mode, BrailleMode.uncontracted);
      expect(view.fellBack, isFalse);

      for (int index = 0; index < brailleModeFixtures.length; index++) {
        expect(
          view.pages.single.blocks[index].brailleContent,
          brailleModeFixtures[index].uncontracted,
          reason: brailleModeFixtures[index].text,
        );
      }
    });

    test('word pairing lines up in both modes for every fixture', () {
      for (final BrailleModeFixture fixture in brailleModeFixtures) {
        final int words = fixture.text.split(RegExp(r'\s+')).length;

        for (final String braille in <String>[
          fixture.uncontracted,
          fixture.contracted,
        ]) {
          final List<List<WordBraillePair>>? lines = pairWordsWithBraille(
            fixture.text,
            braille,
          );

          expect(lines, isNotNull, reason: '${fixture.text} → $braille');
          expect(lines!.single, hasLength(words));
        }
      }
    });

    test('stored blocks keep their Braille 2', () async {
      final List<DocumentPage> pages = _pages(fixtureBlocks);

      await _translator(
        _FixtureTranslator(),
      ).viewFor(pages, BrailleMode.uncontracted);

      expect(
        pages.single.blocks.first.brailleContent,
        brailleModeFixtures.first.contracted,
      );
    });

    test('Nemeth math is never changed', () async {
      final _FixtureTranslator fake = _FixtureTranslator();

      final BrailleModeView view = await _translator(fake).viewFor(
        _pages(<DocumentBlock>[fixtureBlocks.first, _formula()]),
        BrailleMode.uncontracted,
      );

      expect(view.pages.single.blocks.last.brailleContent, _nemeth);
      expect(fake.batches.expand((List<String> b) => b), isNot(contains('x')));
    });

    test('multi-line blocks are translated line by line', () async {
      final _FixtureTranslator fake = _FixtureTranslator();
      final BrailleModeFixture first = brailleModeFixtures[0];
      final BrailleModeFixture second = brailleModeFixtures[3];

      final BrailleModeView view = await _translator(fake).viewFor(
        _pages(<DocumentBlock>[
          _ueb(
            '${first.text}\n${second.text}',
            '${first.contracted}\n${second.contracted}',
          ),
        ]),
        BrailleMode.uncontracted,
      );

      expect(fake.batches.single, <String>[first.text, second.text]);
      expect(
        view.pages.single.blocks.single.brailleContent,
        '${first.uncontracted}\n${second.uncontracted}',
      );
    });

    test('lines are sent in batches', () async {
      final _FixtureTranslator fake = _FixtureTranslator();

      await _translator(
        fake,
        batchSize: 2,
      ).viewFor(_pages(fixtureBlocks), BrailleMode.uncontracted);

      expect(fake.batches.map((List<String> batch) => batch.length), <int>[
        2,
        2,
        1,
      ]);
    });

    test('translated lines are cached for the next view', () async {
      final _FixtureTranslator fake = _FixtureTranslator();
      final BrailleModeTranslator translator = _translator(fake);

      await translator.viewFor(_pages(fixtureBlocks), BrailleMode.uncontracted);
      await translator.viewFor(_pages(fixtureBlocks), BrailleMode.uncontracted);

      expect(fake.batches, hasLength(1));
    });

    test('the combined Braille follows the mode on screen', () async {
      final BrailleModeView view = await _translator(_FixtureTranslator())
          .viewFor(
            _pages(fixtureBlocks.take(2).toList()),
            BrailleMode.uncontracted,
          );

      expect(
        view.combinedBraille,
        '${brailleModeFixtures[0].uncontracted}\n\n'
        '${brailleModeFixtures[1].uncontracted}',
      );
    });
  });

  group('fallback to Braille 2', () {
    test('a failing translator shows Braille 2, never a blank', () async {
      final BrailleModeTranslator translator = BrailleModeTranslator(
        translateLines: (List<String> lines, BrailleMode mode) async {
          throw const OfflineBrailleException('Missing table en-ueb-g1.ctb');
        },
        isSupported: () => true,
      );
      final List<DocumentPage> pages = _pages(fixtureBlocks);

      final BrailleModeView view = await translator.viewFor(
        pages,
        BrailleMode.uncontracted,
      );

      expect(view.fellBack, isTrue);
      expect(view.mode, BrailleMode.contracted);
      expect(identical(view.pages, pages), isTrue);
      expect(view.combinedBraille, isNotEmpty);
    });

    test('one failed line falls back for the whole record', () async {
      final BrailleModeTranslator translator = BrailleModeTranslator(
        translateLines: (List<String> lines, BrailleMode mode) async {
          return <OfflineBrailleResult>[
            for (int index = 0; index < lines.length; index++)
              OfflineBrailleResult(
                success: index != 1,
                code: 'ueb',
                content: index == 1 ? '' : '⠁',
                error: index == 1 ? 'failed' : null,
              ),
          ];
        },
        isSupported: () => true,
      );

      final BrailleModeView view = await translator.viewFor(
        _pages(fixtureBlocks),
        BrailleMode.uncontracted,
      );

      expect(view.fellBack, isTrue);
      expect(view.mode, BrailleMode.contracted);
    });

    test('on other platforms Braille 1 is unavailable', () async {
      final _FixtureTranslator fake = _FixtureTranslator();
      final BrailleModeTranslator translator = _translator(
        fake,
        supported: false,
      );

      expect(
        translator.availabilityOf(_pages(fixtureBlocks)),
        BrailleModeAvailability.unsupportedPlatform,
      );

      final BrailleModeView view = await translator.viewFor(
        _pages(fixtureBlocks),
        BrailleMode.uncontracted,
      );

      expect(view.fellBack, isTrue);
      expect(fake.batches, isEmpty);
    });
  });

  group('availability', () {
    final BrailleModeTranslator translator = _translator(_FixtureTranslator());

    test('records without blocks need a newer scan', () {
      expect(
        translator.availabilityOf(const <DocumentPage>[]),
        BrailleModeAvailability.noSourceText,
      );
    });

    test('math-only records have nothing to switch', () {
      expect(
        translator.availabilityOf(_pages(<DocumentBlock>[_formula()])),
        BrailleModeAvailability.mathOnly,
      );
    });

    test('UEB text records can switch', () {
      expect(
        translator.availabilityOf(_pages(fixtureBlocks)),
        BrailleModeAvailability.available,
      );
    });
  });

  group('saving', () {
    final ScanDocumentResult result = ScanDocumentResult(
      model: 'test',
      pipelineVersion: 'test',
      device: 'test',
      pageCount: 1,
      processingTimeMs: 0,
      blocks: fixtureBlocks,
      pages: _pages(fixtureBlocks),
    );

    test(
      'History always saves Braille 2, even with Braille 1 on screen',
      () async {
        final BrailleModeView braille1 = await _translator(
          _FixtureTranslator(),
        ).viewFor(result.pages, BrailleMode.uncontracted);

        expect(braille1.mode, BrailleMode.uncontracted);

        final BrailleSavePayload payload = BrailleSavePayload.forHistory(
          result,
        );

        expect(payload.brailleContent, result.combinedBraille);
        expect(
          payload.brailleContent,
          contains(brailleModeFixtures[0].contracted),
        );
        expect(
          payload.documentBlocks.any(
            (Map<String, dynamic> block) =>
                block.containsKey('saved_braille_mode'),
          ),
          isFalse,
        );
      },
    );

    test('Materials save the combined Braille of the mode on screen', () async {
      final BrailleModeView braille1 = await _translator(
        _FixtureTranslator(),
      ).viewFor(result.pages, BrailleMode.uncontracted);

      final BrailleSavePayload payload = BrailleSavePayload.forMaterial(
        result,
        braille1,
      );

      expect(payload.brailleContent, braille1.combinedBraille);
      expect(
        payload.brailleContent,
        contains(brailleModeFixtures[0].uncontracted),
      );

      // Blocks keep their Braille 2 and record the saved mode.
      final Map<String, dynamic> firstBlock = payload.documentBlocks.first;
      expect(firstBlock['braille_content'], brailleModeFixtures[0].contracted);
      expect(firstBlock['saved_braille_mode'], 'uncontracted');

      final Map<String, dynamic> pageBlock =
          (payload.documentPages.single['blocks'] as List<Object?>).first
              as Map<String, dynamic>;
      expect(pageBlock['saved_braille_mode'], 'uncontracted');
    });

    test('Materials saved in Braille 2 keep the existing JSON shape', () {
      final BrailleSavePayload payload = BrailleSavePayload.forMaterial(
        result,
        BrailleModeView(pages: result.pages, mode: BrailleMode.contracted),
      );

      expect(payload.brailleContent, result.combinedBraille);
      expect(
        payload.documentBlocks.first.containsKey('saved_braille_mode'),
        isFalse,
      );
    });

    test('a saved mode reads back, and a missing one means Braille 2', () {
      final DocumentBlock saved = DocumentBlock.fromJson(
        fixtureBlocks.first
            .withSavedBrailleMode(BrailleMode.uncontracted)
            .toJson(),
        fallbackId: 0,
        fallbackOrder: 0,
      );
      final DocumentBlock legacy = DocumentBlock.fromJson(
        fixtureBlocks.first.toJson(),
        fallbackId: 0,
        fallbackOrder: 0,
      );

      expect(saved.savedBrailleMode, BrailleMode.uncontracted);
      expect(legacy.savedBrailleMode, BrailleMode.contracted);
      expect(
        savedBrailleModeOf(_pages(<DocumentBlock>[saved])),
        BrailleMode.uncontracted,
      );
      expect(
        savedBrailleModeOf(const <DocumentPage>[]),
        BrailleMode.contracted,
      );
    });
  });
}
