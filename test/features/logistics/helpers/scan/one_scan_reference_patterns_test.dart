import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_extractor.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/one_scan_reference_patterns.dart';

/// The shared extractor first, then the one-scan extras, the way the scan
/// service runs them.
List<String> _scan(String text, {List<String> exclude = const []}) =>
    OneScanReferencePatterns.extract(
      text,
      DocumentReferenceExtractor().extractPatterns(text),
      excludeTexts: exclude,
    );

void main() {
  test('Sales Invoice: DR without "No." plus the SI and PO the extractor finds',
      () {
    final refs = _scan('SI No.: 700014535\n'
        'PO No.: 358-C64033-A\n'
        'Delivery Receipt: DR 690014535');
    expect(refs, [
      'SINo.:700014535',
      'PONo.:358-C64033-A',
      'DRNo.:690014535',
    ]);
  });

  test('our TIN lines are not references', () {
    expect(
      _scan('VAT Reg TIN: 204-595-997-00000\nTIN: 194-402-270-000\n'
          'Tel #: (632) 7751-9999'),
      isEmpty,
    );
  });

  test('S1 ITR number on the line below its label', () {
    expect(_scan('ITR No.:\nPosting Date:\nTransfer\nRequest Date:\n810003448'),
        ['ITRNo.:810003448']);
  });

  test('S1 device capture: ITR number under its label, past the TIN and phone',
      () {
    OcrLine l(String t, double x, double y, double w) =>
        OcrLine(t, Rect.fromLTWH(x, y, w, 20));
    final refs = OneScanReferencePatterns.fromLines([
      l('Business Partner:', 55, 252, 163),
      l('INVENTORY TRANSFER REQUEST', 923, 245, 578),
      l('DLR-190', 55, 284, 80),
      l('Galinato Clinic and Hospital', 207, 284, 257),
      l('ORIGINAL', 1145, 286, 130),
      l('TIN: 194-402-270-000', 55, 313, 197),
      l('ITR No.:', 915, 315, 75),
      l('Posting Date:', 1188, 313, 122),
      l('Transfer', 1388, 311, 80),
      l('Tel #: 0948-249-7012', 55, 340, 190),
      l('Request Date:', 1363, 339, 132),
      l('Fax:', 55, 366, 36),
      l('810003448', 985, 375, 102),
      l('10/15/2026', 1200, 375, 110),
      l('10/15/2026', 1376, 372, 110),
    ], DocumentReferenceExtractor());
    expect(refs, contains('ITRNo.:810003448'));
    expect(refs.where((r) => r.startsWith('ITRNo.:')), hasLength(1));
  });

  test('S1 device capture: OCR slips in the ITR label and number', () {
    OcrLine l(String t, double x, double y, double w) =>
        OcrLine(t, Rect.fromLTWH(x, y, w, 20));
    final refs = OneScanReferencePatterns.fromLines([
      l('TIN: 194-402-270-000', 55, 313, 197),
      l('|TR No.:', 915, 315, 75),
      l('Tel #: 0948-249-7012', 55, 340, 190),
      l('B10003448', 985, 375, 102),
    ], DocumentReferenceExtractor());
    expect(refs, contains('ITRNo.:810003448'));
  });

  test('S3 IT number and the request it is based on', () {
    expect(
      _scan('IT No.:\n750005578\nTransfer Request No.: ITR 810003436'),
      ['ITNo.:750005578', 'ITRNo.:810003436'],
    );
  });

  test('S2 Stock Issue Slip number without "SIS"', () {
    expect(_scan('STOCK ISSUE SLIP\nNo. 00611\nDELIVERED TO:'), ['SIS#:00611']);
  });

  test('S7 Goods Issue reference IT number', () {
    expect(
      _scan('GI No.:\n760006490\nReference No.:\nIT750005302'),
      ['GINo.:760006490', 'ITNo.:750005302'],
    );
  });

  test('S2 property tags are not references', () {
    expect(_scan('PTN\nACS26-09742\n'), isEmpty,
        reason: 'CS26-09742 is read out of ACS26-09742');
    expect(_scan('PTN\nFA26-0609\n', exclude: ['FA26-0609']), isEmpty,
        reason: 'a property tag in the item table');
  });

  test('a real bare code is kept', () {
    expect(_scan('NO. AR26-240'), ['AR26-240']);
  });

  test('S6 SIS# from the DR column, once', () {
    expect(_scan('DR No.\nSIS#00595\nSTOCK ISSUE SLIP No. 00595'),
        ['SIS#:00595']);
  });
}
