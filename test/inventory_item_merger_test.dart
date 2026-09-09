import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/inventory_item_merger.dart';

InventoryItemModel item({
  String itemCode = '',
  String partNo = '',
  String serialNo = '',
  double qty = 1,
  String unit = 'UNIT',
  String description = '',
  String ptn = '',
  List<InventoryBatchModel> batches = const [],
}) {
  return InventoryItemModel(
    itemCode: itemCode,
    description: description,
    qty: qty,
    unit: unit,
    partNo: partNo,
    serialNo: serialNo,
    ptn: ptn,
    batches: batches,
  );
}

void main() {
  group('InventoryItemMerger.merge', () {
    test('keeps the same part with different serials as separate rows', () {
      final existing = [item(partNo: 'AY19270', serialNo: 'SERIAL-A')];
      final incoming = [item(partNo: 'AY19270', serialNo: 'SERIAL-B')];

      final merged =
          InventoryItemMerger.merge(existing: existing, incoming: incoming);

      expect(merged.length, 2);
      expect(merged.map((e) => e.serialNo), containsAll(['SERIAL-A', 'SERIAL-B']));
      expect(merged.every((e) => e.qty == 1), isTrue);
    });

    test('sums quantities when part, code and serial all match', () {
      final existing = [
        item(partNo: 'AY19270', itemCode: '629029', serialNo: 'S1', qty: 2)
      ];
      final incoming = [
        item(partNo: 'AY19270', itemCode: '629029', serialNo: 'S1', qty: 3)
      ];

      final merged =
          InventoryItemMerger.merge(existing: existing, incoming: incoming);

      expect(merged.length, 1);
      expect(merged.single.qty, 5);
    });

    test('fills blank fields on the existing row from the incoming row', () {
      final existing = [item(partNo: 'AY19270', serialNo: 'S1')];
      final incoming = [
        item(
          partNo: 'AY19270',
          serialNo: 'S1',
          description: 'Barcode Gun',
          ptn: 'ACS16-2383',
        )
      ];

      final merged =
          InventoryItemMerger.merge(existing: existing, incoming: incoming);

      expect(merged.single.description, 'Barcode Gun');
      expect(merged.single.ptn, 'ACS16-2383');
    });

    test('does not overwrite values already present on the existing row', () {
      final existing = [
        item(
          partNo: 'AY19270',
          serialNo: 'S1',
          description: 'Original',
          ptn: 'Original ptn',
        )
      ];
      final incoming = [
        item(
          partNo: 'AY19270',
          serialNo: 'S1',
          description: 'Replacement',
          ptn: 'Replacement ptn',
        )
      ];

      final merged =
          InventoryItemMerger.merge(existing: existing, incoming: incoming);

      expect(merged.single.description, 'Original');
      expect(merged.single.ptn, 'Original ptn');
    });

    test('merges batches by batch serial on a matching row', () {
      final existing = [
        item(partNo: 'P1', serialNo: 'S1', batches: [
          InventoryBatchModel(
              batchSerial: 'B-1', batchQuantity: 1, expiryDate: '')
        ])
      ];
      final incoming = [
        item(partNo: 'P1', serialNo: 'S1', batches: [
          InventoryBatchModel(
              batchSerial: 'B-1', batchQuantity: 4, expiryDate: '2026-01-01'),
          InventoryBatchModel(
              batchSerial: 'B-2', batchQuantity: 2, expiryDate: '')
        ])
      ];

      final merged =
          InventoryItemMerger.merge(existing: existing, incoming: incoming);

      expect(merged.single.batches.length, 2);
      final b1 =
          merged.single.batches.firstWhere((b) => b.batchSerial == 'B-1');
      expect(b1.batchQuantity, 4);
      expect(b1.expiryDate, '2026-01-01');
    });

    test('appends rows that match nothing', () {
      final existing = [item(partNo: 'P1', serialNo: 'S1')];
      final incoming = [
        item(partNo: 'P2', serialNo: 'S2'),
        item(partNo: 'P3', serialNo: 'S3'),
      ];

      final merged =
          InventoryItemMerger.merge(existing: existing, incoming: incoming);

      expect(merged.length, 3);
    });

    test('does not mutate the input lists', () {
      final existing = [item(partNo: 'P1', serialNo: 'S1', qty: 1)];
      final incoming = [item(partNo: 'P1', serialNo: 'S1', qty: 1)];

      InventoryItemMerger.merge(existing: existing, incoming: incoming);

      expect(existing.length, 1);
      expect(existing.single.qty, 1);
      expect(incoming.length, 1);
    });
  });
}
