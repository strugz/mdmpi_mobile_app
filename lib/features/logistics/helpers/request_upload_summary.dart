import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/data/repositories/standard_delivery/delivery_update_outcome.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/upload_candidate_classifier.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

/// What Settings > Upload Data achieved across the locally saved requests.
///
/// The server refuses (409) a request that is already done, would move
/// backwards, or is older than what it holds; those are "skipped" and listed
/// with the server's reason. Anything else that did not go through is
/// "failed" and worth retrying.
///
/// After the upload, [refreshSkipped] replaces each skipped request on the
/// phone with the server's copy, so the same stale copy is not sent again.
class RequestUploadSummary {
  RequestUploadSummary();

  /// Reasons shown in the snackbar before collapsing into "+N more".
  static const int maxListedReasons = 3;

  /// Accepted requests that moved the status forward on the server.
  int uploaded = 0;

  /// Accepted requests whose status the server already had: nothing new.
  int sameStatus = 0;

  final List<String> skipped = [];
  final List<String> failed = [];

  /// IDs of the skipped requests, in the order they were sent.
  final List<String> skippedIds = [];

  /// Skipped requests replaced on the phone with the server's copy.
  int refreshed = 0;

  /// Set when the server's copies could not be fetched.
  String? refreshError;

  bool get isClean => skipped.isEmpty && failed.isEmpty;

  /// Requests that were sent, whatever came back.
  int get attempted => uploaded + sameStatus + skipped.length + failed.length;

  /// Sends every locally modified request (anything past New Request) through
  /// [send] and tallies the outcomes. One refusal never stops the rest.
  ///
  /// [onProgress] is called with (0, total) before the first send and after
  /// each one, so a progress UI can show "3 of 8".
  static Future<RequestUploadSummary> run(
    Iterable<StandardDeliveryModel> requests,
    Future<DeliveryUpdateOutcome> Function(StandardDeliveryModel request)
        send, {
    void Function(int done, int total)? onProgress,
  }) async {
    final summary = RequestUploadSummary();
    final pending = requests
        .where((request) => request.status != BTexts.statusNewRequest)
        .toList();
    onProgress?.call(0, pending.length);
    for (final request in pending) {
      final outcome = await send(request);
      switch (outcome.status) {
        case DeliveryUpdateStatus.updated:
          if (outcome.sameStatus) {
            summary.sameStatus++;
          } else {
            summary.uploaded++;
          }
        case DeliveryUpdateStatus.rejected:
          summary.skipped.add(outcome.message);
          summary.skippedIds.add(request.id);
        case DeliveryUpdateStatus.failed:
          summary.failed.add('Request ${request.id}: ${outcome.message}');
      }
      onProgress?.call(summary.attempted, pending.length);
    }
    return summary;
  }

  /// [run], minus the requests whose status the server already holds.
  ///
  /// Those are not sent at all (re-sending them changes nothing but can put
  /// the phone's older crew or trip ticket back); they are counted in
  /// [sameStatus] instead. If the server's list cannot be fetched, everything
  /// is sent and the server's own `sameStatus` reply does the counting.
  static Future<RequestUploadSummary> runSkippingSameStatus(
    Iterable<StandardDeliveryModel> requests,
    Future<DeliveryUpdateOutcome> Function(StandardDeliveryModel request)
        send, {
    required Future<List<StandardDeliveryModel>> Function() fetchServer,
    void Function(int done, int total)? onProgress,
  }) async {
    var toSend = requests.toList();
    var alreadySame = 0;
    try {
      final serverStatus = {
        for (final r in await fetchServer()) r.id: r.status,
      };
      bool isSameAsServer(StandardDeliveryModel request) {
        final status = serverStatus[request.id];
        return status != null &&
            BUploadCandidateClassifier.sameStatus(status, request.status);
      }

      final same = toSend
          .where((r) => r.status != BTexts.statusNewRequest)
          .where(isSameAsServer)
          .length;
      toSend = toSend.where((r) => !isSameAsServer(r)).toList();
      alreadySame = same;
    } catch (e) {
      logDebug(
          'RequestUploadSummary: server list unavailable, sending all: $e');
    }
    final summary = await run(toSend, send, onProgress: onProgress);
    summary.sameStatus += alreadySame;
    return summary;
  }

  /// Replaces every skipped request on the phone with the server's copy.
  ///
  /// [fetchServer] returns the server's requests; [replaceLocal] overwrites
  /// the local row even when that moves the status backwards, which is the
  /// point: the server has just said its copy wins. A skipped request missing
  /// from the server's list is left alone. Never throws.
  Future<void> refreshSkipped({
    required Future<List<StandardDeliveryModel>> Function() fetchServer,
    required Future<void> Function(StandardDeliveryModel serverCopy)
        replaceLocal,
  }) async {
    if (skippedIds.isEmpty) return;
    try {
      final serverCopies = {
        for (final request in await fetchServer()) request.id: request,
      };
      for (final id in skippedIds) {
        final serverCopy = serverCopies[id];
        if (serverCopy == null) continue;
        await replaceLocal(serverCopy);
        refreshed++;
      }
    } catch (e) {
      refreshError = e.toString();
      logDebug('RequestUploadSummary.refreshSkipped failed: $e');
    }
  }

  String get title {
    if (attempted == 0) return 'Nothing to upload';
    if (failed.isNotEmpty) return 'Upload incomplete';
    if (skipped.isNotEmpty) return 'Upload finished with skipped requests';
    if (uploaded == 0) return 'Already up to date';
    return 'Upload complete';
  }

  String get message {
    if (attempted == 0) {
      return 'This phone has no changes the server is missing.';
    }
    final lines = <String>[
      uploaded == 1 ? 'Uploaded 1 request.' : 'Uploaded $uploaded requests.',
      if (sameStatus > 0)
        sameStatus == 1
            ? '1 request has the same status as the server.'
            : '$sameStatus requests have the same status as the server.',
    ];
    if (skipped.isNotEmpty) {
      lines.add('Skipped ${skipped.length} (the server already has newer '
          'or finished data):');
      lines.addAll(_listed(skipped));
      if (refreshError != null) {
        lines.add('Could not reload them from the server. Run Hard Reset '
            'Refresh before uploading again.');
      } else if (refreshed > 0) {
        lines.add(refreshed == skipped.length
            ? "This phone now has the server's copy of "
                '${refreshed == 1 ? 'it' : 'them'}.'
            : "This phone now has the server's copy of $refreshed of them.");
      }
    }
    if (failed.isNotEmpty) {
      lines.add('Failed ${failed.length} (try again later):');
      lines.addAll(_listed(failed));
    }
    return lines.join('\n');
  }

  /// Shows the summary: success when everything went up, a warning when the
  /// server skipped some, an error when some failed.
  void show() {
    if (failed.isNotEmpty) {
      BLoaders.errorSnackBar(title: title, message: message, duration: 8);
    } else if (skipped.isNotEmpty) {
      BLoaders.warningSnackBar(title: title, message: message, duration: 8);
    } else {
      BLoaders.successSnackBar(title: title, message: message);
    }
  }

  static Iterable<String> _listed(List<String> reasons) sync* {
    for (final reason in reasons.take(maxListedReasons)) {
      yield '• $reason';
    }
    if (reasons.length > maxListedReasons) {
      yield '• +${reasons.length - maxListedReasons} more';
    }
  }
}
