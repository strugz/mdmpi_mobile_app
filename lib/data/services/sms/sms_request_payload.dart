import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';

/// Canonical SMS payload used by template/policy services.
class SmsRequestPayload {
  final String requestId;
  final String requesterCode;
  final String clientName;
  final List<String> documentReferences;
  final String targetDate;
  final String completionActor;
  final String completionActorLabel;
  final String completionAt;
  final String completionTimeLabel;
  final String cancelRemarks;
  final String completionStatusLabel;
  final List<InventoryItemModel> inventoryItems;

  const SmsRequestPayload({
    required this.requestId,
    required this.requesterCode,
    required this.clientName,
    required this.documentReferences,
    required this.targetDate,
    required this.completionActor,
    required this.completionActorLabel,
    required this.completionAt,
    required this.completionTimeLabel,
    required this.cancelRemarks,
    required this.completionStatusLabel,
    this.inventoryItems = const [],
  });
}

