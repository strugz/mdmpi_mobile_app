import 'package:mdmpi_mobile_app/features/collection/dtos/collection_item_dto.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';

/// Mapper between the Collection API DTO and the domain model.
///
/// Both sides share the same canonical JSON shape (PascalCase fields, an ACCMST
/// `Client` object and a PascalCase `History` list), so the mapper delegates to
/// [CollectionItemModel.fromJson] / [CollectionItemModel.toJson] and
/// [CollectionItemDto.fromJson] / [CollectionItemDto.toJson] rather than
/// re-implementing field-by-field parsing (which previously drifted out of sync
/// with the client/history key names and silently dropped data).
class CollectionMapper {
  /// Convert API DTO to domain model.
  static CollectionItemModel toDomainModel(CollectionItemDto dto) {
    return CollectionItemModel.fromJson(dto.toJson());
  }

  /// Convert domain model to API DTO.
  static CollectionItemDto toDto(CollectionItemModel model) {
    return CollectionItemDto.fromJson(model.toJson());
  }

  /// Convert list of DTOs to domain models.
  static List<CollectionItemModel> toDomainModels(
      List<CollectionItemDto> dtos) {
    return dtos.map(toDomainModel).toList();
  }

  /// Convert list of domain models to DTOs.
  static List<CollectionItemDto> toDtos(List<CollectionItemModel> models) {
    return models.map(toDto).toList();
  }
}
