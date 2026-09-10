import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/data/services/sms/sms_request_payload.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pick_up_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_ids.dart';

/// Builds [SmsRequestPayload] from domain request models.
///
/// [cancelRemarksResolver] is an optional async seam injected by the caller
/// to fetch cancel remarks from local DB when needed, so this class remains
/// pure and testable without a DB dependency.
class SmsPayloadBuilder {
  final Future<String> Function(String requestId)? cancelRemarksResolver;

  const SmsPayloadBuilder({this.cancelRemarksResolver});

  /// Returns [SmsRequestPayload] for supported model types, or `null` if the
  /// model type is not supported.
  Future<SmsRequestPayload?> build(
    String status,
    Object requestModel, {
    String? overrideCancelRemarks,
    List<InventoryItemModel>? inventoryItems,
  }) async {
    final normalizedOverride = overrideCancelRemarks?.trim() ?? '';

    switch (requestModel) {
      case StandardDeliveryModel model:
        return _buildForStandardDelivery(
          status,
          model,
          normalizedOverride,
          inventoryItems: inventoryItems,
        );
      case PickUpModel model:
        return _buildForPickUp(model, normalizedOverride);
      case PullOutModel model:
        return _buildForPullOut(model, normalizedOverride);
      case AirSeaModel model:
        return _buildForAirSea(status, model, normalizedOverride);
      default:
        return null;
    }
  }

  Future<SmsRequestPayload> _buildForStandardDelivery(
    String status,
    StandardDeliveryModel model,
    String normalizedOverride, {
    List<InventoryItemModel>? inventoryItems,
  }) async {
    final cancelRemarks = normalizedOverride.isNotEmpty
        ? normalizedOverride
        : status == BTexts.statusCancelled
            ? await _resolveCancelRemarks(model.id)
            : model.cancelRemarks.remarks;

    final isPullOut = model.documentReference
        .any((ref) => ref.toUpperCase().contains('PULL OUT'));

    return SmsRequestPayload(
      requestId: model.id,
      requesterCode: model.requestBy,
      clientName: model.client.name,
      documentReferences: model.documentReference,
      targetDate: model.deliveryDate,
      completionActor: model.receiver,
      completionActorLabel: 'Received By',
      completionAt: model.deliveredEndAt,
      completionTimeLabel: 'Date Time Received',
      cancelRemarks: cancelRemarks,
      completionStatusLabel: isPullOut ? 'PULLED OUT' : 'DELIVERED',
      inventoryItems: inventoryItems ?? [],
      // Stamped locally on the Item Prepared -> For Delivery (Dispatch) step.
      dispatchAt: model.deliveredAt,
    );
  }

  SmsRequestPayload _buildForPickUp(
    PickUpModel model,
    String normalizedOverride,
  ) {
    return SmsRequestPayload(
      requestId: model.id,
      requesterCode: model.createdBy,
      clientName: model.client.name,
      documentReferences: model.documentReference,
      targetDate: model.datePickUp,
      completionActor: model.receivedBy,
      completionActorLabel: 'Received By',
      completionAt: model.updatedAt,
      completionTimeLabel: 'Date Time Updated',
      cancelRemarks:
          normalizedOverride.isNotEmpty ? normalizedOverride : model.remarks,
      completionStatusLabel: 'RECEIVED',
      inventoryItems: const [],
    );
  }

  SmsRequestPayload _buildForPullOut(
    PullOutModel model,
    String normalizedOverride,
  ) {
    final isStockReceive = model.formCategoryId == FormCategoryIds.stockReceive;

    return SmsRequestPayload(
      requestId: model.id,
      requesterCode:
          model.requestedBy.isNotEmpty ? model.requestedBy : model.createdBy,
      clientName: model.client.name,
      documentReferences: model.documentReference,
      targetDate: model.pullOutDate,
      completionActor: model.releasedBy,
      completionActorLabel: 'Released By',
      completionAt: model.pullOutDateEndAt,
      completionTimeLabel: 'Date Time Completed',
      cancelRemarks: normalizedOverride.isNotEmpty
          ? normalizedOverride
          : model.cancelRemarks.remarks,
      completionStatusLabel: isStockReceive ? 'STOCK RECEIVED' : 'TAKEN OUT',
      inventoryItems: const [],
    );
  }

  SmsRequestPayload _buildForAirSea(
    String status,
    AirSeaModel model,
    String normalizedOverride,
  ) {
    return SmsRequestPayload(
      requestId: model.id,
      requesterCode: model.createdBy,
      clientName: model.client.name,
      documentReferences: model.documentReference,
      targetDate: model.datePickUp,
      completionActor: _resolveAirSeaCompletionActor(status, model),
      completionActorLabel: _resolveAirSeaCompletionActorLabel(status),
      completionAt: _resolveAirSeaCompletionTime(status, model),
      completionTimeLabel: _resolveAirSeaCompletionTimeLabel(status),
      cancelRemarks: normalizedOverride.isNotEmpty
          ? normalizedOverride
          : model.cancelRemarks.remarks,
      completionStatusLabel: _resolveAirSeaCompletionStatusLabel(status),
      inventoryItems: const [],
      dispatchAt: model.dispatchedAt,
    );
  }

  Future<String> _resolveCancelRemarks(String requestId) async {
    if (cancelRemarksResolver != null) {
      return cancelRemarksResolver!(requestId);
    }
    return '';
  }

  // ── AirSea completion resolvers ──────────────────────────────────────────

  String _resolveAirSeaCompletionActor(String status, AirSeaModel model) {
    switch (status) {
      case BTexts.statusReceived:
        return model.receivedBy;
      case BTexts.statusEndorsedToGuard:
        return model.endorsedBy;
      case BTexts.statusDropOff:
        return model.receivedBy;
      case BTexts.statusProvincialDelivered:
        return model.provincialReceiverName;
      default:
        return model.receivedBy;
    }
  }

  String _resolveAirSeaCompletionActorLabel(String status) {
    switch (status) {
      case BTexts.statusEndorsedToGuard:
        return 'Endorsed By';
      default:
        return 'Received By';
    }
  }

  String _resolveAirSeaCompletionTime(String status, AirSeaModel model) {
    switch (status) {
      case BTexts.statusReceived:
        return model.receivedAt;
      case BTexts.statusDropOff:
        return model.dropOffAt;
      case BTexts.statusProvincialDelivered:
        return model.provincialDeliveredEndAt;
      default:
        return model.updatedAt;
    }
  }

  String _resolveAirSeaCompletionTimeLabel(String status) {
    switch (status) {
      case BTexts.statusDropOff:
        return 'Date Time Dropped Off';
      case BTexts.statusProvincialDelivered:
        return 'Date Time Delivered';
      default:
        return 'Date Time Received';
    }
  }

  String _resolveAirSeaCompletionStatusLabel(String status) {
    switch (status) {
      case BTexts.statusReceived:
        return 'RECEIVED';
      case BTexts.statusDropOff:
        return 'DROPPED OFF';
      case BTexts.statusProvincialDelivered:
        return 'PROVINCIAL DELIVERED';
      case BTexts.statusEndorsedToGuard:
        return 'ENDORSED TO GUARD';
      default:
        return status.toUpperCase();
    }
  }
}

