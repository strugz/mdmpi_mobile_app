import 'dart:convert';

import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_pending_dao.dart';

/// How an Upload All run ended.
class CollectionUploadResult {
  const CollectionUploadResult({
    this.accepted = 0,
    this.rejected = const [],
    this.total = 0,
    this.error,
  });

  /// Changes the server took (now off the queue).
  final int accepted;

  /// "reason" strings for the changes it refused (kept on the queue).
  final List<String> rejected;

  /// Changes the run set out to send.
  final int total;

  /// Why the run stopped before the end (no connection, a server error);
  /// null when every batch got an answer.
  final String? error;

  int get rejectedCount => rejected.length;
  bool get hasRejections => rejected.isNotEmpty;

  /// Stopped part-way; what was sent before stays sent.
  bool get interrupted => error != null;

  /// Changes that got an answer, either way.
  int get done => accepted + rejectedCount;
}

/// Sends one batch; returns the server's refusals as `operation|itemId` →
/// reason. Throws when the batch got no answer (no connection, a timeout, a
/// server error), so the run stops there.
typedef UploadBatchSender = Future<Map<String, String>> Function(
    List<PendingChange> batch);

/// Records one answered batch on the phone: accepted rows leave the queue,
/// refused ones keep their reason. Returns how many were accepted.
typedef UploadBatchApplier = Future<int> Function(
    List<PendingChange> batch, Map<String, String> rejected);

/// Splits the queue into small batches for Upload All, in queue order.
///
/// Small, so the collector sees progress ("12 of 30") and a lost connection
/// costs one batch, not the day. Changes with the same `EngagementDate` were
/// saved together (one batch collection over several invoices) and stay in
/// one batch: the server merges such a batch into one payment only within a
/// single upload. A group larger than [size] travels whole.
List<List<PendingChange>> planUploadBatches(List<PendingChange> pending,
    {int size = 5}) {
  final batches = <List<PendingChange>>[];
  var current = <PendingChange>[];
  String? currentStamp;
  for (final change in pending) {
    final stamp = _engagementDate(change);
    final sameSave = stamp != null && stamp == currentStamp;
    if (current.isNotEmpty && current.length >= size && !sameSave) {
      batches.add(current);
      current = <PendingChange>[];
    }
    current.add(change);
    currentStamp = stamp;
  }
  if (current.isNotEmpty) batches.add(current);
  return batches;
}

/// A stable id per queued change (`ClientChangeId`), so a server can tell a
/// batch sent again after a lost answer from new work.
String clientChangeId(String collectorCode, PendingChange change) =>
    '${collectorCode.trim().toUpperCase()}:${change.id}:${change.createdAt}';

/// Runs Upload All batch by batch: each answered batch is applied before the
/// next is sent, [onProgress] reports changes answered so far, and the first
/// batch with no answer stops the run with its reason (the rest stay queued
/// for the retry).
Future<CollectionUploadResult> runBatchedUpload({
  required List<PendingChange> pending,
  required UploadBatchSender send,
  required UploadBatchApplier apply,
  void Function(int done, int total)? onProgress,
  int batchSize = 5,
}) async {
  final total = pending.length;
  var accepted = 0;
  final rejected = <String>[];
  onProgress?.call(0, total);
  for (final batch in planUploadBatches(pending, size: batchSize)) {
    final Map<String, String> refused;
    try {
      refused = await send(batch);
    } catch (e) {
      return CollectionUploadResult(
          accepted: accepted,
          rejected: rejected,
          total: total,
          error: describeUploadError(e));
    }
    accepted += await apply(batch, refused);
    for (final c in batch) {
      final reason = refused['${c.operation}|${c.itemId}'];
      if (reason != null) rejected.add('${c.itemId}: $reason');
    }
    onProgress?.call(accepted + rejected.length, total);
  }
  return CollectionUploadResult(
      accepted: accepted, rejected: rejected, total: total);
}

/// A collector-facing reason for a batch that got no answer.
String describeUploadError(Object e) {
  final text = e.toString();
  if (text.contains('TimeoutException')) {
    return 'The server took too long to answer.';
  }
  if (text.contains('SocketException') ||
      text.contains('ClientException') ||
      text.contains('HandshakeException') ||
      text.contains('Failed host lookup')) {
    return 'The connection was lost.';
  }
  final status = RegExp(r'Upload failed \((\d+)\)').firstMatch(text);
  if (status != null) {
    return 'The server could not take the upload (${status.group(1)}).';
  }
  return 'The upload stopped.';
}

String? _engagementDate(PendingChange change) {
  try {
    final decoded = jsonDecode(change.payload);
    if (decoded is! Map) return null;
    final stamp = decoded['EngagementDate']?.toString().trim() ?? '';
    return stamp.isEmpty ? null : stamp;
  } catch (_) {
    return null;
  }
}
