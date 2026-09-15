import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_area.dart';

void main() {
  test('empty selection matches every code', () {
    expect(BCollectionArea.matches('NLN-1', ''), isTrue);
    expect(BCollectionArea.matches('', ''), isTrue);
  });

  test('matches by prefix, case-insensitively', () {
    expect(BCollectionArea.matches('NCR-205', 'NCR'), isTrue);
    expect(BCollectionArea.matches('ncr-205', 'NCR'), isTrue);
    expect(BCollectionArea.matches('NCR-205', 'ncr'), isTrue);
    expect(BCollectionArea.matches('NLN-115', 'NCR'), isFalse);
  });

  test('does not match on a bare substring', () {
    // "NCR" must not match a code whose prefix merely starts with NCR.
    expect(BCollectionArea.matches('NCRX-1', 'NCR'), isFalse);
  });

  test('Others is every prefix outside the named territories', () {
    for (final code in ['VET-10', 'CSAT-3', 'ABC-1', 'NOPREFIX']) {
      expect(BCollectionArea.matches(code, BCollectionArea.others), isTrue, reason: code);
    }
    for (final code in ['NLN-1', 'SLN-1', 'CLN-1', 'ncr-1', 'VIS-1', 'MIN-1', 'RAD-1']) {
      expect(BCollectionArea.matches(code, BCollectionArea.others), isFalse, reason: code);
    }
  });

  test('labels', () {
    expect(BCollectionArea.labelFor('NLN'), 'North Luzon');
    expect(BCollectionArea.labelFor('OTHERS'), 'Others');
    expect(BCollectionArea.labelFor('XYZ'), 'XYZ');
  });
}
