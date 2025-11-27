import 'package:mdmpi_mobile_app/features/logistics/dtos/standard_delivery_dto.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/dtos/client_dto.dart';
import 'package:mdmpi_mobile_app/features/logistics/dtos/remarks_dto.dart';
import 'package:mdmpi_mobile_app/features/logistics/dtos/image_dto.dart';
import 'package:mdmpi_mobile_app/features/logistics/dtos/signature_dto.dart';
import 'package:mdmpi_mobile_app/features/logistics/dtos/standard_delivery_insert_dto.dart';
import 'package:mdmpi_mobile_app/features/logistics/dtos/standard_delivery_update_dto.dart';

// Import the concrete models used by helpers
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/cancel_remarks_model.dart';

class StandardDeliveryMapper {
  static StandardDeliveryModel fromDto(StandardDeliveryDto dto) {
    return StandardDeliveryModel(
      id: dto.id ?? '',
      clientId: dto.clientId ?? '',
      shippingMethod: dto.shippingMethod ?? '',
      deliveryTerms: dto.deliveryTerms ?? '',
      deliveryDate: dto.deliveryDate ?? '',
      preference: dto.preference ?? '',
      status: dto.status ?? '',
      requestBy: dto.requestBy ?? '',
      createdBy: dto.createdBy ?? '',
      itemPreparedBy: dto.itemPreparedBy ?? '',
      deliveredBy: dto.deliveredBy ?? '',
      itemPreparedAt: dto.itemPreparedAt ?? '',
      itemPreparedEndAt: dto.itemPreparedEndAt ?? '',
      deliveredAt: dto.deliveredAt ?? '',
      deliveredEndAt: dto.deliveredEndAt ?? '',
      documentReference: dto.documentReference ?? [],
      client: dto.client != null
          ? _clientDtoToModel(dto.client!)
          : ClientModel.empty(),
      createdAt: dto.createdAt ?? '',
      locationStartedAt: dto.locationStartedAt ?? '',
      locationEndAt: dto.locationEndAt ?? '',
      mobileID: dto.mobileID,
      mobileName: dto.mobileName ?? '',
      helper: dto.helper ?? '',
      receiver: dto.receiver ?? '',
      signature: dto.signature?.path ?? '',
      image: dto.image?.path ?? '',
      tripTicketNumber: dto.tripTicketNumber ?? '',
      cancelRemarks: dto.cancelRemarks != null ? _remarksDtoToModel(dto.cancelRemarks!) : CancelRemarksModel.empty,
    );
  }

  static StandardDeliveryDto toDto(StandardDeliveryModel m) {
    return StandardDeliveryDto(
      id: m.id,
      clientId: m.clientId,
      shippingMethod: m.shippingMethod,
      deliveryTerms: m.deliveryTerms,
      deliveryDate: m.deliveryDate,
      preference: m.preference,
      status: m.status,
      requestBy: m.requestBy,
      createdBy: m.createdBy,
      createdAt: m.createdAt,
      itemPreparedBy: m.itemPreparedBy,
      deliveredBy: m.deliveredBy,
      itemPreparedAt: m.itemPreparedAt,
      itemPreparedEndAt: m.itemPreparedEndAt,
      deliveredAt: m.deliveredAt,
      deliveredEndAt: m.deliveredEndAt,
      mobileID: m.mobileID,
      mobileName: m.mobileName,
      helper: m.helper,
      receiver: m.receiver,
      tripTicketNumber: m.tripTicketNumber,
      locationStartedAt: m.locationStartedAt,
      locationEndAt: m.locationEndAt,
      client: _clientModelToDto(m.client),
      documentReference: m.documentReference,
      cancelRemarks: _cancelRemarksModelToDto(m.cancelRemarks),
      image: m.image.isNotEmpty ? ImageDto(path: m.image) : null,
      signature: m.signature.isNotEmpty ? SignatureDto(path: m.signature) : null,
    );
  }

  // small helpers - adapt these to existing client/cancel models
  static ClientModel _clientDtoToModel(ClientDto dto) {
    return ClientModel(
      id: dto.clientID ?? '',
      code: '',
      name: dto.name ?? '',
      address: '',
      contact: '',
      emailAddress: '',
    );
  }

