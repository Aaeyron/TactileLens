import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/history/history_model.dart';
import 'package:mobile/screens/history/history_screen.dart';
import 'package:mobile/screens/main/tab_data_cache.dart';
import 'package:mobile/services/history/history_service.dart';
import 'package:mobile/styles/screens/history/history_screen_styles.dart';
import 'package:mobile/utils/session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps records in memory and counts deletions; no database or network.
class _FakeHistoryService extends HistoryService {
  _FakeHistoryService(this.records);

  List<HistoryRecord> records;
  final List<int> deletedIds = <int>[];

  @override
  Future<HistoryPage> getHistory({
    int page = HistoryService.defaultPage,
    int limit = HistoryService.defaultLimit,
  }) async {
    return HistoryPage(
      records: List<HistoryRecord>.from(records),
      pagination: HistoryPagination(
        page: 1,
        limit: limit,
        total: records.length,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<void> deleteHistory(int historyId) async {
    deletedIds.add(historyId);
    records = records.where((HistoryRecord r) => r.id != historyId).toList();
  }

  @override
  void dispose() {}
}

HistoryRecord _record(int id, bool math) {
  final DateTime t = DateTime(2026, 11, 22, 9, id);
  return HistoryRecord(
    id: id,
    userId: 1,
    title: 'Scan $id',
    recognizedContent: math ? r'x^{2}=4' : 'Some text',
    brailleContent: '⠎⠉⠁⠝',
    documentBlocks: <Map<String, dynamic>>[
      <String, dynamic>{
        'block_label': math ? 'display_formula' : 'text',
        'block_content': math ? r'x^{2}=4' : 'Some text',
      },
    ],
    createdAt: t,
    updatedAt: t,
  );
}

const String _trashTooltip = 'Clear all history';

Finder get _trash => find.byTooltip(_trashTooltip);

Future<List<String>> _pump(
  WidgetTester tester,
  _FakeHistoryService service, {
  Size size = const Size(393, 852),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final List<String> overflows = <String>[];
  final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exceptionAsString().contains('overflowed')) {
      overflows.add(details.exceptionAsString());
    }
  };
  addTearDown(() => FlutterError.onError = previous);

  await tester.pumpWidget(
    MaterialApp(
      builder: (BuildContext context, Widget? app) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: app!,
      ),
      home: Scaffold(
        body: HistoryScreen(
          cache: TabDataCache()..history = service.records,
          onBack: () {},
          historyService: service,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  FlutterError.onError = previous;
  return overflows;
}

Rect _rectOf(WidgetTester tester, String label) {
  return tester.getRect(
    find.ancestor(of: find.text(label), matching: find.byType(InkWell)).first,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SessionManager.guestModeKey: true,
    });
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  group('layout', () {
    testWidgets('filters are evenly spaced, the same height, and the trash '
        'button sits at the end of the row', (WidgetTester tester) async {
      await _pump(
        tester,
        _FakeHistoryService(<HistoryRecord>[_record(1, true)]),
      );

      final Rect all = _rectOf(tester, 'All');
      final Rect text = _rectOf(tester, 'Text');
      final Rect math = _rectOf(tester, 'Math');
      const double gap = HistoryScreenStyles.filterSpacing;

      expect(text.left - all.right, closeTo(gap, 0.01));
      expect(math.left - text.right, closeTo(gap, 0.01));
      expect(all.height, text.height);
      expect(text.height, math.height);
      expect(all.height, HistoryScreenStyles.filterHeight);

      final Rect trash = tester.getRect(_trash);
      expect(trash.left, greaterThan(math.right + gap));
      // Right edge of the content area (14 px page padding).
      expect(trash.right, closeTo(393 - 14, 0.01));
      expect(trash.center.dy, closeTo(math.center.dy, 0.01));
    });

    for (final (Size size, double scale) in <(Size, double)>[
      (const Size(393, 852), 1),
      (const Size(320, 568), 1),
      (const Size(320, 568), 2),
    ]) {
      testWidgets('no overflow at ${size.width.toInt()} px, ${scale}x text, '
          'and every label stays whole', (WidgetTester tester) async {
        final List<String> overflows = await _pump(
          tester,
          _FakeHistoryService(<HistoryRecord>[_record(1, true)]),
          size: size,
          textScale: scale,
        );

        expect(overflows, isEmpty);
        for (final String label in <String>['All', 'Text', 'Math']) {
          final Rect chip = _rectOf(tester, label);
          final Rect text = tester.getRect(find.text(label));
          expect(chip.contains(text.topLeft), isTrue, reason: label);
          expect(chip.contains(text.bottomRight), isTrue, reason: label);
          expect(chip.right, lessThanOrEqualTo(size.width), reason: label);
        }
        expect(tester.getRect(_trash).right, lessThanOrEqualTo(size.width));
      });
    }
  });

  testWidgets('filter chips take taps over 48 dp and TalkBack hears which '
      'one is selected', (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await _pump(
      tester,
      _FakeHistoryService(<HistoryRecord>[_record(1, true), _record(2, false)]),
    );

    for (final String label in <String>['All', 'Text', 'Math']) {
      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel(label).first,
      );
      expect(node.rect.height, greaterThanOrEqualTo(48), reason: label);
      final SemanticsData data = node.getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue, reason: label);
      expect(
        data.flagsCollection.isSelected,
        label == 'All' ? Tristate.isTrue : Tristate.isFalse,
        reason: label,
      );
    }

    // A tap just above the visible chip (inside its 48 dp area) selects it.
    final Rect math = _rectOf(tester, 'Math');
    await tester.tapAt(Offset(math.center.dx, math.top - 3));
    await tester.pumpAndSettle();
    expect(find.text('Scan 1'), findsOneWidget);
    expect(find.text('Scan 2'), findsNothing);
    semantics.dispose();
  });

  group('trash button', () {
    testWidgets('is a 48 dp trash icon with the TalkBack label', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await _pump(
        tester,
        _FakeHistoryService(<HistoryRecord>[_record(1, true)]),
      );

      expect(
        find.descendant(
          of: _trash,
          matching: find.byIcon(HistoryScreenStyles.clearAllIcon),
        ),
        findsOneWidget,
      );
      expect(find.text('Clear All'), findsNothing);
      final Size size = tester.getSize(_trash);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel(_trashTooltip),
      );
      final SemanticsData data = node.getSemanticsData();
      expect(data.label, _trashTooltip);
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isEnabled, Tristate.isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      semantics.dispose();
    });

    testWidgets('is disabled when history is empty', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await _pump(tester, _FakeHistoryService(<HistoryRecord>[]));

      final IconButton button = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(HistoryScreenStyles.clearAllIcon),
          matching: find.byType(IconButton),
        ),
      );
      expect(button.onPressed, isNull);
      final SemanticsData data = tester
          .getSemantics(find.bySemanticsLabel(_trashTooltip))
          .getSemanticsData();
      expect(data.label, _trashTooltip);
      expect(data.flagsCollection.isEnabled, Tristate.isFalse);
      expect(data.hasAction(SemanticsAction.tap), isFalse);

      await tester.tap(_trash, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      semantics.dispose();
    });
  });

  group('confirmation', () {
    testWidgets('tapping trash asks first; Cancel deletes nothing', (
      WidgetTester tester,
    ) async {
      final _FakeHistoryService service = _FakeHistoryService(<HistoryRecord>[
        _record(1, true),
        _record(2, false),
      ]);
      await _pump(tester, service);

      await tester.tap(_trash);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Clear all history?'), findsOneWidget);
      // Guest: history lives only on this phone.
      expect(
        find.text(
          "Every scan listed here will be deleted from this phone. "
          "This can't be undone.",
        ),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(service.deletedIds, isEmpty);
      expect(find.text('Scan 1'), findsOneWidget);
      expect(find.text('Scan 2'), findsOneWidget);
    });

    testWidgets('signed-in users are told it deletes from the server', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await _pump(
        tester,
        _FakeHistoryService(<HistoryRecord>[_record(1, true)]),
      );

      await tester.tap(_trash);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Every scan listed here will be deleted from your account on the '
          "server, so it is gone on all your devices. This can't be undone.",
        ),
        findsOneWidget,
      );
    });

    testWidgets('Clear runs the existing clear flow once: every listed scan '
        'is deleted exactly once', (WidgetTester tester) async {
      final _FakeHistoryService service = _FakeHistoryService(<HistoryRecord>[
        _record(1, true),
        _record(2, false),
        _record(3, true),
      ]);
      await _pump(tester, service);

      await tester.tap(_trash);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Clear'));
      await tester.pumpAndSettle();

      expect(service.deletedIds..sort(), <int>[1, 2, 3]);
      expect(find.text('All scan history was removed.'), findsOneWidget);
      expect(find.text('Scan 1'), findsNothing);
      // Now empty, so the trash button is disabled.
      final IconButton button = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(HistoryScreenStyles.clearAllIcon),
          matching: find.byType(IconButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('Cancel has focus first (the safe default)', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _FakeHistoryService(<HistoryRecord>[_record(1, true)]),
      );
      await tester.tap(_trash);
      await tester.pumpAndSettle();

      final TextButton cancel = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Cancel'),
      );
      expect(cancel.autofocus, isTrue);
    });
  });
}
