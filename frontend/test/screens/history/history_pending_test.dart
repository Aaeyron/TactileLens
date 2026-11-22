import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/history/history_model.dart';
import 'package:mobile/screens/history/history_screen.dart';
import 'package:mobile/screens/main/tab_data_cache.dart';
import 'package:mobile/services/history/history_outbox.dart';
import 'package:mobile/services/history/history_service.dart';
import 'package:mobile/utils/session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// History on a server in memory; [online] false = cannot be reached.
class _Server extends HistoryService {
  final List<HistoryRecord> records = <HistoryRecord>[];
  bool online = false;

  HistoryServiceException get _offline =>
      const HistoryServiceException('Unable to reach the TactileLens server.');

  @override
  Future<HistoryRecord> createHistory({
    required String title,
    required String recognizedContent,
    required String brailleContent,
    required List<Map<String, dynamic>> documentBlocks,
    List<Map<String, dynamic>> documentPages = const <Map<String, dynamic>>[],
    String? sourceImagePath,
    String? modelName,
    String? pipelineVersion,
    double? processingTimeMs,
    String? idempotencyKey,
  }) async {
    if (!online) {
      throw _offline;
    }
    final DateTime t = DateTime(2026, 11, 22, 9);
    final HistoryRecord r = HistoryRecord(
      id: records.length + 100,
      userId: 7,
      title: title,
      recognizedContent: recognizedContent,
      brailleContent: brailleContent,
      documentBlocks: documentBlocks,
      createdAt: t,
      updatedAt: t,
    );
    records.add(r);
    return r;
  }

  @override
  Future<HistoryPage> getHistory({
    int page = HistoryService.defaultPage,
    int limit = HistoryService.defaultLimit,
  }) async {
    if (!online) {
      throw _offline;
    }
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
    records.removeWhere((HistoryRecord r) => r.id == historyId);
  }

  @override
  void dispose() {}
}

void main() {
  late Directory dir;
  late _Server server;
  late HistoryOutbox outbox;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('outbox_history_test');
    server = _Server();
    outbox = HistoryOutbox(historyService: server, directory: () async => dir);
    SharedPreferences.setMockInitialValues(<String, Object>{
      SessionManager.userIdKey: 7,
    });
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  tearDown(() async {
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  Future<void> open(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryScreen(
              cache: TabDataCache(),
              onBack: () {},
              historyService: server,
              historyOutbox: outbox,
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pumpAndSettle();
  }

  Future<void> saveOffline(WidgetTester tester, String title) async {
    await tester.runAsync(() async {
      final HistorySaveOutcome outcome = await outbox.save(
        title: title,
        recognizedContent: 'x = 2',
        brailleContent: '⠭⠀⠨⠅⠀⠼⠃',
        documentBlocks: <Map<String, dynamic>>[],
      );
      expect(outcome, HistorySaveOutcome.savedOnPhone);
    });
  }

  testWidgets(
    'offline: a scan kept on the phone is listed, marked "Not synced yet"',
    (WidgetTester tester) async {
      await saveOffline(tester, 'Offline worksheet');
      await open(tester);

      expect(find.text('Offline worksheet'), findsOneWidget);
      expect(find.text('Not synced yet'), findsOneWidget);
      // The server error is a message, not the error page.
      expect(
        find.text('Unable to reach the TactileLens server.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'back online: opening History syncs it; no "Not synced yet" left',
    (WidgetTester tester) async {
      await saveOffline(tester, 'Offline worksheet');
      server.online = true;
      await open(tester);

      expect(server.records.map((HistoryRecord r) => r.title), <String>[
        'Offline worksheet',
      ]);
      expect(find.text('Offline worksheet'), findsOneWidget);
      expect(find.text('Not synced yet'), findsNothing);
      await tester.runAsync(
        () async => expect(await outbox.pending(), isEmpty),
      );
    },
  );

  testWidgets(
    'deleting a waiting scan removes it from the phone, not the server',
    (WidgetTester tester) async {
      await saveOffline(tester, 'Offline worksheet');
      await open(tester);

      await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      // Confirm (frames close the dialog), then let the file delete finish.
      await tester.tap(find.widgetWithText(FilledButton, 'Delete').last);
      await tester.pumpAndSettle();
      // Each file step needs real time, then a frame to continue.
      for (int i = 0; i < 4; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(find.text('Not synced yet'), findsNothing);
      await tester.runAsync(
        () async => expect(await outbox.pending(), isEmpty),
      );
      expect(server.records, isEmpty);
    },
  );
}
