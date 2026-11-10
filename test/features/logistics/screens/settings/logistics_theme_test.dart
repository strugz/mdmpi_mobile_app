import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/theme/logistics_theme.dart';
import 'package:mdmpi_mobile_app/base/utils/theme/theme.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/settings/logistics_theme_screen.dart';

/// Settings → Theme for Logistics: five colour themes, and light or dark.

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  tearDown(() {
    BLogisticsColors.debugBrightness = null;
    BLogisticsColors.themeMode = ThemeMode.system;
    BLogisticsColors.accent = BLogisticsAccent.ocean;
    BCollectionTheme.debugReset();
    Get.reset();
  });

  group('colour themes', () {
    test('Ocean is the original Logistics blue, and the default', () {
      expect(BLogisticsAccent.ocean.primary, const Color(0xFF4B68FF));
      expect(BLogisticsColors.accent, BLogisticsAccent.ocean);
      expect(BColors.primary, const Color(0xFF4B68FF));
    });

    test('the same five names as Collection', () {
      expect(BLogisticsAccent.values.map((a) => a.label),
          BCollectionAccent.values.map((a) => a.label));
    });

    test('white text stays readable on every theme colour', () {
      for (final a in BLogisticsAccent.values) {
        // 4.4, not 4.5: the original Logistics blue (Ocean) sits at 4.45,
        // and it stays as it always was.
        expect(_contrast(a.primary, Colors.white), greaterThanOrEqualTo(4.4),
            reason: '${a.label}: header and button text');
        expect(_contrast(a.primary, a.soft), greaterThanOrEqualTo(3),
            reason: '${a.label}: icon on its tile');
      }
    });

    test('the choice is saved and read back; anything else is Ocean', () {
      final store = <String, Object>{};
      BLogisticsTheme.setAccent(BLogisticsAccent.teal,
          write: (k, v) => store[k] = v);
      BLogisticsTheme.setMode(ThemeMode.dark, write: (k, v) => store[k] = v);
      expect(store, {
        BLogisticsTheme.accentKey: 'teal',
        BLogisticsTheme.themeModeKey: 'dark',
      });
      expect(BColors.primary, BLogisticsAccent.teal.primary,
          reason: 'the brand colour follows at once');
      expect(BLogisticsTheme.readSavedAccent((k) => store[k]),
          BLogisticsAccent.teal);
      expect(BLogisticsTheme.readSavedMode((k) => store[k]), ThemeMode.dark);

      expect(BLogisticsTheme.readSavedAccent((_) => 'neon'),
          BLogisticsAccent.ocean);
      expect(
          BLogisticsTheme.readSavedAccent((_) => throw StateError('no storage')),
          BLogisticsAccent.ocean);
      expect(BLogisticsTheme.readSavedMode((_) => null), ThemeMode.system);
    });
  });

  testWidgets('a Logistics session wears the saved colour, and a pick '
      'recolours the app', (tester) async {
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
    BCollectionTheme.applyFor('Logistics');
    await tester.pumpAndSettle();
    expect(Theme.of(ctx).colorScheme.primary, BLogisticsAccent.ocean.primary);

    BLogisticsTheme.setAccent(BLogisticsAccent.rose, write: (_, __) {});
    await tester.pumpAndSettle();
    expect(Theme.of(ctx).colorScheme.primary, BLogisticsAccent.rose.primary);
    expect(Theme.of(ctx).primaryColor, BLogisticsAccent.rose.primary);
  });

  group('the Theme page', () {
    Future<({List<ThemeMode> modes, List<BLogisticsAccent> accents})> pump(
        WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      final modes = <ThemeMode>[];
      final accents = <BLogisticsAccent>[];
      await tester.pumpWidget(GetMaterialApp(
        theme: BLogisticsTheme.light,
        home: LogisticsThemeScreen(onMode: modes.add, onAccent: accents.add),
      ));
      await tester.pumpAndSettle();
      return (modes: modes, accents: accents);
    }

    testWidgets('offers every colour, the picked one marked', (tester) async {
      BLogisticsColors.accent = BLogisticsAccent.cocoa;
      await pump(tester);
      for (final a in BLogisticsAccent.values) {
        expect(find.byKey(ValueKey('theme-accent-${a.name}')), findsOneWidget);
        expect(find.text(a.label), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('theme-preview')), findsOneWidget);
      expect(
          tester.getSemantics(find.bySemanticsLabel('Cocoa colour theme')),
          matchesSemantics(
              isButton: true,
              isSelected: true,
              hasSelectedState: true,
              hasTapAction: true,
              label: 'Cocoa colour theme'));
    });

    testWidgets('renders in dark mode too', (tester) async {
      BLogisticsColors.debugBrightness = Brightness.dark;
      await pump(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Graphite'), findsOneWidget);
    });

    testWidgets('a tap on a colour or a mode asks for it', (tester) async {
      final asked = await pump(tester);
      await tester.tap(find.byKey(const ValueKey('theme-accent-teal')));
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(asked.accents, [BLogisticsAccent.teal]);
      expect(asked.modes, [ThemeMode.dark]);
    });

    test('Settings says which theme is on', () {
      BLogisticsColors.accent = BLogisticsAccent.graphite;
      BLogisticsColors.themeMode = ThemeMode.dark;
      expect(LogisticsThemeScreen.summary(), 'Graphite · Dark');
      BLogisticsColors.themeMode = ThemeMode.system;
      expect(LogisticsThemeScreen.summary(), 'Graphite · Follows the phone');
    });
  });
}
