import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_constants.dart';
import 'package:mdmpi_mobile_app/features/logistics/constants/form_category_ids.dart';

void main() {
  group('Air / Sea / Land HD category', () {
    test('fromCategoryName resolves the HD name to airSeaHd, not airSea', () {
      expect(
        FormCategoryConstants.fromCategoryName('Air / Sea / Land HD'),
        FormCategoryType.airSeaHd,
      );
      expect(
        FormCategoryConstants.fromCategoryName('air / sea / land hd'),
        FormCategoryType.airSeaHd,
      );
      expect(
        FormCategoryConstants.fromCategoryName('Air / Sea / Land'),
        FormCategoryType.airSea,
      );
      expect(
        FormCategoryConstants.fromCategoryName('Air / Sea'),
        FormCategoryType.airSea,
      );
    });

    test('HD shares the Air/Sea form', () {
      expect(FormCategoryType.airSeaHd.usesSharedForm, isTrue);
      expect(
          FormCategoryType.airSeaHd.baseFormCategory, FormCategoryType.airSea);
      expect(FormCategoryType.airSeaHd.actualFormPageIndex,
          FormCategoryType.airSea.actualFormPageIndex);
    });

    test('category name fits the server varchar(20) column', () {
      expect(
          FormCategoryType.airSeaHd.categoryName.length, lessThanOrEqualTo(20));
    });

    test('scope.matches buckets rows correctly, NULL/legacy under base', () {
      const base = AirSeaCategoryScope.base;
      const hd = AirSeaCategoryScope.hotlineDirect;

      // Legacy rows have no category at all.
      expect(base.matches(null), isTrue);
      expect(base.matches(''), isTrue);
      expect(base.matches(' '), isTrue);
      expect(hd.matches(null), isFalse);
      expect(hd.matches(''), isFalse);

      // HD rows carry the pinned id.
      expect(hd.matches(FormCategoryIds.airSeaHd), isTrue);
      expect(base.matches(FormCategoryIds.airSeaHd), isFalse);

      // Any other value stays on the base tab.
      expect(base.matches('999'), isTrue);
      expect(hd.matches('999'), isFalse);
    });

    test('every FormCategoryType still has a formPageIndex slot', () {
      final indexes =
          FormCategoryType.values.map((t) => t.formPageIndex).toList();
      expect(indexes.toSet().length, FormCategoryType.values.length);
      for (var i = 0; i < FormCategoryType.values.length; i++) {
        expect(indexes.contains(i), isTrue,
            reason: 'formPageIndex $i missing — home-grid lists are '
                'index-aligned with FormCategoryType.values');
      }
    });
  });
}
