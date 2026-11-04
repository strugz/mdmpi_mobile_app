import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/acr_item_filter.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/acr_verdict.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/item_table_reading.dart';

InventoryItemModel _item(String description,
        {double qty = 1, String unit = 'PIECE', String code = ''}) =>
    InventoryItemModel(
        itemCode: code, description: description, qty: qty, unit: unit);

void main() {
  group('evaluate', () {
    test('complete, clean rows are accepted without Gemini', () {
      final v = AcrItemFilter.evaluate(ItemTableReading(
        headerFound: true,
        items: [_item('Optic Bench', code: 'RXH60169'), _item('Lamp', qty: 2)],
      ));
      expect(v.accepted, isTrue);
      expect(v.confidence, 1);
      expect(v.items, hasLength(2));
    });

    test('no table found falls back', () {
      final v = AcrItemFilter.evaluate(ItemTableReading.none);
      expect(v.reasons, [AcrFallbackReason.noTable]);
    });

    test('blank and corrupted rows are dropped', () {
      final v = AcrItemFilter.evaluate(ItemTableReading(
        headerFound: true,
        items: [_item(' | ~ '), _item('Reagent Pack')],
      ));
      expect(v.droppedRows, 1);
      expect(v.items.single.description, 'Reagent Pack');
      expect(v.accepted, isTrue);
    });

    test('only blank rows means no items', () {
      final v = AcrItemFilter.evaluate(
          ItemTableReading(headerFound: true, items: [_item('|||')]));
      expect(v.reasons, [AcrFallbackReason.noItems]);
    });

    test('a missing unit or quantity falls back', () {
      final v = AcrItemFilter.evaluate(ItemTableReading(
        headerFound: true,
        items: [_item('Lamp', unit: ''), _item('Fuse', qty: 0)],
      ));
      expect(v.reasons, contains(AcrFallbackReason.missingFields));
      expect(v.reasons, contains(AcrFallbackReason.lowConfidence));
      expect(v.confidence, 0);
    });

    test('an unsure row lowers confidence under the default threshold', () {
      final reading = ItemTableReading(
        headerFound: true,
        items: [_item('A item'), _item('B item'), _item('C item'), _item('D item')],
        unsure: const {2},
      );
      final strict = AcrItemFilter.evaluate(reading);
      expect(strict.confidence, 0.75);
      expect(strict.reasons, [AcrFallbackReason.lowConfidence]);

      final relaxed = AcrItemFilter.evaluate(reading, minConfidence: 0.7);
      expect(relaxed.accepted, isTrue);
    });
  });

  group('normalize', () {
    test('collapses whitespace and trims scanner artifacts', () {
      expect(AcrItemFilter.normalize('| Optic   Bench\t/ WBC  |'),
          'Optic Bench / WBC');
      expect(AcrItemFilter.normalize('~* PIECE ;'), 'PIECE');
      expect(AcrItemFilter.normalize('[RXH60169]'), 'RXH60169');
    });

    test('keeps a trailing period, inch mark and brackets', () {
      expect(AcrItemFilter.normalize('Assy.'), 'Assy.');
      expect(AcrItemFilter.normalize('Monitor 3.5"'), 'Monitor 3.5"');
      expect(AcrItemFilter.normalize('Led (OPN:RXH60021)'),
          'Led (OPN:RXH60021)');
    });
  });

  group('minConfidenceFrom', () {
    test('reads and clamps ACR_MIN_CONFIDENCE', () {
      expect(AcrItemFilter.minConfidenceFrom({}), 1.0);
      expect(AcrItemFilter.minConfidenceFrom({'ACR_MIN_CONFIDENCE': '0.8'}),
          0.8);
      expect(AcrItemFilter.minConfidenceFrom({'ACR_MIN_CONFIDENCE': '5'}), 1.0);
      expect(
          AcrItemFilter.minConfidenceFrom({'ACR_MIN_CONFIDENCE': 'x'}), 1.0);
    });
  });
}
