import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/history/history_model.dart';
import '../../utils/session_manager.dart';
import 'history_service.dart';

/// A scan of a signed-in user whose History save did not reach the server
/// (no connection, server error, expired session). Kept on this phone until
/// it syncs. The scanned image is not kept: signed-in History has no image.
class PendingHistoryScan {
  const PendingHistoryScan({
    required this.id,
    required this.userId,
    required this.title,
    required this.recognizedContent,
    required this.brailleContent,
    required this.documentBlocks,
    required this.documentPages,
    required this.createdAt,
    this.modelName,
    this.pipelineVersion,
    this.processingTimeMs,
    this.attempts = 0,
    this.lastError,
  });

  /// Also the Idempotency-Key of every save attempt, so a save that reached
  /// the server but lost its answer is not stored twice.
  final String id;
  final int userId;
  final String title;
  final String recognizedContent;
  final String brailleContent;
  final List<Map<String, dynamic>> documentBlocks;
  final List<Map<String, dynamic>> documentPages;
  final DateTime createdAt;
  final String? modelName;
  final String? pipelineVersion;
  final double? processingTimeMs;
  final int attempts;
  final String? lastError;

  PendingHistoryScan copyWith({
    String? title,
    int? attempts,
    String? lastError,
  }) {
    return PendingHistoryScan(
      id: id,
      userId: userId,
      title: title ?? this.title,
      recognizedContent: recognizedContent,
      brailleContent: brailleContent,
      documentBlocks: documentBlocks,
      documentPages: documentPages,
      createdAt: createdAt,
      modelName: modelName,
      pipelineVersion: pipelineVersion,
      processingTimeMs: processingTimeMs,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'user_id': userId,
    'title': title,
    'recognized_content': recognizedContent,
    'braille_content': brailleContent,
    'document_blocks': documentBlocks,
    'document_pages': documentPages,
    'created_at': createdAt.toIso8601String(),
    'model_name': modelName,
    'pipeline_version': pipelineVersion,
    'processing_time_ms': processingTimeMs,
    'attempts': attempts,
    'last_error': lastError,
  };

  factory PendingHistoryScan.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> maps(Object? value) => value is List
        ? value
              .whereType<Map>()
              .map((Map m) => Map<String, dynamic>.from(m))
              .toList()
        : <Map<String, dynamic>>[];

    return PendingHistoryScan(
      id: json['id'] as String,
      userId: json['user_id'] as int,
      title: json['title'] as String,
      recognizedContent: json['recognized_content'] as String? ?? '',
      brailleContent: json['braille_content'] as String? ?? '',
      documentBlocks: maps(json['document_blocks']),
      documentPages: maps(json['document_pages']),
      createdAt: DateTime.parse(json['created_at'] as String),
      modelName: json['model_name'] as String?,
      pipelineVersion: json['pipeline_version'] as String?,
      processingTimeMs: (json['processing_time_ms'] as num?)?.toDouble(),
      attempts: json['attempts'] as int? ?? 0,
      lastError: json['last_error'] as String?,
    );
  }

  /// For the History list. [displayId] is negative, so it never matches a
  /// server record; History marks these cards "Not synced yet".
  HistoryRecord toRecord(int displayId) {
    return HistoryRecord(
      id: displayId,
      userId: userId,
      title: title,
      recognizedContent: recognizedContent,
      brailleContent: brailleContent,
      documentBlocks: documentBlocks,
      documentPages: documentPages,
      modelName: modelName,
      pipelineVersion: pipelineVersion,
      processingTimeMs: processingTimeMs,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }
}

/// How a History save ended.
enum HistorySaveOutcome {
  /// On the server (signed in) or in the phone's History (guest).
  saved,

  /// Kept on this phone; it syncs when the server can be reached.
  savedOnPhone,
}

/// Signed-in scans that could not be saved to the server, kept as JSON files
/// in the app's private storage until they sync. Guests never use it: their
/// History is already on the phone.
class HistoryOutbox {
  HistoryOutbox({this._historyService, Future<Directory> Function()? directory})
    : _directory = directory ?? _defaultDirectory;

  static final HistoryOutbox instance = HistoryOutbox();

  /// The message shown when a scan was kept on the phone.
  static const String savedOnPhoneMessage =
      'Saved on this phone. It will sync when you\'re online.';

  final HistoryService? _historyService;
  final Future<Directory> Function() _directory;
  Future<int>? _running;

  static Future<Directory> _defaultDirectory() async {
    final Directory base = await getApplicationSupportDirectory();
    return Directory('${base.path}${Platform.pathSeparator}history_outbox');
  }

  HistoryService get _service => _historyService ?? HistoryService();

