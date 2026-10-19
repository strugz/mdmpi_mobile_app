import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/item_table_parser.dart';

/// Hand-made OCR lines laid out like the sample photos in plan §1.

OcrLine _l(String text, double left, double top, double width,
        [double height = 20]) =>
    OcrLine(text, Rect.fromLTWH(left, top, width, height));

void main() {
  group('samples', () {
    test('S1 Inventory Transfer Request: wrapped description, prices ignored',
        () {
      final r = ItemTableParser.parse([
        _l('Details', 68, 540, 68),
        _l('Item Code', 105, 585, 97),
        _l('Description', 349, 585, 107),
        _l('From Warehouse', 555, 585, 162),
        _l('Warehouse', 749, 585, 107),
        _l('Qty', 918, 585, 34),
        _l('Unit', 1031, 585, 40),
        _l('Unit Price', 1215, 585, 92),
        _l('Total', 1458, 585, 48),
        _l('RXH60169', 105, 617, 97),
        _l('Optic Bench / WBC Chamber', 252, 617, 262),
        _l('MAINSPA', 593, 617, 88),
        _l('SVC103', 754, 617, 82),
        _l('1.00', 916, 617, 40),
        _l('PIECE', 1031, 617, 55),
        _l('0.00', 1260, 617, 40),
        _l('0.00', 1458, 617, 40),
        _l('Assy w/ Pre-Screened Hgb', 252, 644, 224),
        _l('Led (OPN:RXH60021)', 252, 670, 190),
        _l('Comments:', 68, 1402, 96),
        _l('ACD thru viber 0856 Galinato Clinic and Hospital', 60, 1445, 976),
      ]);

      expect(r.headerFound, isTrue);
      expect(r.items, hasLength(1));
      final item = r.items.single;
      expect(item.itemCode, 'RXH60169');
      expect(item.description,
          'Optic Bench / WBC Chamber Assy w/ Pre-Screened Hgb Led (OPN:RXH60021)');
      expect(item.qty, 1);
      expect(item.unit, 'PIECE');
      expect(r.unsure, isEmpty);
    });

    test('S1 device capture: a missed wrap line still leaves one item', () {
      // "Assy w/ Pre-Screened Hgb" not read, so "Led (OPN:...)" sits two
      // lines below the item; "| Comments:" with the grey bar read as "|".
      final r = ItemTableParser.parse([
        _l('Item Code', 105, 585, 97),
        _l('Description', 349, 585, 107),
        _l('From Warehouse', 555, 585, 162),
        _l('Warehouse', 749, 585, 107),
        _l('Qty', 918, 585, 34),
        _l('Unit', 1031, 585, 40),
        _l('Unit Price', 1215, 585, 92),
        _l('Total', 1458, 585, 48),
        _l('RXH60169', 105, 617, 97),
        _l('Optic Bench / WBC Chamber', 252, 617, 262),
        _l('MAINSPA', 593, 617, 88),
        _l('SVC103', 754, 617, 82),
        _l('1.00', 916, 617, 40),
        _l('PIECE', 1031, 617, 55),
        _l('Led (OPN:RXH60021)', 252, 670, 190),
        _l('| Comments:', 52, 700, 112),
        _l('ACD thru viber 0856 Galinato Clinic and Hospital', 60, 730, 976),
      ]);
      expect(r.items, hasLength(1));
      expect(r.items.single.description,
          'Optic Bench / WBC Chamber Led (OPN:RXH60021)');
      expect(r.unsure, isEmpty);
    });

    test('S1 device capture: the prices read on the wrap line, Total title missed',
        () {
      // Tilted photo: "0.00 0.00" sits low enough to join the "Assy w/" row,
      // and with Unit Price / Total unread they fall in the Unit column.
      final r = ItemTableParser.parse([
        _l('Item Code', 105, 585, 97),
        _l('Description', 349, 585, 107),
        _l('From Warehouse', 555, 585, 162),
        _l('Warehouse', 749, 585, 107),
        _l('Qty', 918, 585, 34),
        _l('Unit', 1031, 585, 40),
        _l('RXH60169', 105, 617, 97),
        _l('Optic Bench/ WBC Chamber', 252, 617, 262),
        _l('MAINSPA', 593, 617, 88),
        _l('SVC103', 754, 617, 82),
        _l('1.00', 916, 617, 40),
        _l('PIECE', 1031, 617, 55),
        _l('0.00 0.00', 1260, 642, 240),
        _l('Assy w/ Pre-Screened Hgb', 252, 644, 224),
        _l('Led (OPN:RXH60021)', 252, 670, 190),
      ]);
      expect(r.items, hasLength(1));
      final item = r.items.single;
      expect(item.itemCode, 'RXH60169');
      expect(item.description,
          'Optic Bench/ WBC Chamber Assy w/ Pre-Screened Hgb Led (OPN:RXH60021)');
      expect(item.qty, 1);
      expect(item.unit, 'PIECE');
    });

    test('S2 Stock Issue Slip: typed and handwritten rows, SR note dropped', () {
      final r = ItemTableParser.parse([
        _l('QTY', 95, 545, 50, 24),
        _l('UM', 195, 545, 45, 24),
        _l('PART NO.', 325, 545, 123, 24),
        _l('ITEM DESCRIPTION', 710, 545, 252, 24),
        _l('SERIAL NO.', 1222, 545, 150, 24),
        _l('PTN', 1545, 545, 64, 24),
        _l('REMARKS', 1760, 545, 136, 24),
        _l('1', 128, 617, 10, 24),
        _l('UNIT', 180, 617, 65, 24),
        _l('BT120', 322, 617, 80, 24),
        _l('BT120 Auto Blood Culture Analyzer', 550, 617, 430, 24),
        _l('20260904012', 1215, 617, 160, 24),
        _l('FA26-0609', 1453, 617, 136, 24),
        _l('DEMO', 1755, 617, 96, 24),
        _l('1', 130, 683, 10, 24),
        _l('PIECE', 175, 683, 80, 24),
        _l('LOC200987', 322, 683, 130, 24),
        _l('1 KVA UPS / MP1K - K STAR', 553, 683, 362, 24),
        _l('47245800082', 1215, 683, 160, 24),
        _l('ACS26-09742', 1453, 683, 170, 24),
        _l('1', 125, 732, 10, 30),
        _l('PIECE', 180, 732, 75, 30),
        _l('WIRELESS KEYBOARD', 557, 732, 360, 30),
        _l('ACS26-08061', 1213, 732, 215, 30),
        _l('1', 122, 795, 10, 30),
        _l('PIECE', 180, 795, 75, 30),
        _l('WIRELESS MOUSE', 567, 795, 280, 30),
        _l('ACS26-08062', 1208, 795, 215, 30),
        _l('l', 125, 860, 10, 30),
        _l('PIECE', 180, 860, 75, 30),
        _l('BARCODE GUN', 573, 860, 255, 30),
        _l('ACS26-08063', 1206, 860, 220, 30),
        _l('SR: JRQ', 748, 1100, 108, 24),
        _l('Received items in good condition:', 1440, 1370, 460, 24),
      ]);

      expect(r.items.map((i) => i.description), [
        'BT120 Auto Blood Culture Analyzer',
        '1 KVA UPS / MP1K - K STAR',
        'WIRELESS KEYBOARD',
        'WIRELESS MOUSE',
        'BARCODE GUN',
      ]);
      final first = r.items.first;
      expect(first.qty, 1);
      expect(first.unit, 'UNIT');
      expect(first.partNo, 'BT120');
      expect(first.serialNo, '20260904012');
      expect(first.ptn, 'FA26-0609');
      expect(r.items[2].serialNo, 'ACS26-08061');
      expect(r.items[4].qty, 1, reason: 'handwritten "1" read as "l"');
      expect(r.unsure, isEmpty);
      expect(r.dropped, ['SR: JRQ']);
      expect(r.tableTexts, contains('FA26-0609'));
    });

    test('S4 Acknowledgement Receipt: tilted header, sub-header skipped', () {
      final r = ItemTableParser.parse([
        _l('QTY', 155, 540, 38, 22),
        _l('TAG/PART NO', 245, 543, 123, 22),
        _l('DESCRIPTION', 610, 553, 113, 22),
        _l('TAKEN FROM', 1475, 553, 117, 22),
        _l('LOT/SERIAL NO', 957, 555, 130, 22),
        _l('EXPIRY DATE', 1147, 557, 107, 22),
        _l('UNIT', 1380, 582, 50, 18),
        _l('SERIAL NO', 1610, 584, 85, 18),
        _l('1', 170, 605, 12, 25),
        _l('11575181', 245, 603, 125, 26),
        _l('6C1 HD TRANSDUCER - H', 548, 610, 237, 22),
        _l('26340214', 930, 600, 180, 40),
        _l('REMARKS', 157, 1080, 86),
        _l('PURCHASED PROBE', 572, 1085, 232, 26),
      ]);

      expect(r.items, hasLength(1));
      final item = r.items.single;
      expect(item.partNo, '11575181');
      expect(item.description, '6C1 HD TRANSDUCER - H');
      expect(item.serialNo, '26340214');
      expect(item.qty, 1);
    });

    test('S5 Materials Issuance Slip: handwritten, note joins the item above',
        () {
      final r = ItemTableParser.parse([
        _l('MIS No.', 1478, 198, 108),
        _l('SERIAL / PART NO.', 118, 268, 302, 30),
        _l('DESCRIPTION', 948, 272, 227, 30),
        _l('QUANTITY', 1702, 272, 170, 30),
        _l('BO1131', 128, 310, 90, 30),
        _l('HINGE, DOOR', 690, 318, 210, 30),
        _l('1', 1775, 318, 8, 20),
        _l('BO1132', 128, 365, 105, 30),
        _l('MOUNTING PLATE, HINGE CONCEALED', 690, 375, 560, 30),
        _l('1', 1780, 380, 8, 20),
        _l('TAKEN FROM BXH 800 (SN:A21230)', 985, 428, 600, 30),
        _l('REMARKS / PURPOSE', 57, 862, 355, 30),
      ]);

      expect(r.items.map((i) => (i.partNo, i.description, i.qty)), [
        ('BO1131', 'HINGE, DOOR', 1.0),
        (
          'BO1132',
          'MOUNTING PLATE, HINGE CONCEALED TAKEN FROM BXH 800 (SN:A21230)',
          1.0
        ),
      ]);
    });

    test('S6 Return / Pull Out slip: a note across columns is not an item',
        () {
      final r = ItemTableParser.parse([
        _l('Quantity', 115, 408, 70),
        _l('UOM', 260, 408, 42),
        _l('Part No.', 408, 408, 62),
        _l('Description', 653, 412, 85),
        _l('Lot/Serial No.', 930, 414, 108),
        _l('Property Tag', 1235, 417, 95),
        _l('1', 150, 453, 8),
        _l('UNIT', 262, 453, 40),
        _l('11712187', 348, 453, 80),
        _l('ACUSON MAPLE, BASE CONFIGURATION', 536, 455, 305),
        _l('700080', 858, 457, 50),
        _l('FA24-0386', 1117, 460, 70),
        _l('1', 150, 550, 8),
        _l('PIECE', 262, 550, 45),
        _l('Sony printer', 536, 550, 82),
        _l('on board', 858, 552, 62),
        _l('1', 150, 647, 8),
        _l('PIECE', 262, 647, 45),
        _l('ECG Cable', 536, 647, 70),
        _l('5 PM PULL OUT AS PER GCS', 860, 680, 305),
        _l('Released by:', 88, 958, 85),
      ]);

      expect(r.items.map((i) => i.description),
          ['ACUSON MAPLE, BASE CONFIGURATION', 'Sony printer', 'ECG Cable']);
      expect(r.items.first.ptn, 'FA24-0386');
      expect(r.items.first.serialNo, '700080');
    });

    test('S7 Goods Issue', () {
      final r = ItemTableParser.parse([
        _l('Item Code', 105, 555, 97),
        _l('Description', 582, 557, 103),
        _l('Warehouse', 1045, 557, 105),
        _l('Qty', 1260, 558, 35),
        _l('Unit', 1405, 558, 38),
        _l('B96742', 118, 588, 68),
        _l('FRU,LALS ASSEMBLY W/CABLE (OPN:A61139)', 283, 590, 405),
        _l('NCR007', 1062, 592, 70),
        _l('1.00', 1257, 592, 40),
        _l('PIECE', 1397, 592, 52),
        _l('Comments:', 64, 1490, 107),
      ]);

      final item = r.items.single;
      expect(item.itemCode, 'B96742');
      expect(item.description, 'FRU,LALS ASSEMBLY W/CABLE (OPN:A61139)');
      expect(item.unit, 'PIECE');
    });

    test('Sales Invoice layout (plan §4.5): GL Account and Amount ignored', () {
      final r = ItemTableParser.parse([
        _l('Description', 60, 400, 100),
        _l('GL Account', 500, 400, 100),
        _l('Qty', 700, 400, 40),
        _l('Unit', 780, 400, 40),
        _l('Account Name', 900, 400, 140),
        _l('Amount', 1150, 400, 80),
        _l('SITE SURVEY, INSTALLATION & TESTING OF BECKMAN', 60, 430, 420),
        _l('4010-00', 500, 430, 70),
        _l('1', 712, 430, 10),
        _l('PC', 785, 430, 25),
        _l('Service Revenue', 900, 430, 140),
        _l('150,000.00', 1150, 430, 100),
        _l('COULTER CHEMISTRY ANALYZER DXC700AU', 60, 455, 330),
        _l('Total:', 900, 700, 60),
      ]);

      final item = r.items.single;
      expect(item.description,
          'SITE SURVEY, INSTALLATION & TESTING OF BECKMAN COULTER CHEMISTRY ANALYZER DXC700AU');
      expect(item.qty, 1);
      expect(item.unit, 'PC');
      expect(item.itemCode, '');
    });
  });

  group('device run 2026-10-15 (S3 Inventory Transfer)', () {
    // What the phone read: one item and the two Comments lines, because the
    // signature turned "Comments:" into "Commenta:".
    final body = [
      _l('RXH60035', 103, 700, 93),
      _l('Commenta:', 72, 1480, 105),
      _l('ACD thru iper1750 AR26-239 Galincato Clinic and Hospital DB00 '
          'AYi00077 Contact name: Deo Glenn Reyes Contact number: +63906051395',
          72, 1508, 1180),
      _l('WBHO79-4441-5584 Based On Inventory Transfer RequesB1G003436.', 72,
          1532, 560),
      _l('Prepared By:', 58, 1570, 120),
    ];

    test('all column titles read: the row is split into its columns', () {
      final r = ItemTableParser.parse([
        _l('ltem Code', 103, 668, 97),
        _l('Description', 487, 668, 103),
        _l('From Warehouse', 835, 665, 158),
        _l('Warehouse', 1030, 665, 105),
        _l('Oty', 1232, 665, 35),
        _l('Unit', 1348, 664, 38),
        _l('RBC Counting Chamber MAINSPA SVC103 1.00 PIECE', 249, 700, 1145),
        ...body,
      ]);
      expect(r.items, hasLength(1), reason: 'Comments are not items');
      final item = r.items.single;
      expect(item.itemCode, 'RXH60035');
      expect(item.description, 'RBC Counting Chamber');
      expect(item.qty, 1);
      expect(item.unit, 'PIECE');
    });

    test('right-hand titles missed: quantity and unit taken off the end', () {
      final r = ItemTableParser.parse([
        _l('Item Code', 103, 668, 97),
        _l('Description', 487, 668, 103),
        _l('RBC Counting Chamber MAINSPA SVC103 100 PIECE', 249, 700, 1145),
        ...body,
      ]);
      expect(r.items, hasLength(1));
      final item = r.items.single;
      expect(item.description, 'RBC Counting Chamber MAINSPA SVC103');
      expect(item.unit, 'PIECE');
      expect(r.isUnsure(0), isTrue, reason: '100 may be 1.00 without its point');
    });

    test('a shaded header line with stray letters still counts', () {
      final r = ItemTableParser.parse([
        _l('Item Code  ::  Description  ::  From Warehouse Warehouse Oty Unit xx',
            103, 668, 1290),
        _l('RXH60035', 103, 700, 93),
        _l('RBC Counting Chamber', 249, 700, 210),
        _l('1.00', 1232, 700, 40),
        _l('PIECE', 1342, 700, 55),
      ]);
      // Title positions inside one merged line are estimates, so only the
      // header and the description are pinned here.
      expect(r.headerFound, isTrue);
      expect(r.items.single.description, 'RBC Counting Chamber');
      expect(r.items.single.itemCode, 'RXH60035');
    });
  });

  group('rules', () {
    final header = [
      _l('QTY', 0, 0, 40),
      _l('UNIT', 100, 0, 40),
      _l('DESCRIPTION', 200, 0, 120),
    ];

    test('no column titles → no table', () {
      final r = ItemTableParser.parse([
        _l('Customer: Clinica Manila', 0, 0, 300),
        _l('Unit 5, Megamall', 0, 30, 200),
      ]);
      expect(r.headerFound, isFalse);
      expect(r.items, isEmpty);
    });

    test('a body row holding the word UNIT is not a header', () {
      final r = ItemTableParser.parse([
        ...header,
        _l('2', 10, 40, 10),
        _l('UNIT', 100, 40, 40),
        _l('Description of a unit', 200, 40, 200),
      ]);
      expect(r.items, hasLength(1));
      expect(r.items.single.qty, 2);
    });

    test('missing quantity defaults to 1 and is flagged', () {
      final r = ItemTableParser.parse([
        ...header,
        _l('PIECE', 100, 40, 40),
        _l('Sony printer', 200, 40, 120),
      ]);
      expect(r.items.single.qty, 1);
      expect(r.isUnsure(0), isTrue);
    });

    test('one OCR line across several columns is split and flagged', () {
      final r = ItemTableParser.parse([
        ...header,
        _l('2 UNIT Sony printer', 0, 40, 380),
      ]);
      final item = r.items.single;
      expect(item.qty, 2);
      expect(item.unit, 'UNIT');
      expect(item.description, 'Sony printer');
      expect(r.isUnsure(0), isTrue);
    });

    test('a description-only first row is kept and flagged', () {
      final r = ItemTableParser.parse([
        ...header,
        _l('WIRELESS KEYBOARD', 200, 40, 200),
      ]);
      expect(r.items.single.description, 'WIRELESS KEYBOARD');
      expect(r.isUnsure(0), isTrue);
    });

    test('quantities: decimals, commas, O for 0', () {
      final r = ItemTableParser.parse([
        ...header,
        _l('2.50', 0, 40, 40),
        _l('Gloves', 200, 40, 100),
        _l('1,000', 0, 80, 40),
        _l('Swabs', 200, 80, 100),
        _l('1O', 0, 120, 30),
        _l('Tubes', 200, 120, 100),
      ]);
      expect(r.items.map((i) => i.qty), [2.5, 1000, 10]);
    });

    test('empty input', () {
      expect(ItemTableParser.parse([]).headerFound, isFalse);
    });
  });
}
