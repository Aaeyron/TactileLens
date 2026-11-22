import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/history/history_model.dart';
import 'package:mobile/services/history/history_outbox.dart';
import 'package:mobile/services/history/history_service.dart';
import 'package:mobile/utils/session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A server in memory: stores each Idempotency-Key once, like the backend.
/// [failures] makes the next calls fail without reaching it; [loseAnswer]
/// stores the next save but fails the answer (the save that "got lost").
class FakeServer extends HistoryService {
  final Map<String, HistoryRecord> stored = <String, HistoryRecord>{};
  final List<String?> calls = <String?>[];
  int failures = 0;
  int failStatus = 0;
  bool loseAnswer = false;

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
    calls.add(idempotencyKey);
    await Future<void>.delayed(Duration.zero);
    if (failures > 0) {
      failures--;
      throw HistoryServiceException(
        failStatus == 0
            ? 'Unable to reach the TactileLens server.'
            : 'Refused.',
        statusCode: failStatus == 0 ? null : failStatus,
      );
    }
    final String key = idempotencyKey ?? 'no-key-${calls.length}';
    final HistoryRecord record = stored.putIfAbsent(
      key,
      () => HistoryRecord(
        id: stored.length + 1,
        userId: 7,
        title: title,
        recognizedContent: recognizedContent,
        brailleContent: brailleContent,
        documentBlocks: documentBlocks,
        createdAt: DateTime(2026, 11, 22),
        updatedAt: DateTime(2026, 11, 22),
      ),
    );
    if (loseAnswer) {
      loseAnswer = false;
      throw const HistoryServiceException('The history request took too long.');
    }
    return record;
  }

  @override
  void dispose() {}
}

Future<HistorySaveOutcome> _save(
  HistoryOutbox outbox, [
  String title = 'Fractions quiz',
]) {
  return outbox.save(
    title: title,
    recognizedContent: r'\frac{3}{4}',
    brailleContent: '⠹⠒⠌⠲⠼',
    documentBlocks: <Map<String, dynamic>>[
      <String, dynamic>{
        'block_label': 'display_formula',
        'block_content': r'\frac{3}{4}',
      },
    ],
    pipelineVersion: 'offline-onnx-v1',
  );
}

void main() {
  late Directory dir;
  late FakeServer server;
  late HistoryOutbox outbox;

  void signIn(int userId) {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SessionManager.userIdKey: userId,
    });
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('outbox_test');
    server = FakeServer();
    outbox = HistoryOutbox(historyService: server, directory: () async => dir);
    signIn(7);
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  tearDown(() async {
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  test('saved on the server when it answers', () async {
    expect(await _save(outbox), HistorySaveOutcome.saved);
    expect(server.stored, hasLength(1));
    expect(await outbox.pending(), isEmpty);
  });

  test(
    'no connection: kept on this phone, with the key the save used',
    () async {
      server.failures = 1;

      expect(await _save(outbox), HistorySaveOutcome.savedOnPhone);

      final List<PendingHistoryScan> pending = await outbox.pending();
      expect(pending, hasLength(1));
      expect(pending.single.title, 'Fractions quiz');
      expect(pending.single.id, server.calls.single);
      expect(server.stored, isEmpty);
      expect(
        HistoryOutbox.savedOnPhoneMessage,
        "Saved on this phone. It will sync when you're online.",
      );
    },
  );

  test('server errors and an expired session are kept too', () async {
    server
      ..failures = 2
      ..failStatus = 503;
    expect(await _save(outbox, 'A'), HistorySaveOutcome.savedOnPhone);
    server.failStatus = 401;
    expect(await _save(outbox, 'B'), HistorySaveOutcome.savedOnPhone);
    expect(await outbox.pending(), hasLength(2));
  });

  test(
    'a refusal of the content (400) is not kept: it would fail again',
    () async {
      server
        ..failures = 1
        ..failStatus = 400;
      await expectLater(_save(outbox), throwsA(isA<HistoryServiceException>()));
      expect(await outbox.pending(), isEmpty);
    },
  );

  test('later sync sends it and removes it from the phone', () async {
    server.failures = 1;
    await _save(outbox);

    expect(await outbox.sync(), 1);
    expect(server.stored, hasLength(1));
    expect(await outbox.pending(), isEmpty);
  });

  test(
    'no duplicate when a save reached the server but its answer was lost',
    () async {
      server.loseAnswer = true;
      expect(await _save(outbox), HistorySaveOutcome.savedOnPhone);
      expect(server.stored, hasLength(1), reason: 'the server did store it');

      expect(await outbox.sync(), 1);
      expect(server.stored, hasLength(1), reason: 'same key: not stored again');
      expect(
        server.calls.toSet(),
        hasLength(1),
        reason: 'every attempt used one key',
      );
      expect(await outbox.pending(), isEmpty);
    },
  );

  test(
    'a failed sync keeps the scan, counts the attempt, and the next one works',
    () async {
      server.failures = 2;
      await _save(outbox);

      expect(await outbox.sync(), 0);
      final PendingHistoryScan after = (await outbox.pending()).single;
      expect(after.attempts, 2);
      expect(after.lastError, contains('Unable to reach'));

      expect(await outbox.sync(), 1);
      expect(server.stored, hasLength(1));
      expect(await outbox.pending(), isEmpty);
    },
  );

  test('several scans sync oldest first; a failure stops the round', () async {
    server.failures = 3;
    await _save(outbox, 'First');
    await _save(outbox, 'Second');
    await _save(outbox, 'Third');

    expect(await outbox.sync(), 3);
    expect(server.stored.values.map((HistoryRecord r) => r.title), <String>[
      'First',
      'Second',
      'Third',
    ]);
  });

  test('two syncs at once send each scan once', () async {
    server.failures = 1;
    await _save(outbox);
    final int callsBefore = server.calls.length;

    final List<int> results = await Future.wait(<Future<int>>[
      outbox.sync(),
      outbox.sync(),
    ]);

    expect(results, <int>[1, 1], reason: 'the second call joined the first');
    expect(server.calls.length - callsBefore, 1);
    expect(server.stored, hasLength(1));
  });

  test("another account's waiting scans are neither shown nor sent", () async {
    server.failures = 1;
    await _save(outbox);

    signIn(8);
    expect(await outbox.pending(), isEmpty);
    expect(await outbox.sync(), 0);
    expect(server.stored, isEmpty);

    signIn(7);
    expect(await outbox.sync(), 1);
  });

  test('guests are unchanged: errors are passed on, nothing is kept', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SessionManager.guestModeKey: true,
    });
    server.failures = 1;

    await expectLater(_save(outbox), throwsA(isA<HistoryServiceException>()));
    expect(await outbox.pending(), isEmpty);
    expect(await dir.list().toList(), isEmpty);
  });

  test('rename and remove work on the waiting scan', () async {
    server.failures = 1;
    await _save(outbox);
    final String id = (await outbox.pending()).single.id;

    await outbox.rename(id, '  Renamed  ');
    expect((await outbox.pending()).single.title, 'Renamed');

    await outbox.remove(id);
    expect(await outbox.pending(), isEmpty);
  });
}
