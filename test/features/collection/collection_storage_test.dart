import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_storage_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/settings/collection_storage_screen.dart';

/// Settings → Storage (Collection TODO item 15).

const _snapshot = StorageSnapshot(
  databaseBytes: 3 * 1024 * 1024 + 200 * 1024,
  tables: [
    StorageTableCount(table: 'a_tblCollectionItems', rows: 120),
    StorageTableCount(table: 'a_tblCollectionEngagement', rows: 45),
    StorageTableCount(table: 'a_tblCollectionPending', rows: 2),
  ],
  pendingUploads: 2,
);

void main() {
  tearDown(Get.reset);

  test('formatBytes reads like a phone', () {
    expect(CollectionStorageController.formatBytes(0), '0 B');
    expect(CollectionStorageController.formatBytes(900), '900 B');
    expect(CollectionStorageController.formatBytes(5 * 1024), '5.0 KB');
    expect(CollectionStorageController.formatBytes(240 * 1024), '240 KB');
    expect(CollectionStorageController.formatBytes(3 * 1024 * 1024 + 200 * 1024),
        '3.2 MB');
    expect(CollectionStorageController.formatBytes(2 * 1024 * 1024 * 1024),
        '2.00 GB');
  });

  test('a table name reads as words', () {
    expect(const StorageTableCount(table: 'a_tblCollectionItems', rows: 1).label,
        'Collection Items');
    expect(
        const StorageTableCount(table: 'a_tblCollectionAccountHistory', rows: 1)
            .label,
        'Collection Account History');
    expect(_snapshot.collectionRows, 167);
  });

  group('controller', () {
    test('loads the snapshot; an action re-reads it afterwards', () async {
      var reads = 0;
      var redownloads = 0;
      final c = CollectionStorageController(
        snapshot: () async {
          reads++;
          return _snapshot;
        },
        redownload: () async => redownloads++,
        clearImageCache: () async {},
      );
      await c.load();
      expect(c.snapshot.value, _snapshot);
      expect(reads, 1);

      final result = await c.redownloadBucket();
      expect(result.isSuccess, isTrue);
      expect(redownloads, 1);
      expect(reads, 2);
      expect(c.isWorking.value, isFalse);
    });

    test('a failing action reports the message', () async {
      final c = CollectionStorageController(
        snapshot: () async => _snapshot,
        redownload: () async {},
        clearImageCache: () async => throw Exception('cache busy'),
      );
      final result = await c.clearImageCache();
      expect(result.isFailure, isTrue);
      expect(result.error, contains('cache busy'));
    });

    test('an unreadable storage is an error, not a crash', () async {
      final c = CollectionStorageController(
        snapshot: () async => throw Exception('no database'),
        redownload: () async {},
        clearImageCache: () async {},
      );
      await c.load();
      expect(c.snapshot.value, isNull);
      expect(c.error.value, contains('no database'));
    });
  });

  group('screen', () {
    late int redownloads;
    late int clears;

    Future<void> pump(WidgetTester tester) async {
      redownloads = 0;
      clears = 0;
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      Get.put(CollectionStorageController(
        snapshot: () async => _snapshot,
        redownload: () async => redownloads++,
        clearImageCache: () async => clears++,
      ));
      await tester.pumpWidget(GetMaterialApp(
          theme: BCollectionTheme.light,
          home: const CollectionStorageScreen()));
      await tester.pumpAndSettle();
    }

    Future<void> drainSnackbar(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the size, the rows, and what waits to upload',
        (tester) async {
      await pump(tester);
      expect(find.text('3.2 MB'), findsOneWidget);
      expect(find.textContaining('167 Collection rows'), findsOneWidget);
      expect(find.textContaining('2 waiting to upload'), findsOneWidget);
      expect(find.byKey(const ValueKey('storage-table-a_tblCollectionItems')),
          findsOneWidget);
      expect(find.text('Collection Engagement'), findsOneWidget);
      expect(find.textContaining('2 un-uploaded changes · upload first'),
          findsOneWidget);
    });

    testWidgets('re-download asks first, then runs', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Re-download the bucket'));
      await tester.pumpAndSettle();
      expect(find.text('Re-download the bucket?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(redownloads, 0);

      await tester.tap(find.text('Re-download the bucket'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('storage-confirm-redownload')));
      await tester.pumpAndSettle();
      expect(redownloads, 1);
      await drainSnackbar(tester);
    });

    testWidgets('clearing pictures runs after confirmation', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Clear cached pictures'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('storage-confirm-images')));
      await tester.pumpAndSettle();
      expect(clears, 1);
      await drainSnackbar(tester);
    });
  });
}
