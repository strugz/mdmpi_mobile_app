import 'dart:ui' show Offset, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_extractor.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/client_header_extractor.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/delivery_document_type.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/item_table_parser.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/one_scan_reference_patterns.dart';

/// S8 Sales Invoice, S9 Delivery Receipt, S10 Reagents Issue Slip (plan §1),
/// and the document-to-request rules. Hand-made lines from the photos.

OcrLine _l(String text, double left, double top, double width,
        [double height = 20]) =>
    OcrLine(text, Rect.fromLTWH(left, top, width, height));

List<String> _refs(List<OcrLine> lines) {
  final text = lines.map((l) => l.text).join('\n');
  return OneScanReferencePatterns.extract(
      text, DocumentReferenceExtractor().extractPatterns(text),
      excludeTexts: ItemTableParser.parse(lines).tableTexts);
}

final _s8SalesInvoice = [
  _l('MARSMAN DRYSDALE', 210, 95, 335, 25),
  _l('2231 G/F Molave Bldg Chino Roces Ave. Bangkal, City of Makati,', 908,
      138, 520),
  _l('Customer:', 47, 242, 95),
  _l('SALES INVOICE', 1053, 244, 292, 40),
  _l('RAD-028', 47, 274, 83),
  _l('University of Cebu Medical Center, Inc.', 197, 276, 372),
  _l('ORIGINAL', 1133, 286, 128),
  _l('TIN: 434-441-310-000', 47, 302, 200),
  _l('SI No.:', 908, 312, 60),
  _l('Posting Date:', 1176, 313, 122),
  _l('Due Date:', 1340, 313, 92),
  _l('700014676', 908, 342, 103),
  _l('10/09/2026', 1190, 344, 108),
  _l('11/23/2026', 1352, 344, 110),
  _l('PO No.:', 908, 387, 70),
  _l('PO Date:', 1176, 389, 80),
  _l('40405A', 908, 418, 70),
  _l('10/09/2026', 1196, 419, 108),
  _l('Address:', 47, 470, 82),
  _l('Payment Terms:', 908, 463, 150),
  _l('Ouano Avenue City South Special Economic', 47, 503, 405),
  _l('PHILIPPINES', 468, 505, 115),
  _l('Delivery Receipt:', 908, 509, 155),
  _l('DR 690014676', 1100, 509, 135),
  _l('Details', 63, 563, 68),
  _l('Description', 230, 612, 110),
  _l('GL Account', 578, 613, 104),
  _l('Qty', 785, 614, 35),
  _l('Unit', 918, 614, 40),
  _l('Account Name', 1077, 614, 138),
  _l('Amoun', 1397, 613, 68),
  _l('FIRST QUARTERLY MAINTENANCE VISIT OF', 47, 641, 400),
  _l('41020210', 585, 644, 90),
  _l('1', 797, 645, 8),
  _l('PC', 922, 645, 25),
  _l('Service Income - Others -', 1010, 644, 225),
  _l('25,000.00', 1372, 643, 92),
  _l('SC2000 SN:402053', 47, 667, 175),
  _l('VATable', 1010, 670, 75),
  _l('FIRST QUARTERLY MAINTENANCE VISIT OF', 47, 694, 400),
  _l('41020210', 585, 697, 90),
  _l('1', 797, 698, 8),
  _l('PC', 922, 698, 25),
  _l('Service Income - Others -', 1010, 697, 225),
  _l('23,750.00', 1372, 696, 92),
  _l('S1000 SN:210828', 47, 721, 165),
  _l('VATable', 1010, 723, 75),
  _l('FIRST QUARTERLY MAINTENANCE VISIT OF', 47, 747, 400),
  _l('41020210', 585, 750, 90),
  _l('1', 797, 751, 8),
  _l('PC', 922, 751, 25),
  _l('Service Income - Others -', 1010, 750, 225),
  _l('25,000.00', 1372, 749, 92),
  _l('S2000 SN:210541', 47, 774, 165),
  _l('VATable', 1010, 776, 75),
  _l('Comments:', 65, 1075, 95),
  _l('Total Sales (VAT included):', 1008, 1074, 245),
  _l('For invoice of visit with SR#FLD26274143 Based On Deliveries 690014676.',
      65, 1131, 850),
];

