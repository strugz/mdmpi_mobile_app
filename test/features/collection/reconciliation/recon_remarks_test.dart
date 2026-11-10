import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_remarks.dart';

/// A remark per invoice on a reconciliation step (update checklist item 20),
/// written one per line into the step's single remark.

void main() {
  test('the remark for all first, then each invoice in the listed order', () {
    expect(
        BReconRemarks.compose(
          general: '  Called Ms. Cruz ',
          invoiceNos: ['700009771', '700009347'],
          perInvoice: {
            '700009347': 'Deposit slip to follow',
            '700009771': 'Paid by check',
          },
        ),
        'Called Ms. Cruz\n'
        'SI 700009771 - Paid by check\n'
        'SI 700009347 - Deposit slip to follow');
  });

  test('blank remarks are left out', () {
    expect(
        BReconRemarks.compose(
          general: '',
          invoiceNos: ['A', 'B', 'C'],
          perInvoice: {'A': '  ', 'B': 'Paid'},
        ),
        'SI B - Paid');
  });

  test('an invoice remark stays on its own line', () {
    expect(
        BReconRemarks.compose(
          general: '',
          invoiceNos: ['A'],
          perInvoice: {'A': 'Paid\n  by check'},
        ),
        'SI A - Paid by check');
  });

  test('a remark for an invoice not named is not written', () {
    expect(
        BReconRemarks.compose(
            general: 'x', invoiceNos: ['A'], perInvoice: {'Z': 'gone'}),
        'x');
  });
}
