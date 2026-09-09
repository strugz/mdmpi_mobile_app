import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';

void main() {
  group('InventoryItemModel Stock Issue Slip fields', () {
    test('toJson emits every slip column', () {
      final item = InventoryItemModel(
        itemCode: '629029',
        description: 'Dell 800 Hematology System Analyzer',
        qty: 1,
        unit: 'UNIT',
        partNo: 'AY19270',
        serialNo: 'FA2440433',
        ptn: 'ACS16-6435',
      );

      final json = item.toJson();

      expect(json['Qty'], 1);
      expect(json['Unit'], 'UNIT');
      expect(json['Part No.'], 'AY19270');
      expect(json['Item Code'], '629029');
      expect(json['Description'], 'Dell 800 Hematology System Analyzer');
      expect(json['Serial No.'], 'FA2440433');
      expect(json['PTN'], 'ACS16-6435');
      expect(json.containsKey('Remarks'), isFalse,
          reason: 'the client does not send remarks');
    });

    test('fromJson round-trips toJson', () {
      final original = InventoryItemModel(
        itemCode: '629029',
        description: 'Barcode Gun',
        qty: 2.5,
        unit: 'PIECE',
        partNo: 'AY19270',
        serialNo: 'FA2440433',
        ptn: 'ACS16-2383',
        batches: [
          InventoryBatchModel(
            batchSerial: 'B-001',
            batchQuantity: 2.5,
            expiryDate: '2026-12-31',
          ),
        ],
      );

      final restored = InventoryItemModel.fromJson(original.toJson());

      expect(restored.itemCode, original.itemCode);
      expect(restored.description, original.description);
      expect(restored.qty, original.qty);
      expect(restored.unit, original.unit);
      expect(restored.partNo, original.partNo);
      expect(restored.serialNo, original.serialNo);
      expect(restored.ptn, original.ptn);
      expect(restored.batches.length, 1);
      expect(restored.batches.first.batchSerial, 'B-001');
    });

    test('fromJson accepts alias keys the OCR may return', () {
      final item = InventoryItemModel.fromJson({
        'partno': 'AY19270',
        'Serial Number': 'FA2440433',
        'ptn': 'ACS16-6435',
        'Qty': '3',
        'um': 'UNIT',
        'Description': 'Keyboard',
      });

      expect(item.partNo, 'AY19270');
      expect(item.serialNo, 'FA2440433');
      expect(item.ptn, 'ACS16-6435');
      expect(item.qty, 3);
      expect(item.unit, 'UNIT');
      expect(item.itemCode, '');
    });

    test('missing slip columns default to empty strings', () {
      final item = InventoryItemModel.fromJson({
        'Item Code': '629029',
        'Description': 'Mouse',
        'Qty': 1,
        'Unit': 'PIECE',
      });

      expect(item.partNo, '');
      expect(item.serialNo, '');
      expect(item.ptn, '');
    });

    test('mergeKey ignores case and surrounding whitespace', () {
      final a = InventoryItemModel(
        itemCode: 'C1',
        description: '',
        qty: 1,
        unit: '',
        partNo: ' AY19270 ',
        serialNo: 'fa2440433',
      );
      final b = InventoryItemModel(
        itemCode: 'c1',
        description: '',
        qty: 1,
        unit: '',
        partNo: 'ay19270',
        serialNo: 'FA2440433',
      );

      expect(a.mergeKey, b.mergeKey);
    });

    test('mergeKey separates the same part with different serials', () {
      final a = InventoryItemModel(
        itemCode: 'C1',
        description: '',
        qty: 1,
        unit: '',
        partNo: 'AY19270',
        serialNo: 'SERIAL-A',
      );
      final b = InventoryItemModel(
        itemCode: 'C1',
        description: '',
        qty: 1,
        unit: '',
        partNo: 'AY19270',
        serialNo: 'SERIAL-B',
      );

      expect(a.mergeKey, isNot(b.mergeKey));
    });

    test('referenceCode prefers the part number', () {
      final item = InventoryItemModel(
        itemCode: '629029',
        description: '',
        qty: 1,
        unit: '',
        partNo: 'AY19270',
      );

      expect(item.referenceCode, 'AY19270');
    });

    test('referenceCode falls back to the item code for older records', () {
      final item = InventoryItemModel(
        itemCode: '629029',
        description: '',
        qty: 1,
        unit: '',
      );

      expect(item.referenceCode, '629029');
    });

    test('copyWith replaces only the named fields', () {
      final item = InventoryItemModel(
        itemCode: 'C1',
        description: 'Monitor',
        qty: 1,
        unit: 'UNIT',
        partNo: 'P1',
        serialNo: 'S1',
        ptn: 'T1',
      );

      final updated = item.copyWith(qty: 4, unit: 'BOX');

      expect(updated.qty, 4);
      expect(updated.unit, 'BOX');
      expect(updated.itemCode, 'C1');
      expect(updated.partNo, 'P1');
      expect(updated.serialNo, 'S1');
      expect(updated.ptn, 'T1');
      expect(updated.description, 'Monitor');
    });
  });
}
