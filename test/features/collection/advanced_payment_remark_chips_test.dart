import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/add_activity/advanced_payment_form.dart';

/// The Advanced Payment remark chips add their label to the remarks, and a
/// second tap takes it back out, leaving anything typed alone.
void main() {
  test('a chip adds its label to empty remarks', () {
    expect(toggleRemarkChip('', 'Machine'), 'Machine');
  });

  test('a chip appends after what was typed', () {
    expect(toggleRemarkChip('For Q4', 'Reagents'), 'For Q4, Reagents');
  });

  test('a second tap removes the label and keeps the rest', () {
    expect(toggleRemarkChip('Machine, For Q4, Reagents', 'machine'),
        'For Q4, Reagents');
  });

  test('blank parts and stray commas are tidied', () {
    expect(toggleRemarkChip(' , Machine ,, ', 'Hold accounts'),
        'Machine, Hold accounts');
  });

  test('the chips offered are the ones asked for', () {
    expect(advancedPaymentRemarkChips,
        containsAll(['Machine', 'Reagents', 'Hold accounts']));
  });
}
