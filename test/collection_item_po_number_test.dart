import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/dtos/collection_item_dto.dart';
import 'package:mdmpi_mobile_app/features/collection/mappers/collection_mapper.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';

/// The customer P.O. number (SAP "BP Ref. No.") travels as `PONumber` in the
/// bucket JSON. It is spelled in the DTO, the model and the DAO, so a missed
/// key would silently read blank — these pin the contract end to end.
void main() {
  Map<String, dynamic> bucketJson({Object? po}) => {
        'id': 'INV-1',
        'Client': {'ACCMID': 'NCR-300', 'ACCMSC': 'NCR-300', 'ACCMNM': 'Test'},
        'DocumentReferences': ['INV-1'],
        'ToBeCollected': 100,
        'TotalCollected': 0,
        'BPCode': 'NCR-300',
        if (po != null) 'PONumber': po,
        'PostingDate': '2026-09-01',
        'DueDate': '2026-09-30',
        'Status': '',
        'History': <Map<String, dynamic>>[],
      };

  test('DTO reads PONumber from the API and the mapper carries it to the model',
      () {
    final dto = CollectionItemDto.fromJson(bucketJson(po: ' 2026-0262 '));
    expect(dto.poNumber, '2026-0262');

    final model = CollectionMapper.toDomainModel(dto);
    expect(model.poNumber, '2026-0262');
    expect(model.hasPoNumber, isTrue);
    expect(model.toJson()['PONumber'], '2026-0262');
  });

  test('a missing or null PONumber is blank, never "N/A"', () {
    expect(CollectionItemDto.fromJson(bucketJson()).poNumber, '');
    expect(CollectionItemDto.fromJson(bucketJson(po: null)).poNumber, '');

    final model = CollectionItemModel.fromJson(bucketJson());
    expect(model.poNumber, '');
    expect(model.hasPoNumber, isFalse);

    // A payload built for a save carries no P.O. and must still serialize.
    final save = CollectionItemDto.fromSaveActivityPayload(
        id: 'INV-1', status: 'Collected', remarks: '');
    expect(save.toJson()['PONumber'], '');
  });

  test('copyWith keeps the P.O. unless overridden', () {
    final model = CollectionItemModel.fromJson(bucketJson(po: '23-122'));
    expect(model.copyWith(status: 'Collected').poNumber, '23-122');
    expect(model.copyWith(poNumber: '').hasPoNumber, isFalse);
  });
}
