import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_text_recognition_service.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/voucher_layout_reader.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/voucher_si_matcher.dart';
import 'package:mdmpi_mobile_app/features/collection/models/scanned_invoice.dart';

/// Reading a voucher with no internet: the phone's own text recognition,
/// line by line with positions, read by layout (labels and columns) and
/// matched against the account with near misses allowed.

OcrLine _l(String text, double left, double top, [double width = 200]) =>
    OcrLine(text, Rect.fromLTWH(left, top, width, 20));

void main() {
  group('layout', () {
    test('a number after an SI / Invoice label is an invoice', () {
      final r = VoucherLayoutReader.read([
        _l('Payment for SI No. 240009288 / 240009608', 0, 0, 400),
        _l('Sales Invoice # 240010232', 0, 30),
        _l('SI#240004614', 0, 60),
        _l('INV-97339 amount 12,700.00', 0, 90),
      ]);
      expect(r.labelled,
          ['240009288', '240009608', '240010232', '240004614', '97339']);
    });

    test('numbers after P.O., check, CV, OR, DR, TIN are never invoices', () {
      final r = VoucherLayoutReader.read([
        _l('CV No. 2026-0098   Check No. 0012345678', 0, 0, 400),
        _l('P.O. 4500012345  SI 240009288', 0, 30, 400),
        _l('OR# 556677  TIN 123-456-789-000', 0, 60, 400),
      ]);
      expect(r.labelled, ['240009288']);
      expect(r.excluded,
          containsAll(['2026-0098', '0012345678', '4500012345', '556677']));
    });

    test('a column under an "SI No." header is a column of invoices', () {
      final r = VoucherLayoutReader.read([
        _l('Particulars', 0, 0, 120),
        _l('SI No.', 200, 0, 80),
        _l('Amount', 360, 0, 80),
        _l('240009288', 195, 30, 90),
        _l('12,700.00', 360, 30, 90),
        _l('240009608', 195, 60, 90),
        _l('12,700.00', 360, 60, 90),
      ]);
      expect(r.labelled, ['240009288', '240009608']);
      expect(r.unlabelled, isNot(contains('240009288')));
    });

    test('an "Invoice Date" column is not a column of invoice numbers', () {
      final r = VoucherLayoutReader.read([
        _l('Invoice Date', 200, 0, 100),
        _l('09/15/2026', 200, 30, 100),
      ]);
      expect(r.labelled, isEmpty);
    });

    test('ordinary words "or", "si" never count as labels', () {
      final r = VoucherLayoutReader.read([
        _l('Pay this or 240009288 si senor', 0, 0, 400),
      ]);
      expect(r.labelled, isEmpty);
      expect(r.excluded, isEmpty);
      expect(r.unlabelled, ['240009288']);
    });
  });

  group('near matches', () {
    const open = ['240009288', '240009608', '240010232', '97339'];

    test('one digit off a single open invoice', () {
      expect(VoucherSiMatcher.nearIds('240009238', open), ['240009288']);
      expect(VoucherSiMatcher.nearIds('24OOO9638', open), ['240009608'],
          reason: 'letter-for-digit slips undone first');
    });

    test('never across lengths, never on short numbers, never two off', () {
      expect(VoucherSiMatcher.nearIds('24000928', open), isEmpty);
      expect(VoucherSiMatcher.nearIds('97338', open), ['97339']);
      expect(VoucherSiMatcher.nearIds('9733', open), isEmpty);
      expect(VoucherSiMatcher.nearIds('240009333', open), isEmpty);
    });

    test('a likely misread is selected but marked to check', () {
      const c = ScannedInvoiceClassifier(knownIds: open);
      final t = c.line(const VoucherInvoiceLine(invoiceNo: '240009238'));
      expect(t.status, ScannedInvoiceStatus.likely);
      expect(t.invoiceId, '240009288');
      expect(t.status.canAdd, isTrue);
    });

    test('a reading one off two invoices is not guessed', () {
      const c = ScannedInvoiceClassifier(knownIds: ['240009288', '240009388']);
      expect(c.line(const VoucherInvoiceLine(invoiceNo: '240009188')).status,
          ScannedInvoiceStatus.ambiguous);
    });
  });

  test('offline page: labels, columns, misreads and noise together', () {
    const c = ScannedInvoiceClassifier(
      knownIds: ['240009288', '240009608', '240010232', '240004614'],
      ignore: ['4500012345'],
    );
    final tiles = c.offlineLines([
      _l('CHECK VOUCHER   CV No. 2026-0098', 0, 0, 400),
      _l('P.O. 4500012345', 0, 30),
      _l('SI No.', 200, 60, 80),
      _l('24OOO9288', 195, 90, 90), // O for 0: exact after the slip fix
      _l('240009638', 195, 120, 90), // one digit off 240009608
      _l('240077777', 195, 150, 90), // labelled, not this account's
      _l('Total 25,400.00   09/30/2026', 0, 180, 400),
      _l('Ref 240010232', 0, 210), // unlabelled, but an exact open invoice
    ]);
    expect(tiles.map((t) => (t.read, t.status)), [
      ('24OOO9288', ScannedInvoiceStatus.matched),
      ('240009638', ScannedInvoiceStatus.likely),
      ('240077777', ScannedInvoiceStatus.notFound),
      ('240010232', ScannedInvoiceStatus.matched),
    ]);
    expect(tiles.every((t) => t.offline), isTrue);
  });
}
