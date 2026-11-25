import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/services/sim_info_service.dart';

void main() {
  group('DefaultSmsSim', () {
    test('shows slot, carrier and number', () {
      final sim = DefaultSmsSim.fromMap({
        'simCount': 2,
        'hasDefault': true,
        'slot': 2,
        'carrier': 'Carrier A',
        'number': '09170000000',
      });
      expect(sim.summary, 'SIM 2 · Carrier A · 09170000000');
    });

    test('says when the SIM does not store its number', () {
      final sim = DefaultSmsSim.fromMap({
        'simCount': 1,
        'hasDefault': true,
        'slot': 1,
        'carrier': 'Carrier B',
        'number': '  ',
      });
      expect(sim.number, isNull);
      expect(sim.summary, 'SIM 1 · Carrier B · number not stored on this SIM');
    });

    test('flags Ask every time', () {
      final sim = DefaultSmsSim.fromMap({'simCount': 2, 'hasDefault': false});
      expect(sim.summary, startsWith('No default SMS SIM'));
    });

    test('no SIM and missing keys', () {
      expect(DefaultSmsSim.fromMap({}).summary, 'No SIM found');
    });
  });
}
