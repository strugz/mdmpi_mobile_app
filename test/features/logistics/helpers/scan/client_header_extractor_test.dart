import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/client_header_extractor.dart';

/// Hand-made OCR lines laid out like the sample photos catalogued in plan §1
/// (positions taken from the photos, scaled). Real OCR fixtures come later
/// from the device dump and stay git-ignored.

OcrLine _l(String text, double left, double top, double width,
        [double height = 20]) =>
    OcrLine(text, Rect.fromLTWH(left, top, width, height));

/// Our own header, as printed on the system-generated forms.
final _systemHeader = [
  _l('MARSMAN DRYSDALE', 220, 100, 335, 25),
  _l('MEDICAL PRODUCTS, INC', 220, 128, 380, 25),
  _l('2231 G/F Molave Bldg Chino Roces Ave. Bangkal, City of Makati,', 915,
      138, 520),
  _l('VAT Reg TIN: 204-595-997-00000', 915, 188, 265),
  _l('Tel #: (632) 7751-9999', 915, 213, 180),
];

void main() {
  group('samples', () {
    test('SI gallery photo: a margin fragment beside the code is not a label',
        () {
      // SI 700014771, 2026-10-21: "NO" and "TI", cut off from a sheet
      // underneath, sit in the left margin. "NO" read as the label "No."
      // and the customer name was lost.
      final h = ClientHeaderExtractor.extract([
        ..._systemHeader,
        _l('SALES INVOICE', 1469, 1149, 368, 42),
        _l('Customer', 217, 1179, 124, 33),
        _l('Philippine Red Cross National Blood Center-NBC Tower', 451, 1222,
            626, 46),
        _l('NCR-326', 218, 1224, 104, 24),
        _l('NO', 119, 1225, 30, 22),
        _l('TIN 330-000-804', 227, 1256, 194, 30),
        _l('TI', 134, 1259, 12, 21),
        _l('Tel #: 000-000', 216, 1287, 163, 34),
        _l('Address:', 219, 1453, 103, 24),
        _l('37 Edsa Corner Boni Avenue Mandaluyong PHILIPPINES', 219, 1490,
            655, 30),
        _l('Details', 240, 1566, 84, 21),
        _l('Item Code', 263, 1620, 123, 21),
        _l('Description', 756, 1620, 129, 21),
      ]);

      expect(h.label, 'Customer');
      expect(h.prefix, 'NCR-326');
      expect(h.name, 'Philippine Red Cross National Blood Center-NBC Tower');
      expect(h.address, '37 Edsa Corner Boni Avenue Mandaluyong PHILIPPINES');
    });

    test('S1 Inventory Transfer Request: Business Partner, name below', () {
      final h = ClientHeaderExtractor.extract([
        ..._systemHeader,
        _l('INVENTORY TRANSFER REQUEST', 922, 242, 580, 35),
        _l('Business Partner:', 55, 252, 163),
        _l('DLR-190', 55, 284, 80),
        _l('Galinato Clinic and Hospital', 207, 284, 257),
        _l('ORIGINAL', 1145, 285, 130, 22),
        _l('TIN: 194-402-270-000', 55, 313, 197),
        _l('ITR No.:', 915, 315, 75),
        _l('Posting Date:', 1188, 315, 122),
        _l('Tel #: 0948-249-7012', 55, 340, 190),
        _l('810003448', 985, 375, 103),
        _l('Fax:', 55, 366, 35),
        _l('Email:', 55, 393, 55),
        _l('Contact Person: Mr. Tito V. Reyes', 55, 419, 305),
        _l('Business Style:', 55, 446, 135),
        _l('Address:', 55, 479, 82),
        _l('Villamor, Esperanza Sultran Kudarat', 55, 511, 330),
        _l('PHILIPPINES', 407, 511, 112),
        _l('Details', 68, 540, 68),
        _l('Item Code', 105, 585, 97),
        _l('Description', 349, 585, 107),
        _l('RXH60169', 105, 617, 97),
        _l('Optic Bench / WBC Chamber', 252, 617, 262),
        _l('Comments:', 68, 1402, 96),
        _l('ACD thru viber 0856 Galinato Clinic and Hospital Contact name: '
            'Deo Glenn Reyes', 60, 1445, 976),
      ]);

      expect(h.label, 'Business Partner');
      expect(h.prefix, 'DLR-190');
      expect(h.name, 'Galinato Clinic and Hospital');
      expect(h.address, 'Villamor, Esperanza Sultran Kudarat PHILIPPINES');
    });

    test('S2 Stock Issue Slip: DELIVERED TO and ADDRESS on the same row', () {
      final h = ClientHeaderExtractor.extract([
        _l('MARSMAN DRYSDALE MEDICAL PRODUCTS, INC.', 200, 120, 915, 45),
        _l('G/F Molave Bldg., 2231 Chino Roces Avenue, Makati City', 203, 175,
            683, 25),
        _l('STOCK ISSUE SLIP', 700, 305, 545, 50),
        _l('No. 00611', 1605, 318, 305, 50),
        _l('DELIVERED TO:', 60, 402, 203, 24),
        _l('QUEZON CITY GENERAL HOSPITAL', 320, 412, 548, 28),
        _l('DATE:', 1217, 404, 78, 24),
        _l('10/14/2026', 1493, 412, 147, 26),
        _l('ADDRESS:', 65, 465, 135, 24),
        _l('Seminary Road, Project 8 , Quezon City', 320, 475, 503, 28),
        _l('REF DOC:', 1217, 466, 130, 24),
        _l('10/10/2026', 1493, 483, 147, 26),
        _l('QTY', 95, 545, 50, 24),
        _l('BT120 Auto Blood Culture Analyzer', 550, 617, 430, 24),
      ]);

      expect(h.label, 'DELIVERED TO');
      expect(h.prefix, isNull);
      expect(h.name, 'QUEZON CITY GENERAL HOSPITAL');
      expect(h.address, 'Seminary Road, Project 8 , Quezon City');
    });

    test('S3 Inventory Transfer: faint print, same block as S1', () {
      final h = ClientHeaderExtractor.extract([
        ..._systemHeader,
        _l('INVENTORY TRANSFER', 978, 290, 462, 40),
        _l('Business Partner:', 48, 318, 160),
        _l('DLR-190', 48, 348, 76),
        _l('Galinato Clinic and Hospital', 170, 347, 250),
        _l('TIN: 194-402-270-000', 48, 378, 198),
        _l('Address:', 48, 545, 82),
        _l('Villamor, Esperanza Sultran Kudarat', 48, 576, 330),
        _l('PHILIPPINES', 398, 576, 110),
        _l('Details', 66, 621, 66),
      ]);

      expect(h.prefix, 'DLR-190');
      expect(h.name, 'Galinato Clinic and Hospital');
      expect(h.address, 'Villamor, Esperanza Sultran Kudarat PHILIPPINES');
    });

    test('S3 label misread: the header rows are offered, the coded row first',
        () {
      final h = ClientHeaderExtractor.extract([
        ..._systemHeader,
        _l('INVENTORY TRANSFER', 978, 290, 462, 40),
        _l('Buslness Partnor', 48, 318, 160),
        _l('DLR-190', 48, 348, 76),
        _l('Galinato Clinic and Hospital', 170, 347, 250),
        _l('TIN: 194-402-270-000', 48, 378, 198),
        _l('Contact Person: Mr. Tito V. Reyes', 48, 487, 305),
        _l('Address:', 48, 545, 82),
        _l('Villamor, Esperanza Sultran Kudarat', 48, 576, 330),
        _l('Item Code', 100, 668, 97),
        _l('Description', 487, 668, 105),
        _l('RBC Counting Chamber', 248, 700, 212),
      ]);

      expect(h.hasLabel, isFalse);
      expect(h.hasName, isFalse);
      expect(h.nameCandidates.first, 'Galinato Clinic and Hospital');
      expect(h.nameCandidates, isNot(contains(contains('TIN'))));
      expect(h.nameCandidates, isNot(contains(contains('Tito'))));
      expect(h.nameCandidates, isNot(contains('RBC Counting Chamber')),
          reason: 'the item table is not the header');
    });

    test('S4 Acknowledgement Receipt: CUSTOMER NAME, centred below', () {
      final h = ClientHeaderExtractor.extract([
        _l('Marsman Drysdale Medical Products, Inc.', 378, 140, 700, 40),
        _l('Acknowledgement Receipt', 420, 240, 625, 50),
        _l('NO.', 1140, 280, 75, 40),
        _l('AR26-240', 1410, 275, 205, 45),
        _l('CUSTOMER NAME', 133, 318, 163),
        _l('DATE', 1130, 345, 47, 18),
        _l('CHONG HUA HOSPITAL- MANDAUE', 372, 358, 500, 30),
        _l('13-Oct-26', 1395, 378, 130, 28),
        _l('Form Distrubution (4 copies)', 162, 400, 255, 22),
        _l('WAREHOUSE', 250, 443, 118),
        _l('REMARKS', 157, 1080, 86),
        _l('PURCHASED PROBE', 572, 1085, 232, 26),
      ]);

      expect(h.label, 'CUSTOMER NAME');
      expect(h.name, 'CHONG HUA HOSPITAL- MANDAUE');
      expect(h.address, isNull);
    });

    test('S5 Materials Issuance Slip: no customer block', () {
      final h = ClientHeaderExtractor.extract([
        _l('MARSMAN DRYDALE MEDICAL PRODUCTS, INC.', 372, 70, 1250, 45),
        _l('MATERIALS ISSUANCE SLIP', 698, 135, 595, 40),
        _l('MIS No.', 1478, 198, 108),
        _l('SERIAL / PART NO.', 118, 268, 302, 30),
        _l('HINGE, DOOR', 690, 318, 210),
        _l('REMARKS / PURPOSE', 57, 862, 355, 30),
        _l('FOR TESTING AND EVALUATION @ SLMCGC', 575, 870, 1290, 30),
      ]);

      expect(h.hasLabel, isFalse);
      expect(h.name, isNull);
    });

    test('S6 Return / Pull Out slip: "Returned by" is not a delivery label',
        () {
      final h = ClientHeaderExtractor.extract([
        _l('Marsman Drysdale Medical Products, Inc.', 340, 118, 390),
        _l('RETURN/PULL OUT SLIP', 315, 175, 443, 40),
        _l('Returned by:', 85, 225, 95, 18),
        _l('Contact Person', 638, 256, 112),
        _l('Address', 1125, 258, 58),
        _l('CLINICA MANILA', 250, 278, 112),
        _l('MAAM BABES', 645, 288, 95),
        _l('2ND FLOOR , SM MEGAMALL BLDG. A', 1030, 290, 246),
      ]);

      expect(h.hasLabel, isFalse);
      expect(h.name, isNull);
      expect(h.address, isNull);
    });

    test('S7 Goods Issue: the client is only in Comments, which are ignored',
        () {
      final h = ClientHeaderExtractor.extract([
        _l('MARSMAN DRYSDALE', 215, 165, 340, 25),
        _l('GOODS ISSUE', 1072, 305, 270, 40),
        _l('GI No.:', 913, 375, 65),
        _l('760006490', 983, 405, 98),
        _l('Reference No.:', 913, 452, 135),
        _l('IT750005302', 913, 483, 115),
        _l('Comments:', 64, 1490, 107),
        _l('WASTE/SAFEKEEP FA Parts RLN ITR#810003182/750005229 '
            'PHILIPPINE-CHINESE CHARITABLE ASSOCIATION.', 64, 1530, 1245),
        _l('Client: PHILIPPINE-CHINESE CHARITABLE ASSOCIATION', 64, 1560,
            600),
      ]);

      expect(h.hasLabel, isFalse);
      expect(h.name, isNull);
    });

    test('Sales Invoice (plan §1): Customer with NCR prefix on one OCR line',
        () {
      final h = ClientHeaderExtractor.extract([
        _l('MARSMAN DRYSDALE MEDICAL PRODUCTS, INC', 200, 60, 600, 30),
        _l('Customer: NCR-414 U.S. Department of Veterans Affairs', 40, 200,
            560),
        _l('SI No.: 700014535', 900, 200, 200),
        _l('TIN:', 40, 228, 40),
        _l('Address: 1501 Roxas Boulevard, Pasay City PHILIPPINES', 40, 256,
            520),
        _l('Details', 40, 300, 70),
      ]);

      expect(h.label, 'Customer');
      expect(h.prefix, 'NCR-414');
      expect(h.name, 'U.S. Department of Veterans Affairs');
      expect(h.address, '1501 Roxas Boulevard, Pasay City PHILIPPINES');
    });
  });

  group('rules', () {
    test('Customer Name wins over Customer', () {
      final h = ClientHeaderExtractor.extract([
        _l('Customer Name: St. Luke\'s Medical Center', 40, 100, 400),
      ]);
      expect(h.label, 'Customer Name');
      expect(h.name, "St. Luke's Medical Center");
    });

    test('our own name after a customer label is never the customer', () {
      final h = ClientHeaderExtractor.extract([
        _l('Customer:', 40, 100, 90),
        _l('Marsman Drysdale Medical Products, Inc.', 160, 100, 380),
      ]);
      expect(h.hasLabel, isTrue);
      expect(h.name, isNull);
    });

    test('a label with no value before the next label gives no name', () {
      final h = ClientHeaderExtractor.extract([
        _l('Business Partner:', 40, 100, 160),
        _l('TIN: 194-402-270-000', 40, 130, 200),
        _l('Address:', 40, 160, 80),
        _l('Villamor, Esperanza', 40, 190, 200),
      ]);
      expect(h.hasLabel, isTrue);
      expect(h.name, isNull);
      expect(h.address, 'Villamor, Esperanza');
    });

    test('an address may wrap onto a second row, then stops at a label', () {
      final h = ClientHeaderExtractor.extract([
        _l('Customer:', 40, 100, 90),
        _l('Clinica Manila', 160, 100, 150),
        _l('Address:', 40, 130, 80),
        _l('2nd Floor, SM Megamall Bldg. A', 40, 160, 300),
        _l('Mandaluyong City', 40, 185, 170),
        _l('Contact Person: Maam Babes', 40, 210, 260),
      ]);
      expect(h.name, 'Clinica Manila');
      expect(h.address, '2nd Floor, SM Megamall Bldg. A Mandaluyong City');
    });

    test('a client word inside a name is not a label', () {
      final h = ClientHeaderExtractor.extract([
        _l('Clinica Manila', 40, 100, 150),
        _l('Galinato Clinic and Hospital', 40, 130, 250),
      ]);
      expect(h.hasLabel, isFalse);
    });

    test('a slightly tilted row still reads as one row', () {
      final h = ClientHeaderExtractor.extract([
        _l('DELIVERED TO:', 60, 400, 200, 24),
        _l('QUEZON CITY', 320, 410, 200, 26),
        _l('GENERAL HOSPITAL', 540, 414, 250, 26),
      ]);
      expect(h.name, 'QUEZON CITY GENERAL HOSPITAL');
    });

    test('no lines, or only blank ones', () {
      expect(ClientHeaderExtractor.extract([]).hasLabel, isFalse);
      expect(ClientHeaderExtractor.extract([_l('  ', 0, 0, 10)]).hasLabel,
          isFalse);
    });

    test('rawLines lists what the header was read from', () {
      final h = ClientHeaderExtractor.extract([
        _l('Customer:', 40, 100, 90),
        _l('Clinica Manila', 160, 100, 150),
        _l('Unrelated footer', 40, 900, 150),
      ]);
      expect(h.rawLines.map((l) => l.text), ['Customer:', 'Clinica Manila']);
    });
  });
}
