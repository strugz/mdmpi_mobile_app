import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_pending_dao.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/sync_manager.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/upload_batches.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_upload_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/upload/collection_upload_outbox_screen.dart';

/// The Upload screen: what is waiting, "12 of 30" while it goes, and the
/// banner after: done, refused, or cut off with Retry.

class _Sync extends SyncManager {
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _Upload extends CollectionUploadController {
  @override
  Future<void> load() async {}
}

PendingChange _row(int id, String op, String item, {int retries = 0}) =>
    PendingChange(
      id: id,
      operation: op,
      itemId: item,
      payload: jsonEncode({'Operation': op, 'ItemId': item}),
      createdAt: '2026-10-14T08:00:00',
      retryCount: retries,
      lastError: retries > 0 ? 'Already claimed by MAR' : null,
    );

Future<(_Sync, _Upload)> _pump(WidgetTester tester) async {
  final sync = _Sync();
  Get.put<SyncManager>(sync);
  final upload = _Upload();
  Get.put<CollectionUploadController>(upload);
  upload.pending.assignAll([
    for (var i = 0; i < 7; i++) _row(i + 1, 'CLAIM', '70001134$i'),
    _row(8, 'SAVE_ACTIVITY', '240002769', retries: 2),
  ]);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(360, 780);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(GetMaterialApp(
      theme: BCollectionTheme.light,
      home: const CollectionUploadOutboxScreen()));
  await tester.pumpAndSettle();
  return (sync, upload);
}

void main() {
  tearDown(Get.reset);

  testWidgets('what is waiting, by kind, with the refused one marked',
      (tester) async {
    await _pump(tester);
    expect(find.text('8 items waiting'), findsOneWidget);
    expect(find.text('7 Acquire account'), findsOneWidget);
    expect(find.text('1 need attention'), findsOneWidget);
    expect(find.text('Upload All (8)'), findsOneWidget);
  });

  testWidgets('while uploading: 12 of 30, on the panel and the button',
      (tester) async {
    final (sync, _) = await _pump(tester);
    sync.isSyncing.value = true;
    sync.uploadTotal.value = 30;
    sync.uploadDone.value = 12;
    // The spinners turn while it uploads, so step the clock, not settle.
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Uploading  12 of 30'), findsOneWidget);
    expect(find.text('Uploading 12/30'), findsOneWidget);
    sync.isSyncing.value = false;
    await tester.pumpAndSettle();
  });

  testWidgets('cut off: the banner stays and offers Retry', (tester) async {
    final (_, upload) = await _pump(tester);
    upload.banner.value = UploadBanner.from(const CollectionUploadResult(
        accepted: 12, total: 30, error: 'The connection was lost.'));
    await tester.pumpAndSettle();
    expect(find.text('Upload stopped · 12 of 30 sent'), findsOneWidget);
    expect(find.byKey(const ValueKey('upload-retry')), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('Upload stopped · 12 of 30 sent'), findsOneWidget,
        reason: 'it waits to be read');
  });

  testWidgets('done: the banner shows, then leaves by itself', (tester) async {
    final (_, upload) = await _pump(tester);
    upload.banner.value = UploadBanner.from(
        const CollectionUploadResult(accepted: 30, total: 30));
    await tester.pumpAndSettle();
    expect(find.text('All 30 uploaded'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('All 30 uploaded'), findsNothing);
  });
}
