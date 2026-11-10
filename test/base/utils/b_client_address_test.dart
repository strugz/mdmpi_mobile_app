import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/base/utils/b_client_address.dart';

void main() {
  const scanned = 'Villamor, Esperanza Sultan Kudarat';

  test('the saved address wins', () {
    final r = BClientAddress.resolve('Seminary Road, Quezon City', scanned);
    expect(r.address, 'Seminary Road, Quezon City');
    expect(r.fromScan, isFalse);
  });

  for (final missing in ['', '   ', 'none', 'NONE', 'NA', 'na', 'n/a', 'N/A', ' N/A ', null]) {
    test('the scanned address is used when the saved one is "$missing"', () {
      final r = BClientAddress.resolve(missing, scanned);
      expect(r.address, scanned);
      expect(r.fromScan, isTrue);
    });
  }

  test('no scanned address keeps the saved value', () {
    expect(BClientAddress.resolve('N/A', null), (address: 'N/A', fromScan: false));
    expect(BClientAddress.resolve('N/A', '  '), (address: 'N/A', fromScan: false));
    expect(BClientAddress.resolve('', 'n/a'), (address: '', fromScan: false));
  });

  test('isMissing', () {
    expect(BClientAddress.isMissing('Makati'), isFalse);
    expect(BClientAddress.isMissing('NAGA CITY'), isFalse);
    expect(BClientAddress.isMissing('N/A'), isTrue);
  });
}
