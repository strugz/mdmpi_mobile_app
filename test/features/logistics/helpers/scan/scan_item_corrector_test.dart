import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/scan_item_corrector.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/item_table_reading.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/scan_vocab_entry.dart';

ScanVocabEntry _e(String code, String desc, String unit, [int uses = 3]) =>
    ScanVocabEntry(itemCode: code, description: desc, unit: unit, uses: uses);

InventoryItemModel _i(String code, String desc, [String unit = '']) =>
    InventoryItemModel(itemCode: code, description: desc, qty: 1, unit: unit);

ItemTableReading _r(List<InventoryItemModel> items) =>
    ItemTableReading(headerFound: true, items: items);

void main() {
  final vocab = ScanVocabulary([
    _e('OSR6122', 'DxH 500 Cleaner 500mL', 'BOTTLE', 10),
    _e('B36868', 'Lyse Reagent Bottle 1L', 'BOTTLE', 5),
    _e('', 'Control Plasma Level 1', 'BOX'),
    _e('', 'Calibrator Kit', 'KIT'),
  ]);

  test('same item code: the saved description replaces a close misread', () {
    final out = ScanItemCorrector.correct(
        _r([_i('OSR6122', 'DxH 5O0 Clcaner 50OmL')]), vocab);
    expect(out.reading.items.single.description, 'DxH 500 Cleaner 500mL');
    expect(out.changed, 1);
  });

  test('same item code but a different description is left (code misread)',
      () {
    final out = ScanItemCorrector.correct(
        _r([_i('OSR6122', 'Calibrator Kit')]), vocab);
    expect(out.reading.items.single.description, 'Calibrator Kit');
  });

  test('unknown code: words are fixed one by one, case kept', () {
    final out = ScanItemCorrector.correct(
        _r([_i('X1', 'C0NTROL PIasma Leve1 2'), _i('', 'Lyse 8ottle')]), vocab);
    expect(out.reading.items[0].description, 'CONTROL Plasma Level 2');
    expect(out.reading.items[1].description, 'Lyse Bottle');
    expect(out.unknownCodes, {'X1'});
  });

  test('one edit from a long known word', () {
    expect(ScanItemCorrector.correctWord('Calibrafor', vocab), 'Calibrator');
    // Short words need a look-alike, not any edit.
    expect(ScanItemCorrector.correctWord('Kat', vocab), isNull);
  });

  test('known words, numbers and short tokens stay', () {
    expect(ScanItemCorrector.correctWord('Cleaner', vocab), 'Cleaner');
    expect(ScanItemCorrector.correctWord('500', vocab), '500');
    expect(ScanItemCorrector.correctWord('mL', vocab), 'mL');
  });

  test('unknown words are collected for the server with letter variants', () {
    final out =
        ScanItemCorrector.correct(_r([_i('', 'Hemo1yzer Tube')]), vocab);
    expect(out.unknownWords, containsAll(['hemo1yzer', 'hemolyzer']));
    expect(out.unknownWords, contains('tube'));
  });

  test('unit fixed against known units', () {
    final out = ScanItemCorrector.correct(
        _r([_i('', 'Calibrator Kit', '8OX')]), vocab);
    expect(out.reading.items.single.unit, 'BOX');
  });

  test('a unit cell with more than the unit keeps the known unit', () {
    final out = ScanItemCorrector.correct(
        _r([_i('', 'Calibrator Kit', '1.00 BOX')]), vocab);
    expect(out.reading.items.single.unit, 'BOX');
  });

  test('nothing known: reading returned as is', () {
    final reading = _r([_i('', 'Anything here')]);
    final out = ScanItemCorrector.correct(reading, ScanVocabulary(const []));
    expect(identical(out.reading, reading), isTrue);
    expect(out.changed, 0);
  });

  test('variants cover one and two swaps and letter groups', () {
    final v = ScanItemCorrector.variants('c0ntr0l');
    expect(v, contains('control'));
    expect(ScanItemCorrector.variants('rnodule'), contains('module'));
    expect(ScanItemCorrector.variants('bottle'), isNot(contains('bottle')));
  });
}
