import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/data/local/dao/status_progression.dart';

void main() {
  // Mirrors the Standard Delivery DAO map.
  const ranks = <String, int>{
    'New Request': 1,
    'Getting Supplies Ready': 2,
    'Item Prepared': 3,
    'For Delivery': 4,
    'Delivered': 5,
    'Cancelled': 99,
  };

  group('BStatusProgression.rank', () {
    test('matches regardless of casing', () {
      expect(BStatusProgression.rank(ranks, 'Getting Supplies Ready'), 2);
      // The constant the app actually writes uses a lowercase s and r.
      expect(BStatusProgression.rank(ranks, 'Getting supplies ready'), 2);
      expect(BStatusProgression.rank(ranks, 'GETTING SUPPLIES READY'), 2);
    });

    test('tolerates surrounding whitespace', () {
      expect(BStatusProgression.rank(ranks, '  Delivered '), 5);
    });

    test('returns null for unknown, empty and null statuses', () {
      expect(BStatusProgression.rank(ranks, 'Teleported'), isNull);
      expect(BStatusProgression.rank(ranks, ''), isNull);
      expect(BStatusProgression.rank(ranks, null), isNull);
    });

    test('the real status constant resolves', () {
      expect(
        BStatusProgression.rank(ranks, BTexts.statusGettingSuppliesReady),
        2,
        reason: 'casing drift between BTexts and the DAO maps must not '
            'silently disable the progression guard',
      );
    });
  });

  group('BStatusProgression.isRegression', () {
    bool regress(String? current, String? next) =>
        BStatusProgression.isRegression(
            ranks: ranks, current: current, next: next);

    test('blocks a backwards step', () {
      expect(regress('Delivered', 'New Request'), isTrue);
      expect(regress('Item Prepared', 'New Request'), isTrue);
    });

    test('allows forward and same-stage writes', () {
      expect(regress('New Request', 'Delivered'), isFalse);
      expect(regress('Delivered', 'Delivered'), isFalse);
    });

    test('blocks a backwards step across the casing drift', () {
      // The regression this guards: a stale server snapshot saying
      // "New Request" landing on a row already advanced past it.
      expect(regress(BTexts.statusGettingSuppliesReady, 'New Request'), isTrue);
      expect(regress('For Delivery', BTexts.statusGettingSuppliesReady), isTrue);
    });

    test('cancelling is never a regression', () {
      expect(regress('Delivered', 'Cancelled'), isFalse);
      expect(regress('New Request', 'Cancelled'), isFalse);
      expect(regress('Delivered', 'cancelled'), isFalse);
    });

    test('lets unknown statuses through rather than blocking blindly', () {
      expect(regress('Teleported', 'New Request'), isFalse);
      expect(regress('Delivered', 'Teleported'), isFalse);
      expect(regress(null, 'New Request'), isFalse);
      expect(regress('', 'New Request'), isFalse);
    });
  });
}
