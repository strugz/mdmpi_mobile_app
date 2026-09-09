import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/data/services/sms/sms_message_template_service.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/inventory_item_merger.dart';

/// Guards existing production data against the Stock Issue Slip change.
///
/// Every record created before that change has no part number, serial
/// number or PTN. These tests pin the behaviour for such records so
/// a later edit cannot quietly alter how they identify, display or merge.
void main() {
  /// An item exactly as the API returned it before the slip columns existed.
  InventoryItemModel legacyItem() => InventoryItemModel.fromJson({
        'Item Code': 'ITM-001',
        'Description': 'Paracetamol',
        'Qty': 2,
        'Unit': 'box',
      });

  group('legacy items without slip columns', () {
    test('parse with empty slip fields rather than null', () {
      final item = legacyItem();

      expect(item.partNo, '');
      expect(item.serialNo, '');
      expect(item.ptn, '');
    });

    test('tolerate explicit nulls from the API', () {
      final item = InventoryItemModel.fromJson({
        'Item Code': 'ITM-001',
        'Description': 'Paracetamol',
        'Qty': 2,
        'Unit': 'box',
        'Part No.': null,
        'Serial No.': null,
        'PTN': null,
      });

      expect(item.partNo, '');
      expect(item.serialNo, '');
      expect(item.referenceCode, 'ITM-001');
    });

    test('still identify by item code', () {
      // referenceCode is what labels an item and what keys backload and
      // lost-item remarks. For legacy data it must stay the item code.
      expect(legacyItem().referenceCode, 'ITM-001');
    });

    test('produce the pre-change SMS line exactly', () {
      final line = SmsMessageTemplateService()
          .formatInventoryItemsForSms([legacyItem()]);

      expect(line, '- Paracetamol (ITM-001) x2 box');
    });

    test('still merge by item code when no part or serial is present', () {
      final merged = InventoryItemMerger.merge(
        existing: [legacyItem()],
        incoming: [legacyItem()],
      );

      expect(merged.length, 1);
      expect(merged.single.qty, 4);
      expect(merged.single.referenceCode, 'ITM-001');
    });

    test('do not merge with a different legacy item code', () {
      final other = InventoryItemModel.fromJson({
        'Item Code': 'ITM-002',
        'Description': 'Ibuprofen',
        'Qty': 1,
        'Unit': 'box',
      });

      final merged = InventoryItemMerger.merge(
        existing: [legacyItem()],
        incoming: [other],
      );

      expect(merged.length, 2);
    });

    test('serialize the legacy keys unchanged', () {
      final json = legacyItem().toJson();

      expect(json['Item Code'], 'ITM-001');
      expect(json['Description'], 'Paracetamol');
      expect(json['Qty'], 2);
      expect(json['Unit'], 'box');
      expect(json['batch'], isEmpty);
    });

    test('send the new keys as empty strings, never null', () {
      // An older backend ignores unknown keys, so empty strings are safe.
      // Nulls would be riskier if a consumer ever binds them strictly.
      final json = legacyItem().toJson();

      expect(json['Part No.'], '');
      expect(json['Serial No.'], '');
      expect(json['PTN'], '');
      expect(json.containsKey('Remarks'), isFalse);
    });
  });
}
