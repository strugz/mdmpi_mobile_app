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

  /// When the courier pressed Dispatch (Standard Delivery / Hotline Direct:
  /// `deliveredAt`; Air / Sea / Land: `dispatchedAt`). Raw model string —
  /// the template formats it. Empty when the request type has no dispatch.
  final String dispatchAt;

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
    this.dispatchAt = '',
  });
}

