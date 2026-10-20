import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/services/collection_sms_service.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/deposit_remarks.dart';

/// A deposit's remarks: "Account - Amount", one per line, then an optional
/// note (update checklist item 13), and how the deposit SMS shows them.

void main() {
  group('BDepositRemarks', () {
    test('one line per account, the amount with two decimals', () {
      expect(BDepositRemarks.line('Antipolo Doctors Hospital', 25000),
          'Antipolo Doctors Hospital - 25,000.00');
      expect(BDepositRemarks.line('  Ace   Diagnostics Corp. ', 5000.5),
          'Ace Diagnostics Corp. - 5,000.50');
    });

    test('the note comes last, and only when there is one', () {
      const lines = [
        BDepositLine(account: 'Antipolo Doctors Hospital', amount: 25000),
        BDepositLine(account: 'Ace Diagnostics Corp.', amount: 5000),
      ];
      expect(
          BDepositRemarks.compose(lines, note: ' Morning  run '),
          'Antipolo Doctors Hospital - 25,000.00\n'
          'Ace Diagnostics Corp. - 5,000.00\n'
          'Note: Morning run');
      expect(BDepositRemarks.compose(lines, note: '  '),
          'Antipolo Doctors Hospital - 25,000.00\nAce Diagnostics Corp. - 5,000.00');
    });

    test('reads a line back; anything else is not one', () {
      expect(BDepositRemarks.parseLine('Ace Diagnostics Corp. - 5,000.00'),
          (account: 'Ace Diagnostics Corp.', amount: '5,000.00'));
      expect(BDepositRemarks.parseLine('Note: Morning run'), isNull);
      expect(BDepositRemarks.parseLine('Follow Up - Signatory out'), isNull);
    });

    test('a dozen accounts fit the 500 characters the server keeps', () {
      final lines = [
        for (var i = 0; i < 12; i++)
          BDepositLine(account: 'Antipolo Doctors Hospital $i', amount: 25000),
      ];
      expect(BDepositRemarks.compose(lines).length,
          lessThanOrEqualTo(BDepositRemarks.maxLength));
    });
  });

  group('the deposit SMS', () {
    test('lists each account on its own line, in PHP', () {
      expect(
        CollectionSmsService.depositAdded(
          bankName: 'BDO',
          amount: 30000,
          checkNumber: '1254897',
          remarks: 'Antipolo Doctors Hospital - 25,000.00\n'
              'Ace Diagnostics Corp. - 5,000.00\n'
              'Note: Morning run',
        ),
        'Deposited: PHP 30,000.00\n'
        'Bank: BDO\n'
        'Check: 1254897\n'
        'Antipolo Doctors Hospital - PHP 25,000.00\n'
        'Ace Diagnostics Corp. - PHP 5,000.00\n'
        'Note: Morning run',
      );
    });

    test('remarks written before the format stay one Note line', () {
      expect(
        CollectionSmsService.depositAdded(
            bankName: 'BDO', amount: 1, remarks: 'Morning run'),
        'Deposited: PHP 1.00\nBank: BDO\nNote: Morning run',
      );
    });

    test('plain SMS text', () {
      final m = CollectionSmsService.depositAdded(
          bankName: 'BDO',
          amount: 30000,
          remarks: 'Antipolo Doctors Hospital - 25,000.00\nNote: x');
      expect(RegExp(r'^[\x20-\x7E\n]*$').hasMatch(m), isTrue, reason: m);
    });
  });
}
