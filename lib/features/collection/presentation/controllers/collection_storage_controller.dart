import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/sync_manager.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// One local table and how many rows it holds.
class StorageTableCount {
  const StorageTableCount({required this.table, required this.rows});

  final String table;
  final int rows;

  /// `a_tblCollectionItems` → "Collection Items".
  String get label {
    var name = table;
    for (final prefix in const ['a_tbl', 'tbl']) {
      if (name.startsWith(prefix)) name = name.substring(prefix.length);
    }
    return name
        .replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (_) => ' ')
        .trim();
  }
}

/// What the Storage screen reads in one go.
class StorageSnapshot {
  const StorageSnapshot({
    required this.databaseBytes,
    required this.tables,
    required this.pendingUploads,
  });

  /// `app.db` plus its `-wal` / `-journal` files.
  final int databaseBytes;

  /// The Collection tables, largest first.
  final List<StorageTableCount> tables;

  final int pendingUploads;

  int get collectionRows => tables.fold(0, (sum, t) => sum + t.rows);
}

typedef SnapshotLoader = Future<StorageSnapshot> Function();
typedef StorageAction = Future<void> Function();

/// Settings → Storage (Collection TODO item 15): how much the app keeps on
/// this phone, and the two things a collector can do about it — re-download
/// the bucket (through the same path as the home button, so un-uploaded work
/// is still checked first) and clear the cached pictures.
class CollectionStorageController extends GetxController {
  CollectionStorageController({
    SnapshotLoader? snapshot,
    StorageAction? redownload,
    StorageAction? clearImageCache,
  })  : _snapshot = snapshot ?? _readSnapshot,
        _redownload = redownload ?? _redownloadBucket,
        _clearImageCache = clearImageCache ?? _emptyImageCache;

  static CollectionStorageController get instance => Get.find();

  final SnapshotLoader _snapshot;
  final StorageAction _redownload;
  final StorageAction _clearImageCache;

  final snapshot = Rxn<StorageSnapshot>();
  final isLoading = false.obs;
  final isWorking = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      snapshot.value = await _snapshot();
    } catch (e) {
      logDebug('CollectionStorageController.load error: $e');
      error.value = 'Could not read the local storage: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Re-download the bucket. Null on success, else a message.
  Future<Result<void>> redownloadBucket() => _run(_redownload);

  /// Clear cached pictures (profile photos and other network images).
  Future<Result<void>> clearImageCache() => _run(_clearImageCache);

  Future<Result<void>> _run(StorageAction action) async {
    if (isWorking.value) return Result.failure('Still working on the last one.');
    isWorking.value = true;
    try {
      await action();
      await load();
      return Result.success(null);
    } catch (e) {
      logDebug('CollectionStorageController action error: $e');
      return Result.failure(e.toString());
    } finally {
      isWorking.value = false;
    }
  }

  /// "0 B", "12.4 KB", "3.2 MB".
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    return '${(mb / 1024).toStringAsFixed(2)} GB';
  }

  // --- defaults: the real app wiring ---

  static Future<StorageSnapshot> _readSnapshot() async {
    final dbPath = p.join(await getDatabasesPath(), 'app.db');
    var bytes = 0;
    for (final suffix in const ['', '-wal', '-journal', '-shm']) {
      final f = File('$dbPath$suffix');
      if (await f.exists()) bytes += await f.length();
    }

    final db = await DatabaseHelper.instance.database;
    final names = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'a_tblCollection%' ORDER BY name");
    final tables = <StorageTableCount>[];
    for (final row in names) {
      final table = row['name'] as String;
      final count = await db.rawQuery('SELECT COUNT(*) AS c FROM $table');
      tables.add(StorageTableCount(
          table: table, rows: (count.first['c'] as int?) ?? 0));
    }
    tables.sort((a, b) => b.rows.compareTo(a.rows));

    var pending = 0;
    if (Get.isRegistered<SyncManager>()) {
      pending = await Get.find<SyncManager>().getPendingChangeCount();
    }
    return StorageSnapshot(
        databaseBytes: bytes, tables: tables, pendingUploads: pending);
  }

  static Future<void> _redownloadBucket() =>
      Get.find<CollectionActivityController>().downloadBucket();

  static Future<void> _emptyImageCache() => DefaultCacheManager().emptyCache();
}
