import 'package:mdmpi_mobile_app/features/collection/dtos/collection_item_dto.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_history_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// Mapper for converting between Collection DTO and domain models.
class CollectionMapper {
  /// Convert API DTO to domain model.
  static CollectionItemModel toDomainModel(CollectionItemDto dto) {
    // Parse client from DTO
    final clientData = dto.client;
    final client = ClientModel(
      id: clientData['id']?.toString() ?? '',
      code: clientData['code']?.toString() ?? dto.bpCode,
      name: clientData['name']?.toString() ?? '',
      address: clientData['address']?.toString() ?? '',
      contact: clientData['contact']?.toString() ?? '',
      emailAddress: clientData['emailAddress']?.toString() ?? '',
    );

    // Parse history from DTO
    final history = dto.history.map((h) {
      return CollectionHistoryModel(
        date: h['date']?.toString() ?? DateTime.now().toIso8601String(),
        collectorName: h['collectorName']?.toString() ?? 'System',
        status: h['status']?.toString() ?? '',
        remarks: h['remarks']?.toString() ?? '',
        totalCollected: (h['totalCollected'] is num
            ? (h['totalCollected'] as num).toDouble()
            : 0.0),
        bankName: h['bankName']?.toString(),
        checkNumber: h['checkNumber']?.toString(),
        checkDate: h['checkDate']?.toString(),
        purposeOfVisit: h['purposeOfVisit']?.toString(),
      );
    }).toList();

    return CollectionItemModel(
      id: dto.id,
      client: client,
      documentReferences: dto.documentReferences,
      bankName: dto.bankName,
      toBeCollected: dto.toBeCollected,
      totalCollected: dto.totalCollected,
      remarks: dto.remarks,
      documentDate: dto.documentDate,
      bpCode: dto.bpCode,
      postingDate: dto.postingDate,
      dueDate: dto.dueDate,
      status: dto.status,
      lastOutcome: dto.lastOutcome,
      assignedAt: dto.assignedAt,
      collectorName: dto.collectorName,
      history: history,
    );
  }

  /// Convert domain model to API DTO.
  static CollectionItemDto toDto(CollectionItemModel model) {
    return CollectionItemDto(
      id: model.id,
      client: {
        'id': model.client.id,
        'code': model.client.code,
        'name': model.client.name,
        'address': model.client.address,
        'contact': model.client.contact,
        'emailAddress': model.client.emailAddress,
      },
      documentReferences: model.documentReferences,
      bankName: model.bankName,
      toBeCollected: model.toBeCollected,
      totalCollected: model.totalCollected,
      remarks: model.remarks,
      documentDate: model.documentDate,
      bpCode: model.bpCode,
      postingDate: model.postingDate,
      dueDate: model.dueDate,
      status: model.status,
      lastOutcome: model.lastOutcome,
      assignedAt: model.assignedAt,
      collectorName: model.collectorName,
      history: model.history
          .map((h) => {
                'date': h.date,
                'collectorName': h.collectorName,
                'status': h.status,
                'remarks': h.remarks,
                'totalCollected': h.totalCollected,
                'bankName': h.bankName,
                'checkNumber': h.checkNumber,
                'checkDate': h.checkDate,
                'purposeOfVisit': h.purposeOfVisit,
              })
          .toList(),
    );
  }

  /// Convert list of DTOs to domain models.
  static List<CollectionItemModel> toDomainModels(List<CollectionItemDto> dtos) {
    return dtos.map((dto) => toDomainModel(dto)).toList();
  }

  /// Convert list of domain models to DTOs.
  static List<CollectionItemDto> toDtos(List<CollectionItemModel> models) {
    return models.map((model) => toDto(model)).toList();
  }
}

