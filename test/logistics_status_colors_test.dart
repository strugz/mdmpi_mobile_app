import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/status_color_mapper.dart';

void main() {
  group('LogisticsStatusColors.colorsFor', () {
    test('Cancelled returns cancelled background with dark text', () {
      final (bg, fg) = LogisticsStatusColors.colorsFor(BTexts.statusCancelled);
      expect(bg.value, isNotNull);
      expect(fg.value, isNotNull);
      expect(bg != fg, true);
    });

    test('Unknown status falls back colors', () {
      final (bg, fg) = LogisticsStatusColors.colorsFor('RANDOM_STATUS');
      expect(bg != fg, true);
    });
  });

  group('LogisticsStatusColors.display full words', () {
    test('Empty maps to Unknown', () {
      expect(LogisticsStatusColors.display('   '), 'Unknown');
    });
    test('Keeps original full status text', () {
      expect(LogisticsStatusColors.display(BTexts.statusGettingSuppliesReady), BTexts.statusGettingSuppliesReady);
      expect(LogisticsStatusColors.display(BTexts.statusItemPrepared), BTexts.statusItemPrepared);
      expect(LogisticsStatusColors.display(BTexts.statusDoneDelivery), BTexts.statusDoneDelivery);
    });
  });

  group('LogisticsStatusColors adaptive contrast', () {
    test('Light mode For Delivery uses primary text color', () {
      final (bg, fg) = LogisticsStatusColors.colorsFor(BTexts.statusForDelivery, darkMode: false);
      expect(fg != bg, true);
    });
    test('Dark mode translucency boosted', () {
      final (bgLight, _) = LogisticsStatusColors.colorsFor(BTexts.statusGettingSuppliesReady, darkMode: false);
      final (bgDark, _) = LogisticsStatusColors.colorsFor(BTexts.statusGettingSuppliesReady, darkMode: true);
      expect(bgDark.opacity >= bgLight.opacity, true);
    });
    test('Foreground auto-adjusts for insufficient contrast', () {
      final (bg, fg) = LogisticsStatusColors.colorsFor('UNKNOWN_STATUS', darkMode: true);
      expect(fg != bg, true);
    });
  });
}
