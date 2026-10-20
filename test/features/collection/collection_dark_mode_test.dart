import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/theme/theme.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/models/collection_item_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/activity/add_activity/widgets/engagement_invoice_picker.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';

/// Collection in dark mode. The app follows the phone's light/dark setting,
/// but only the light Collection theme was ever installed, so a phone in
/// dark mode drew Collection's white cards and fields on the app's black
/// theme, with that theme's white text on them.

CollectionItemModel _invoice(String id) => CollectionItemModel(
      id: id,
      client: ClientModel(
          id: 'C1',
          code: 'NCR-400',
          name: 'Best Care Pharmacy',
          address: '',
          contact: '',
          emailAddress: ''),
      toBeCollected: 1000,
      dueDate: '2026-10-30',
    );

void main() {
  tearDown(() {
    BCollectionColors.debugBrightness = null;
    BCollectionTheme.debugReset();
    Get.reset();
  });

  group('the tokens follow the phone', () {
    test('light by default', () {
      expect(BCollectionColors.isDark, isFalse);
      expect(BCollectionColors.surface, BCollectionPalette.light.surface);
      expect(BCollectionColors.ink, BCollectionPalette.light.ink);
    });

    test('dark when the phone is', () {
      BCollectionColors.debugBrightness = Brightness.dark;
      expect(BCollectionColors.isDark, isTrue);
      expect(BCollectionColors.surface, BCollectionPalette.dark.surface);
      expect(BCollectionColors.ink, BCollectionPalette.dark.ink);
      expect(BCollectionColors.scheme.brightness, Brightness.dark);
    });

    test('the light palette is the one the module always had', () {
      const l = BCollectionPalette.light;
      expect(l.background, const Color(0xFFF7F7F5));
      expect(l.surface, const Color(0xFFFFFFFF));
      expect(l.ink, const Color(0xFF1C1C1E));
      expect(l.primary, const Color(0xFF3452C7));
      expect(l.headerBackground, const Color(0xFF1F2A5C));
    });

    test('dark ink stands off the dark surfaces', () {
      const d = BCollectionPalette.dark;
      for (final bg in [d.background, d.surface, d.surfaceMuted]) {
        expect(d.ink.computeLuminance() - bg.computeLuminance(),
            greaterThan(0.6));
      }
      expect(d.primary.computeLuminance(),
          greaterThan(d.onPrimary.computeLuminance()),
          reason: 'button text is dark on the lifted accent');
    });
  });

  group('the dark theme', () {
    test('is dark and wears the Collection tokens', () {
      final t = BCollectionTheme.dark;
      const d = BCollectionPalette.dark;
      expect(t.brightness, Brightness.dark);
      expect(t.colorScheme.brightness, Brightness.dark);
      expect(t.scaffoldBackgroundColor, d.background);
      expect(t.cardTheme.color, d.surface);
      expect(t.appBarTheme.backgroundColor, d.headerBackground);
      expect(t.inputDecorationTheme.fillColor, d.surfaceMuted);
    });

    test('the light theme is unchanged', () {
      final t = BCollectionTheme.light;
      const l = BCollectionPalette.light;
      expect(t.brightness, Brightness.light);
      expect(t.scaffoldBackgroundColor, l.background);
      expect(t.cardTheme.color, l.surface);
      expect(t.appBarTheme.backgroundColor, l.headerBackground);
    });
  });

  testWidgets('applying Collection installs its dark theme too',
      (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    late BuildContext ctx;
    await tester.pumpWidget(GetMaterialApp(
      themeMode: ThemeMode.system,
      theme: BAppTheme.lightTheme,
      darkTheme: BAppTheme.darkTheme,
      home: Builder(builder: (c) {
        ctx = c;
        return const Scaffold();
      }),
    ));
    expect(Theme.of(ctx).scaffoldBackgroundColor, Colors.black,
        reason: "the app's own dark theme before Collection is applied");

    BCollectionTheme.applyFor('Collection');
    await tester.pumpAndSettle();
    expect(Theme.of(ctx).scaffoldBackgroundColor,
        BCollectionPalette.dark.background);

    // And a light phone gets the light one: the dark theme must not land
    // in the light slot.
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(Theme.of(ctx).scaffoldBackgroundColor,
        BCollectionPalette.light.background);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();

    BCollectionTheme.applyFor('Logistics');
    await tester.pumpAndSettle();
    expect(Theme.of(ctx).scaffoldBackgroundColor, Colors.black,
        reason: 'back to the app theme for everyone else');
  });

  testWidgets('a Collection widget draws dark in dark mode', (tester) async {
    BCollectionColors.debugBrightness = Brightness.dark;
    await tester.pumpWidget(MaterialApp(
      theme: BCollectionTheme.dark,
      home: Scaffold(
        body: EngagementInvoicePicker(
          invoices: [_invoice('RC1')],
          selectedIds: const [],
          onToggle: (_, __) {},
        ),
      ),
    ));

    final box = tester.widget<Container>(find
        .ancestor(
            of: find.byType(ListView), matching: find.byType(Container))
        .first);
    expect((box.decoration as BoxDecoration).color,
        BCollectionPalette.dark.surface,
        reason: 'it was white on black');
    final amount = tester.widget<Text>(find.textContaining('1,000'));
    expect(amount.style?.color, BCollectionPalette.dark.ink);
  });
}