  static ClientDto _clientModelToDto(ClientModel m) {
    return ClientDto(clientID: m.id, name: m.name);
  }

  static CancelRemarksModel _remarksDtoToModel(RemarksDto dto) {
    return CancelRemarksModel(requestId: '', remarks: dto.remarks ?? '', date: '', userUpdated: '');
  }

  static RemarksDto _cancelRemarksModelToDto(CancelRemarksModel m) {
    return RemarksDto(remarks: m.remarks);
  }

  /// Build API payload for inserting a request. Returns a typed DTO.
  static StandardDeliveryInsertDto toInsertDto(StandardDeliveryModel m) {
    return StandardDeliveryInsertDto(
      requestClientID: m.clientId.isNotEmpty ? m.clientId : null,
      requestShippingMethod: m.shippingMethod.isNotEmpty ? m.shippingMethod : null,
      requestDeliveryTerms: m.deliveryTerms.isNotEmpty ? m.deliveryTerms : null,
      requestDeliveryDate: m.deliveryDate.isNotEmpty ? m.deliveryDate : null,
      requestPreference: m.preference.isNotEmpty ? m.preference : null,
      requestStatus: m.status.isNotEmpty ? m.status : null,
      requestBy: m.requestBy.isNotEmpty ? m.requestBy : null,
      requestCreatedBy: m.createdBy.isNotEmpty ? m.createdBy : null,
      documentReference: m.documentReference.isNotEmpty ? m.documentReference : null,
    );
  }

  /// Build a typed Update DTO for PATCH operations. Only include fields that
  /// are non-null/non-empty per API contract (the DTO's toJson() will omit nulls).
  static StandardDeliveryUpdateDto toUpdateDto(StandardDeliveryModel m) {
    // Normalize request ID to numeric when possible for nested objects
    final dynamic nestedRequestId = int.tryParse(m.id) ?? m.id;

    // Build nested objects only when present
    Map<String, dynamic>? image;
    if (m.image.isNotEmpty) {
      image = {'requestID': nestedRequestId, 'requestImage': m.image};
    }

    Map<String, dynamic>? signature;
    if (m.signature.isNotEmpty) {
      signature = {'requestID': nestedRequestId, 'requestReceiverSignature': m.signature};
    }

    Map<String, dynamic>? remarks;
    if (m.cancelRemarks.remarks.isNotEmpty) {
      remarks = {'requestID': nestedRequestId, 'remarks': m.cancelRemarks.remarks, 'date': m.cancelRemarks.date};
    }

    return StandardDeliveryUpdateDto(
      requestID: m.id.isNotEmpty ? m.id : null,
      requestStatus: m.status.isNotEmpty ? m.status : null,
      requestItemPreparedBy: m.itemPreparedBy.isNotEmpty ? m.itemPreparedBy : null,
      requestDeliveredBy: m.deliveredBy.isNotEmpty ? m.deliveredBy : null,
      requestDriverHelper: m.helper.isNotEmpty ? m.helper : null,
      mobileID: m.mobileID,
      receiver: m.receiver.isNotEmpty ? m.receiver : null,
      requestTripTicketNumber: m.tripTicketNumber.isNotEmpty ? m.tripTicketNumber : null,
      requestItemPreparedAt: m.itemPreparedAt.isNotEmpty ? m.itemPreparedAt : null,
      requestItemPreparedEndAt: m.itemPreparedEndAt.isNotEmpty ? m.itemPreparedEndAt : null,
      requestDeliveredAt: m.deliveredAt.isNotEmpty ? m.deliveredAt : null,
      requestDeliveredEndAt: m.deliveredEndAt.isNotEmpty ? m.deliveredEndAt : null,
      locationStartedAt: m.locationStartedAt.isNotEmpty ? m.locationStartedAt : null,
      locationEndAt: m.locationEndAt.isNotEmpty ? m.locationEndAt : null,
      image: image,
      signature: signature,
      remarks: remarks,
    );
  }
}