final _s9DeliveryReceipt = [
  _l('MARSMAN DRYSDALE', 210, 95, 335, 25),
  _l('Customer:', 47, 247, 95),
  _l('DELIVERY RECEIPT', 1017, 237, 355, 40),
  _l('RAD-028', 47, 277, 83),
  _l('University of Cebu Medical Center, Inc.', 197, 279, 368),
  _l('ORIGINAL', 1130, 276, 128),
  _l('DR No.:', 903, 300, 70),
  _l('Posting Date:', 1172, 303, 122),
  _l('Due Date:', 1338, 302, 92),
  _l('690014676', 903, 330, 103),
  _l('PO No.:', 903, 381, 70),
  _l('PO Date:', 1172, 381, 80),
  _l('40405A', 903, 405, 70),
  _l('Address:', 47, 468, 82),
  _l('Sales Order No.:', 903, 487, 135),
  _l('SO 670009557', 1097, 485, 117),
  _l('Ouano Avenue City South Special Economic', 47, 503, 405),
  _l('PHILIPPINES', 468, 505, 112),
  _l('Delivery Type:', 47, 565, 120),
  _l('Details', 63, 594, 68),
  _l('Description', 316, 640, 108),
  _l('GL Account', 741, 636, 104),
  _l('Account Name', 1024, 634, 138),
  _l('FIRST QUARTERLY MAINTENANCE VISIT OF SC2000 SN:402053', 49, 670, 570),
  _l('41020210', 747, 668, 90),
  _l('Service Income - Others - VATable', 903, 666, 310),
  _l('FIRST QUARTERLY MAINTENANCE VISIT OF S1000 SN:210828', 49, 700, 560),
  _l('41020210', 747, 697, 90),
  _l('Service Income - Others - VATable', 903, 694, 310),
  _l('FIRST QUARTERLY MAINTENANCE VISIT OF S2000 SN:210541', 49, 730, 560),
  _l('41020210', 747, 727, 90),
  _l('Service Income - Others - VATable', 903, 724, 310),
  _l('Comments:', 75, 1330, 105),
];

final _s10ReagentsIssueSlip = [
  _l('Marsman Drysdale Medical Products Inc.', 337, 208, 577, 30),
  _l('REAGENTS ISSUE SLIP', 381, 278, 488, 45),
  _l('ISSUE SLIP NO.:', 1110, 385, 175),
  _l('ISSUED TO:', 65, 410, 108),
  _l('RITE-TECH MEDICAL FOR QMC', 302, 425, 555, 40),
  _l('IS26-344', 1081, 415, 205, 45),
  _l('PO NO. RT-2026-0526-062-QMC', 1018, 560, 415),
  _l('REQUESTED BY:', 63, 596, 140),
  _l('DBG', 300, 610, 75, 30),
  _l('ITEM NO.', 65, 748, 90),
  _l('PART NO.', 202, 748, 92),
  _l('DESCRIPTION', 458, 748, 128),
  _l('QUANTITY', 727, 748, 100),
  _l('UOM', 885, 748, 45),
  _l('SERIAL / LOT NO.', 993, 748, 165),
  _l('EXPIRY', 1250, 748, 70),
  _l('1', 107, 777, 8, 25),
  _l('105724', 189, 772, 80, 25),
  _l('ELUENT 90A', 330, 775, 140, 25),
  _l('1', 742, 775, 8, 25),
  _l('BOX', 865, 772, 50, 25),
  _l('6A3101', 970, 775, 100, 25),
  _l('1/31/2027', 1185, 775, 110, 25),
  _l('2', 107, 805, 8, 25),
  _l('105724', 189, 800, 80, 25),
  _l('ELUENT 90CV', 333, 805, 165, 25),
  _l('1', 745, 805, 8, 25),
  _l('BOX', 865, 800, 50, 25),
  _l('6A3401', 970, 805, 100, 25),
  _l('3', 103, 832, 8, 25),
  _l('C22593', 186, 828, 80, 25),
  _l('PCT Reagent', 330, 830, 140, 25),
  _l('1', 750, 832, 8, 25),
  _l('BOX', 865, 830, 50, 25),
  _l('6334463', 970, 832, 110, 25),
  _l('PREPARED BY:', 225, 1495, 140),
];

