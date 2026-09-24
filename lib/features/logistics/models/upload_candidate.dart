import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_ids.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

/// Where one locally saved request stands against the server's copy, for
/// Settings > Upload Data.
enum UploadCandidateGroup {
  /// The phone is further along than the server: worth uploading.
  ready,

  /// Phone and server hold the same status: nothing to send.
  sameStatus,

  /// The server is further along or the request is finished there; the server
  /// would refuse this copy.
  serverAhead,

  /// The server has no request with this ID.
  notOnServer,
}

extension UploadCandidateGroupX on UploadCandidateGroup {
  String get label => switch (this) {
        UploadCandidateGroup.ready => 'Ready to upload',
        UploadCandidateGroup.sameStatus => 'Same status',
        UploadCandidateGroup.serverAhead => 'Server is ahead',
        UploadCandidateGroup.notOnServer => 'Not on server',
      };

  /// Rows the user may tick. Same-status and server-ahead copies are never
  /// sent: the first changes nothing, the second is refused.
  bool get isSelectable =>
      this == UploadCandidateGroup.ready ||
      this == UploadCandidateGroup.notOnServer;
}

/// One local request, its server copy (if any), and which group it falls in.
class UploadCandidate {
  const UploadCandidate({
    required this.local,
    required this.server,
    required this.group,
    required this.reason,
  });

  final StandardDeliveryModel local;
  final StandardDeliveryModel? server;
  final UploadCandidateGroup group;

  /// One line for the row, e.g. "Item Prepared on phone, For Delivery on server".
  final String reason;

  String get id => local.id;

  bool get isHotlineDirect =>
      local.formCategoryID == FormCategoryIds.hotlineDirect;

  String get clientName {
    final name = local.client.name.trim();
    return name.isEmpty || name == 'N/A' ? 'Request ${local.id}' : name;
  }
}