  static String newKey() {
    final Random random = Random.secure();
    return List<String>.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  /// Whether a failed save is worth keeping for later: the server was not
  /// reached, failed, or the session expired. A refusal of the content
  /// (400, 413, 422) would fail again, so it is not queued.
  static bool shouldKeep(HistoryServiceException error) {
    if (error is HistoryAuthenticationException) {
      return true;
    }
    final int? status = error.statusCode;
    return status == null ||
        status == 401 ||
        status == 408 ||
        status == 429 ||
        status >= 500;
  }

  /// Saves a scan to History. For a signed-in user whose save does not reach
  /// the server, keeps it on this phone instead ([HistorySaveOutcome.savedOnPhone]).
  /// Other errors are passed on, as before.
  Future<HistorySaveOutcome> save({
    required String title,
    required String recognizedContent,
    required String brailleContent,
    required List<Map<String, dynamic>> documentBlocks,
    List<Map<String, dynamic>> documentPages = const <Map<String, dynamic>>[],
    String? sourceImagePath,
    String? modelName,
    String? pipelineVersion,
    double? processingTimeMs,
  }) async {
    final String key = newKey();
    try {
      await _service.createHistory(
        title: title,
        recognizedContent: recognizedContent,
        brailleContent: brailleContent,
        documentBlocks: documentBlocks,
        documentPages: documentPages,
        sourceImagePath: sourceImagePath,
        modelName: modelName,
        pipelineVersion: pipelineVersion,
        processingTimeMs: processingTimeMs,
        idempotencyKey: key,
      );
      return HistorySaveOutcome.saved;
    } on HistoryServiceException catch (error) {
      final int? userId = await SessionManager.getUserId();
      if (await SessionManager.isGuest() ||
          userId == null ||
          !shouldKeep(error)) {
        rethrow;
      }
      await _write(
        PendingHistoryScan(
          id: key,
          userId: userId,
          title: title.trim(),
          recognizedContent: recognizedContent.trim(),
          brailleContent: brailleContent.trim(),
          documentBlocks: documentBlocks,
          documentPages: documentPages,
          createdAt: DateTime.now(),
          modelName: modelName,
          pipelineVersion: pipelineVersion,
          processingTimeMs: processingTimeMs,
          attempts: 1,
          lastError: error.message,
        ),
      );
      return HistorySaveOutcome.savedOnPhone;
    }
  }

  /// The signed-in user's scans waiting to sync, oldest first. Empty for guests.
  Future<List<PendingHistoryScan>> pending() async {
    final int? userId = await SessionManager.getUserId();
    if (await SessionManager.isGuest() || userId == null) {
      return <PendingHistoryScan>[];
    }
    final Directory dir = await _directory();
    if (!await dir.exists()) {
      return <PendingHistoryScan>[];
    }
    final List<PendingHistoryScan> items = <PendingHistoryScan>[];
    await for (final FileSystemEntity f in dir.list()) {
      if (f is! File || !f.path.endsWith('.json')) {
        continue;
      }
      try {
        final PendingHistoryScan item = PendingHistoryScan.fromJson(
          jsonDecode(await f.readAsString()) as Map<String, dynamic>,
        );
        if (item.userId == userId) {
          items.add(item);
        }
      } catch (error) {
        // A damaged file is left alone (not deleted) and skipped.
        debugPrint('Skipping an unreadable pending scan: $error');
      }
    }
    items.sort(
      (PendingHistoryScan a, PendingHistoryScan b) =>
          a.createdAt.compareTo(b.createdAt),
    );
    return items;
  }

  Future<void> remove(String id) async {
    final File f = await _file(id);
    if (await f.exists()) {
      await f.delete();
    }
  }

  Future<void> rename(String id, String title) async {
    final File f = await _file(id);
    if (!await f.exists()) {
      return;
    }
    final PendingHistoryScan item = PendingHistoryScan.fromJson(
      jsonDecode(await f.readAsString()) as Map<String, dynamic>,
    );
    await _write(item.copyWith(title: title.trim()));
  }

  /// Sends the user's pending scans to the server, oldest first, each with
  /// its own key (a repeat is not stored twice). Stops at the first failure
  /// and tries again next time. Only one sync runs at a time. Returns how many
  /// synced.
  Future<int> sync() {
    return _running ??= _sync().whenComplete(() => _running = null);
  }

  Future<int> _sync() async {
    int synced = 0;
    for (final PendingHistoryScan item in await pending()) {
      try {
        await _service.createHistory(
          title: item.title,
          recognizedContent: item.recognizedContent,
          brailleContent: item.brailleContent,
          documentBlocks: item.documentBlocks,
          documentPages: item.documentPages,
          modelName: item.modelName,
          pipelineVersion: item.pipelineVersion,
          processingTimeMs: item.processingTimeMs,
          idempotencyKey: item.id,
        );
        await remove(item.id);
        synced++;
      } on HistoryServiceException catch (error) {
        await _write(
          item.copyWith(attempts: item.attempts + 1, lastError: error.message),
        );
        break;
      }
    }
    return synced;
  }

  Future<File> _file(String id) async {
    final Directory dir = await _directory();
    return File('${dir.path}${Platform.pathSeparator}$id.json');
  }

  Future<void> _write(PendingHistoryScan item) async {
    final Directory dir = await _directory();
    await dir.create(recursive: true);
    final File target = await _file(item.id);
    // Write a temporary file first, so a crash never leaves half a scan.
    final File temp = File('${target.path}.tmp');
    await temp.writeAsString(jsonEncode(item.toJson()), flush: true);
    await temp.rename(target.path);
  }
}
