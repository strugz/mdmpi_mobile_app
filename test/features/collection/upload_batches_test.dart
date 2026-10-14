import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_pending_dao.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/upload_batches.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_upload_controller.dart';

/// Upload All a batch at a time: real progress ("12 of 30"), batches that
/// never split one save, and a lost connection that keeps what was sent.

var _id = 0;
PendingChange _c(String op, String item, {String? stamp}) => PendingChange(
      id: ++_id,
      operation: op,
      itemId: item,
      payload: jsonEncode({
        'Operation': op,
        'ItemId': item,
        if (stamp != null) 'EngagementDate': stamp,
      }),
      createdAt: '2026-10-14T08:00:${(_id % 60).toString().padLeft(2, '0')}',
    );

List<PendingChange> _singles(int n) => [
      for (var i = 0; i < n; i++)
        _c('CLAIM', 'INV-$i',
            stamp: '2026-10-14T08:${i.toString().padLeft(2, '0')}:00')
    ];

void main() {
  group('batches', () {
    test('30 changes go as six batches of five, in queue order', () {
      final pending = _singles(30);
      final batches = planUploadBatches(pending);
      expect(batches.map((b) => b.length), [5, 5, 5, 5, 5, 5]);
      expect(batches.expand((b) => b).toList(), pending);
    });

    test('one save (same EngagementDate) is never split across batches', () {
      final before = _singles(4);
      final batchSave = [
        for (var i = 0; i < 3; i++)
          _c('BATCH_ACTIVITY', 'B-$i', stamp: '2026-10-14T09:00:00.000')
      ];
      final after = _singles(2);
      final batches = planUploadBatches([...before, ...batchSave, ...after]);
      final holding = batches
          .where((b) => b.any((c) => c.operation == 'BATCH_ACTIVITY'))
          .toList();
      expect(holding, hasLength(1),
          reason: 'the server merges a batch save into one payment only '
              'within one upload');
      expect(holding.single.where((c) => c.operation == 'BATCH_ACTIVITY'),
          hasLength(3));
    });

    test('a save bigger than a batch travels whole', () {
      final big = [
        for (var i = 0; i < 12; i++)
          _c('BATCH_ACTIVITY', 'B-$i', stamp: '2026-10-14T09:00:00')
      ];
      expect(planUploadBatches(big).map((b) => b.length), [12]);
    });

    test('each change carries a stable id for the server', () {
      final c = _c('CLAIM', 'INV-1');
      expect(clientChangeId(' jca ', c), clientChangeId('JCA', c));
      expect(clientChangeId('JCA', c), startsWith('JCA:${c.id}:'));
    });
  });

  group('run', () {
    test('progress counts up batch by batch to the total', () async {
      final seen = <String>[];
      final r = await runBatchedUpload(
        pending: _singles(12),
        send: (_) async => const {},
        apply: (batch, _) async => batch.length,
        onProgress: (done, total) => seen.add('$done/$total'),
      );
      expect(seen, ['0/12', '5/12', '10/12', '12/12']);
      expect(r.accepted, 12);
      expect(r.interrupted, isFalse);
    });

    test('a lost connection stops the run; what was sent stays sent', () async {
      var sent = 0;
      final applied = <int>[];
      final r = await runBatchedUpload(
        pending: _singles(30),
        send: (batch) async {
          if (++sent == 3)
            throw const SocketException('Network is unreachable');
          return const {};
        },
        apply: (batch, _) async {
          applied.add(batch.length);
          return batch.length;
        },
      );
      expect(r.interrupted, isTrue);
      expect(r.done, 10, reason: 'two batches answered before the cut');
      expect(r.total, 30);
      expect(applied, [5, 5], reason: 'the unanswered batch stays queued');
      expect(r.error, 'The connection was lost.');
    });

    test('refusals are kept with their reason and counted as done', () async {
      final pending = _singles(5);
      final r = await runBatchedUpload(
        pending: pending,
        send: (_) async => {'CLAIM|INV-2': 'Already claimed by MAR'},
        apply: (batch, refused) async => batch.length - refused.length,
      );
      expect(r.accepted, 4);
      expect(r.rejected, ['INV-2: Already claimed by MAR']);
      expect(r.done, 5);
    });

    test('the reasons a collector reads', () {
      expect(describeUploadError(TimeoutException('x')),
          'The server took too long to answer.');
      expect(describeUploadError(Exception('Upload failed (502)')),
          'The server could not take the upload (502).');
      expect(describeUploadError(StateError('?')), 'The upload stopped.');
    });
  });

  group('banner', () {
    test('all sent: a done banner that leaves by itself', () {
      final b = UploadBanner.from(
          const CollectionUploadResult(accepted: 30, total: 30));
      expect(b.kind, UploadBannerKind.done);
      expect(b.title, 'All 30 uploaded');
      expect(b.autoDismiss, isTrue);
      expect(b.canRetry, isFalse);
    });

    test('refusals: it stays, and says how many need attention', () {
      final b = UploadBanner.from(const CollectionUploadResult(
          accepted: 28, rejected: ['a', 'b'], total: 30));
      expect(b.kind, UploadBannerKind.issues);
      expect(b.title, '28 uploaded · 2 need attention');
      expect(b.autoDismiss, isFalse);
    });

    test('cut off: it stays, counts what went, and offers Retry', () {
      final b = UploadBanner.from(const CollectionUploadResult(
          accepted: 12, total: 30, error: 'The connection was lost.'));
      expect(b.kind, UploadBannerKind.stopped);
      expect(b.title, 'Upload stopped · 12 of 30 sent');
      expect(b.message, startsWith('The connection was lost.'));
      expect(b.canRetry, isTrue);
      expect(b.autoDismiss, isFalse);
    });
  });
}
