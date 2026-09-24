import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/upload_candidate.dart';

/// Sorts the phone's saved requests against the server's copies, so Upload
/// Data only sends what the server is missing.
///
/// Pure: no I/O, so the rules are testable on their own. The status order
/// mirrors the backend's `StatusFlow` (RequestRepository.ValidateUpdateAsync);
/// Cancelled and Delivered are finished and never change again.
class BUploadCandidateClassifier {
  BUploadCandidateClassifier._();

  static const List<String> statusFlow = [
    BTexts.statusNewRequest,
    BTexts.statusGettingSuppliesReady,
    BTexts.statusItemPrepared,
    BTexts.statusForDelivery,
    BTexts.statusInTransit,
    BTexts.statusDoneDelivery,
  ];

  static String _norm(String status) => status.trim().toLowerCase();

  static bool sameStatus(String a, String b) => _norm(a) == _norm(b);

  /// Position in [statusFlow], or -1 for a status outside the flow.
  static int stepOf(String status) =>
      statusFlow.indexWhere((s) => _norm(s) == _norm(status));

  static bool isFinished(String status) =>
      sameStatus(status, BTexts.statusDoneDelivery) ||
      sameStatus(status, BTexts.statusCancelled);

  /// Every local request past New Request, each with its group, in the order
  /// the page shows them: ready first, then not-on-server, same status and
  /// server-ahead; newest request first within a group.
  static List<UploadCandidate> classify({
    required Iterable<StandardDeliveryModel> local,
    required Iterable<StandardDeliveryModel> server,
  }) {
    final serverById = {for (final r in server) r.id: r};
    final candidates = <UploadCandidate>[
      for (final request in local)
        if (!sameStatus(request.status, BTexts.statusNewRequest))
          classifyOne(request, serverById[request.id]),
    ];
    candidates.sort((a, b) {
      final byGroup = _order(a.group).compareTo(_order(b.group));
      return byGroup != 0 ? byGroup : b.id.compareTo(a.id);
    });
    return candidates;
  }

  static UploadCandidate classifyOne(
      StandardDeliveryModel local, StandardDeliveryModel? server) {
    UploadCandidate make(UploadCandidateGroup group, String reason) =>
        UploadCandidate(
            local: local, server: server, group: group, reason: reason);

    final phone = local.status.trim();
    if (server == null) {
      return make(UploadCandidateGroup.notOnServer,
          '$phone on phone; the server has no request ${local.id}');
    }
    final onServer = server.status.trim();

    if (sameStatus(phone, onServer)) {
      return make(
          UploadCandidateGroup.sameStatus, '$onServer on phone and server');
    }
    if (isFinished(onServer)) {
      return make(
          UploadCandidateGroup.serverAhead, 'Already $onServer on the server');
    }

    final phoneStep = stepOf(phone);
    final serverStep = stepOf(onServer);
    if (phoneStep >= 0 && serverStep >= 0 && phoneStep < serverStep) {
      return make(UploadCandidateGroup.serverAhead,
          '$phone on phone, $onServer on server');
    }
    return make(
        UploadCandidateGroup.ready, '$phone on phone, $onServer on server');
  }

  static int _order(UploadCandidateGroup group) => switch (group) {
        UploadCandidateGroup.ready => 0,
        UploadCandidateGroup.notOnServer => 1,
        UploadCandidateGroup.sameStatus => 2,
        UploadCandidateGroup.serverAhead => 3,
      };
}
