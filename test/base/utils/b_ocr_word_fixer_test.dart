import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/base/utils/b_ocr_word_fixer.dart';

void main() {
  group('BOcrWordFixer.fix: words', () {
    for (final (read, expected) in [
      ('8ottle', 'Bottle'),
      ('B0TTLE', 'BOTTLE'),
      ('8OTTLE', 'BOTTLE'),
      ('Contr0l', 'Control'),
      ('Bott1e', 'Bottle'),
      ('1nsulin', 'Insulin'),
      ('5odium', 'Sodium'),
      ('M0NITOR', 'MONITOR'),
    ]) {
      test('$read → $expected', () {
        expect(BOcrWordFixer.fix(read), expected);
      });
    }
  });

  group('BOcrWordFixer.fix: numbers', () {
    for (final (read, expected) in [
      ('1O0mL', '100mL'),
      ('5OO', '500'),
      ('1O', '10'),
      ('2O0pcs', '200pcs'),
    ]) {
      test('$read → $expected', () {
        expect(BOcrWordFixer.fix(read), expected);
      });
    }
  });

  group('BOcrWordFixer.fix: left as read', () {
    for (final token in [
      '500mL', '4x15mL', '1l', 'HbA1c', 'H2O', 'CO2', '5DIFF', '3PART',
      'AU480', 'DxH800', 'XN1000', 'S100', 'B12', 'TUBE1', 'COVID19',
      'CD45', 'A1C', 'Pack10', '1st', 'MP1K',
    ]) {
      test(token, () {
        expect(BOcrWordFixer.fix(token), token);
      });
    }
  });

  test('keeps spacing and punctuation in a description', () {
    expect(BOcrWordFixer.fix('DXH 500 Lyse, 8ottle 1O0mL (C0NTROL)'),
        'DXH 500 Lyse, Bottle 100mL (CONTROL)');
  });

  group('BOcrWordFixer.fixUnit', () {
    for (final (read, expected) in [
      ('8OTTLE', 'BOTTLE'),
      ('B0X', 'BOX'),
      ('PC5', 'PCS'),
      ('1PC', '1PC'),
      ('PIECE', 'PIECE'),
      ('', ''),
    ]) {
      test('"$read" → "$expected"', () {
        expect(BOcrWordFixer.fixUnit(read), expected);
      });
    }
  });
}