void main() {
  group('S8 Sales Invoice', () {
    test('client, references, service rows with wrapped text', () {
      final h = ClientHeaderExtractor.extract(_s8SalesInvoice);
      expect(h.prefix, 'RAD-028');
      expect(h.name, 'University of Cebu Medical Center, Inc.');
      expect(h.address, 'Ouano Avenue City South Special Economic PHILIPPINES');

      expect(_refs(_s8SalesInvoice),
          containsAll(['SINo.:700014676', 'PONo.:40405A', 'DRNo.:690014676']));
      expect(_refs(_s8SalesInvoice).where((r) => r.startsWith('PONo.:')),
          ['PONo.:40405A'], reason: 'not "PO" from the PO Date label');

      final items = ItemTableParser.parse(_s8SalesInvoice);
      expect(items.items.map((i) => i.description), [
        'FIRST QUARTERLY MAINTENANCE VISIT OF SC2000 SN:402053',
        'FIRST QUARTERLY MAINTENANCE VISIT OF S1000 SN:210828',
        'FIRST QUARTERLY MAINTENANCE VISIT OF S2000 SN:210541',
      ]);
      expect(items.items.every((i) => i.qty == 1 && i.unit == 'PC'), isTrue);
      expect(items.unsure, isEmpty);

      expect(DeliveryDocumentType.detect(_s8SalesInvoice),
          DeliveryDocumentType.salesInvoice,
          reason: '"Delivery Receipt:" on the SI is a label, not the title');
    });
  });

  group('S11 Sales Invoice with batch sub-rows (PRC, 2026-10-15)', () {
    // The photo is tilted: lines rise about 3.5 px per 100 px to the right.
    // ML Kit's corner points carry that slope; the readers level it out.
    OcrLine t(String text, double left, double level, double width,
        [double height = 14]) {
      // [level] is where the row would sit on a straight page.
      const slope = -0.035;
      final top = level + slope * left;
      return OcrLine(text, Rect.fromLTWH(left, top, width, height),
          cornerPoints: [
            Offset(left, top),
            Offset(left + width, top + slope * width),
            Offset(left + width, top + height + slope * width),
            Offset(left, top + height),
          ]);
    }

    final lines = [
      t('SALES INVOICE', 752, 205, 190, 28),
      t('Customer:', 112, 212, 62),
      t('NCR-326', 112, 230, 52),
      t('Philippine Red Cross National Blood Center-NBC Tower', 230, 230, 323),
      t('SI No.:', 656, 258, 38),
      t('700014771', 656, 276, 64),
      t('PO No.:', 656, 306, 48),
      t('PO-018561', 656, 324, 64),
      t('Delivery Receipt:', 659, 374, 100),
      t('DR 690014771', 783, 374, 88),
      t('Details', 122, 408, 44),
      t('Item Code', 133, 437, 66),
      t('Description', 386, 437, 70),
      t('Qty', 639, 437, 24),
      t('Unit', 734, 437, 28),
      t('Price', 880, 437, 34),
      t('Amoun', 984, 437, 46),
      t('B36845', 143, 457, 47),
      t('DxH 500 Diluent, 10L', 237, 457, 124),
      t('6.00', 637, 455, 28),
      t('BOX', 734, 457, 26),
      t('16,104.00', 849, 454, 62),
      t('96,624.00', 969, 454, 63),
      t('Batch/Serial #', 315, 476, 85, 13),
      t('Quantity', 462, 476, 47, 13),
      t('Expiry Date', 537, 476, 61, 13),
      t('0179170', 250, 494, 47, 13),
      t('6.00', 474, 493, 23, 13),
      t('07/18/2027', 537, 493, 61, 13),
      t('B36846', 143, 510, 47),
      t('DXH 500 Lyse, 500mL', 237, 510, 131),
      t('5.00', 640, 508, 28),
      t('BOTTLE', 727, 510, 46),
      t('12,536.00', 851, 507, 62),
      t('62,680.00', 971, 507, 63),
      t('Batch/Serial #', 316, 529, 85, 13),
      t('Quantity', 463, 529, 47, 13),
      t('Expiry Date', 538, 529, 61, 13),
      t('8300114', 252, 547, 47, 13),
      t('5.00', 475, 546, 23, 13),
      t('07/05/2027', 538, 546, 61, 13),
      t('B36868', 143, 563, 47),
      t('DxH 500 Cleaner, 500mL', 237, 563, 145),
      t('6.00', 640, 561, 28),
      t('BOTTLE', 728, 563, 46),
      t('9,932.00', 860, 560, 55),
      t('59,592.00', 975, 560, 63),
      t('Batch/Serial #', 316, 582, 85, 13),
      t('Quantity', 464, 582, 47, 13),
      t('Expiry Date', 539, 582, 61, 13),
      t('7704315', 253, 600, 47, 13),
      t('6.00', 476, 599, 23, 13),
      t('08/06/2027', 539, 599, 61, 13),
      t('Total Sales (VAT Included):', 724, 712, 165),
      t('Comments:', 122, 712, 66),
    ];

    test('batches attach to their item, as Add Item does', () {
      final r = ItemTableParser.parse(lines);
      expect(r.items.map((i) => (i.itemCode, i.description, i.qty, i.unit)), [
        ('B36845', 'DxH 500 Diluent, 10L', 6.0, 'BOX'),
        ('B36846', 'DXH 500 Lyse, 500mL', 5.0, 'BOTTLE'),
        ('B36868', 'DxH 500 Cleaner, 500mL', 6.0, 'BOTTLE'),
      ]);
      final batches = [
        for (final i in r.items)
          for (final b in i.batches) (b.batchSerial, b.batchQuantity, b.expiryDate)
      ];
      expect(batches, [
        ('0179170', 6.0, '07/18/2027'),
        ('8300114', 5.0, '07/05/2027'),
        ('7704315', 6.0, '08/06/2027'),
      ]);
      expect(r.items.every((i) => i.serialNo.isEmpty), isTrue,
          reason: 'a batch serial is never the item serial');
      expect(r.unsure, isEmpty);
    });

    test('client, references and type', () {
      expect(ClientHeaderExtractor.extract(lines).name,
          'Philippine Red Cross National Blood Center-NBC Tower');
      expect(_refs(lines),
          containsAll(['SINo.:700014771', 'PONo.:PO-018561', 'DRNo.:690014771']));
      expect(DeliveryDocumentType.detect(lines), DeliveryDocumentType.salesInvoice);
    });
  });

  group('S11 captured in the app: rows run together (device run 2026-10-15)',
      () {
    // A hand-held capture: each batch title line sits so close to its item
    // that OCR rows merge, and each batch line runs into the next item.
    final lines = [
      _l('Item Code', 133, 437, 66, 14),
      _l('Description', 386, 437, 70, 14),
      _l('Qty', 639, 437, 24, 14),
      _l('Unit', 734, 437, 28, 14),
      _l('Price', 880, 437, 34, 14),
      _l('Amoun', 984, 437, 46, 14),
      // item 1 + its batch title in one OCR row
      _l('B36845', 143, 460, 47, 14),
      _l('DxH 500 Diluent, 10L', 237, 460, 124, 14),
      _l('6.00', 637, 460, 28, 14),
      _l('BOX', 734, 460, 26, 14),
      _l('96,624.00', 969, 460, 63, 14),
      _l('Batch/Serial #', 315, 467, 85, 13),
      _l('Quantity', 462, 467, 47, 13),
      _l('Expiry Date', 537, 467, 61, 13),
      // batch 1 + item 2 in one OCR row
      _l('0179170 6.00 07/18/2027', 250, 495, 348, 13),
      _l('B36846', 143, 501, 47, 14),
      _l('DXH 500 Lyse, 500mL', 237, 501, 131, 14),
      _l('5.00', 640, 499, 28, 14),
      _l('BOTTLE', 727, 501, 46, 14),
      _l('Batch/Serial #', 316, 520, 85, 13),
      _l('Quantity', 463, 520, 47, 13),
      _l('Expiry Date', 538, 520, 61, 13),
      _l('8300114', 252, 538, 47, 13),
      _l('5.00', 475, 538, 23, 13),
      _l('07/05/2027', 538, 538, 61, 13),
      _l('Comments:', 122, 640, 66, 14),
    ];

    test('no item is lost and each batch stays with its item', () {
      final r = ItemTableParser.parse(lines);
      expect(r.items.map((i) => i.itemCode), ['B36845', 'B36846']);
      expect(r.items[0].description, 'DxH 500 Diluent, 10L');
      expect(r.items[0].unit, 'BOX');
      expect(r.items[0].batches.map((b) => b.batchSerial), ['0179170']);
      expect(r.items[1].description, 'DXH 500 Lyse, 500mL');
      expect(r.items[1].batches.map((b) => (b.batchSerial, b.batchQuantity, b.expiryDate)),
          [('8300114', 5.0, '07/05/2027')]);
    });

    test('documents without batch titles never read a date as a batch', () {
      final r = ItemTableParser.parse([
        _l('QTY', 0, 0, 40),
        _l('DESCRIPTION', 200, 0, 120),
        _l('EXPIRY', 500, 0, 70),
        _l('1', 10, 40, 10),
        _l('ELUENT 90A', 200, 40, 120),
        _l('1/31/2027', 500, 40, 90),
      ]);
      expect(r.items.single.batches, isEmpty);
      expect(r.items.single.description, 'ELUENT 90A');
    });
  });

  group('S9 Delivery Receipt', () {
    test('DR number below its label; no Qty column → quantity 1, flagged', () {
      expect(ClientHeaderExtractor.extract(_s9DeliveryReceipt).name,
          'University of Cebu Medical Center, Inc.');
      expect(_refs(_s9DeliveryReceipt),
          containsAll(['DRNo.:690014676', 'PONo.:40405A']));

      final items = ItemTableParser.parse(_s9DeliveryReceipt);
      expect(items.items, hasLength(3));
      expect(items.items.first.description,
          'FIRST QUARTERLY MAINTENANCE VISIT OF SC2000 SN:402053');
      expect(items.unsure, {0, 1, 2});
      expect(DeliveryDocumentType.detect(_s9DeliveryReceipt),
          DeliveryDocumentType.deliveryReceipt);
    });
  });

  group('S10 Reagents Issue Slip', () {
    test('ISSUED TO, IS number, handwritten rows; row numbers not part numbers',
        () {
      final h = ClientHeaderExtractor.extract(_s10ReagentsIssueSlip);
      expect(h.label, 'ISSUED TO');
      expect(h.name, 'RITE-TECH MEDICAL FOR QMC');

      expect(_refs(_s10ReagentsIssueSlip),
          containsAll(['IS26-344', 'PONo.:RT-2026-0526-062-QMC']));

      final items = ItemTableParser.parse(_s10ReagentsIssueSlip);
      expect(items.items.map((i) => (i.partNo, i.description, i.unit, i.serialNo)), [
        ('105724', 'ELUENT 90A', 'BOX', '6A3101'),
        ('105724', 'ELUENT 90CV', 'BOX', '6A3401'),
        ('C22593', 'PCT Reagent', 'BOX', '6334463'),
      ]);
      expect(DeliveryDocumentType.detect(_s10ReagentsIssueSlip),
          DeliveryDocumentType.reagentsIssueSlip);
    });
  });

  group('document type → request form', () {
    const sd = DeliveryRequestForm.standardDelivery;

    test('titles', () {
      DeliveryDocumentType t(String title) =>
          DeliveryDocumentType.detect([_l(title, 0, 0, 300, 40)]);
      expect(t('INVENTORY TRANSFER REQUEST'),
          DeliveryDocumentType.inventoryTransferRequest);
      expect(t('INVENTORY TRANSFER'), DeliveryDocumentType.inventoryTransfer);
      expect(t('STOCK ISSUE SLIP'), DeliveryDocumentType.stockIssueSlip);
      expect(t('Acknowledgement Receipt'),
          DeliveryDocumentType.acknowledgementReceipt);
      expect(t('MATERIALS ISSUANCE SLIP'),
          DeliveryDocumentType.materialsIssuanceSlip);
      expect(t('RETURN/PULL OUT SLIP'), DeliveryDocumentType.returnPullOutSlip);
      expect(t('GOODS ISSUE'), DeliveryDocumentType.goodsIssue);
      expect(t('SALES INVOICE ORIGINAL'), DeliveryDocumentType.salesInvoice);
      expect(t('Delivery Receipt: DR 690014676'), DeliveryDocumentType.unknown);
      expect(t('ACKNOWLEDGEMENT CERTIFICATE CONTROL NO AC_048'),
          DeliveryDocumentType.unknown);
    });

    test('Standard Delivery takes SIS, GI, SI, DR and Reagents Issue Slip', () {
      expect(
        [
          for (final t in DeliveryDocumentType.values)
            if (t != DeliveryDocumentType.unknown && t.fits(sd)) t,
        ],
        [
          DeliveryDocumentType.stockIssueSlip,
          DeliveryDocumentType.goodsIssue,
          DeliveryDocumentType.salesInvoice,
          DeliveryDocumentType.deliveryReceipt,
          DeliveryDocumentType.reagentsIssueSlip,
        ],
      );
      expect(DeliveryDocumentType.unknown.fits(sd), isTrue);
    });

    test('the warning names the right forms', () {
      expect(DeliveryDocumentType.inventoryTransfer.mismatchWarning(sd),
          'An Inventory Transfer is for Air/Sea/Land and Air/Sea/Land HD, not Standard Delivery.');
      expect(DeliveryDocumentType.returnPullOutSlip.mismatchWarning(sd),
          'A Return / Pull Out Slip is for Pull Out, not Standard Delivery.');
      expect(DeliveryDocumentType.acknowledgementReceipt.mismatchWarning(sd),
          'An Acknowledgement Receipt is for Air/Sea/Land HD and Hotline Direct, not Standard Delivery.');
      expect(DeliveryDocumentType.salesInvoice.mismatchWarning(sd), isNull);
    });
  });

  group('each document keeps its own references', () {
    test('Inventory Transfer: IT No. and ITR No. only', () {
      expect(
          DeliveryDocumentType.inventoryTransfer.keepOwnReferences(
              ['ITNo.:750005578', 'AR26-239', 'ITRNo.:810003436']),
          ['ITNo.:750005578', 'ITRNo.:810003436']);
    });

    test('Sales Invoice: SI, DR and PO', () {
      expect(
          DeliveryDocumentType.salesInvoice.keepOwnReferences(
              ['SINo.:700014771', 'PONo.:PO-018561', 'DRNo.:690014771', 'GINo.:1']),
          ['SINo.:700014771', 'PONo.:PO-018561', 'DRNo.:690014771']);
    });

    test('Acknowledgement Receipt, Reagents Issue Slip and unknown keep all', () {
      const refs = ['AR26-240', 'IS26-344', 'PONo.:RT-2026-0526-062-QMC'];
      for (final t in [
        DeliveryDocumentType.acknowledgementReceipt,
        DeliveryDocumentType.reagentsIssueSlip,
        DeliveryDocumentType.unknown,
      ]) {
        expect(t.keepOwnReferences(refs), refs, reason: t.label);
      }
    });
  });
}
