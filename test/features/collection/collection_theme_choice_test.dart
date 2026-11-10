import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/theme/theme.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/settings/collection_theme_screen.dart';

/// Settings → Theme: colour themes for Collection, and light or dark.

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  tearDown(() {
    BCollectionColors.debugBrightness = null;
    BCollectionColors.themeMode = ThemeMode.system;
    BCollectionColors.accent = BCollectionAccent.ocean;
    BCollectionTheme.debugReset();
    Get.reset();
  });

  group('colour themes', () {
    test('Ocean is the original Collection blue', () {
      for (final b in Brightness.values) {
        final base = b == Brightness.dark
            ? BCollectionPalette.dark
            : BCollectionPalette.light;
        final ocean = BCollectionTheme.paletteFor(b, BCollectionAccent.ocean);
        expect(ocean.primary, base.primary);
        expect(ocean.primarySoft, base.primarySoft);
        expect(ocean.headerBackground, base.headerBackground);
        expect(ocean.onHeaderMuted, base.onHeaderMuted);
      }
    });

    test('a theme changes the accent and header, never a status colour', () {
      for (final b in Brightness.values) {
        final ocean = BCollectionTheme.paletteFor(b, BCollectionAccent.ocean);
        for (final accent in BCollectionAccent.values) {
          final p = BCollectionTheme.paletteFor(b, accent);
          expect(p.brightness, b);
          expect([p.success, p.warning, p.danger, p.reconcile, p.info],
              [ocean.success, ocean.warning, ocean.danger, ocean.reconcile, ocean.info]);
          expect([p.background, p.surface, p.ink, p.outline],
              [ocean.background, ocean.surface, ocean.ink, ocean.outline]);
          if (accent != BCollectionAccent.ocean) {
            expect(p.primary, isNot(ocean.primary), reason: accent.label);
          }
        }
      }
    });

    test('button and header text stay readable in every theme', () {
      for (final b in Brightness.values) {
        for (final accent in BCollectionAccent.values) {
          final p = BCollectionTheme.paletteFor(b, accent);
          final at = '${accent.label}, ${b.name}';
          expect(_contrast(p.primary, p.onPrimary), greaterThanOrEqualTo(4.5),
              reason: 'button text, $at');
          expect(_contrast(p.headerBackground, p.onHeader),
              greaterThanOrEqualTo(4.5),
              reason: 'header text, $at');
          expect(_contrast(p.primary, p.surface), greaterThanOrEqualTo(3),
              reason: 'accent on a card, $at');
        }
      }
    });

    test('the choice is saved and read back; anything else is Ocean', () {
      final store = <String, Object>{};
      BCollectionTheme.setAccent(BCollectionAccent.teal,
          write: (k, v) => store[k] = v);
      expect(store, {BCollectionTheme.accentKey: 'teal'});
      expect(BCollectionColors.accent, BCollectionAccent.teal);
      expect(BCollectionColors.primary, BCollectionAccent.teal.light.primary,
          reason: 'the tokens follow at once');
      expect(BCollectionTheme.readSavedAccent((k) => store[k]),
          BCollectionAccent.teal);

      expect(BCollectionTheme.readSavedAccent((_) => null),
          BCollectionAccent.ocean);
      expect(BCollectionTheme.readSavedAccent((_) => 'neon'),
          BCollectionAccent.ocean);
      expect(
          BCollectionTheme.readSavedAccent((_) => throw StateError('no storage')),
          BCollectionAccent.ocean);
    });
  });

  testWidgets('picking a colour recolours the whole app', (tester) async {
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
    BCollectionTheme.applyFor('Collection');
    await tester.pumpAndSettle();
    expect(Theme.of(ctx).colorScheme.primary,
        BCollectionPalette.light.primary);

    BCollectionTheme.setAccent(BCollectionAccent.rose, write: (_, __) {});
    await tester.pumpAndSettle();
    expect(Theme.of(ctx).colorScheme.primary,
        BCollectionAccent.rose.light.primary);
    expect(Theme.of(ctx).appBarTheme.backgroundColor,
        BCollectionAccent.rose.light.headerBackground);
  });

  group('the Theme page', () {
    Future<({List<ThemeMode> modes, List<BCollectionAccent> accents})> pump(
        WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      final modes = <ThemeMode>[];
      final accents = <BCollectionAccent>[];
      await tester.pumpWidget(GetMaterialApp(
        theme: BCollectionTheme.light,
        home: CollectionThemeScreen(onMode: modes.add, onAccent: accents.add),
      ));
      await tester.pumpAndSettle();
      return (modes: modes, accents: accents);
    }

    testWidgets('offers every colour, the picked one marked', (tester) async {
      BCollectionColors.accent = BCollectionAccent.cocoa;
      await pump(tester);
      for (final a in BCollectionAccent.values) {
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

    testWidgets('a tap on a colour or a mode asks for it', (tester) async {
      final asked = await pump(tester);
      await tester.tap(find.byKey(const ValueKey('theme-accent-teal')));
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(asked.accents, [BCollectionAccent.teal]);
      expect(asked.modes, [ThemeMode.dark]);
    });

    test('Settings says which theme is on', () {
      BCollectionColors.accent = BCollectionAccent.graphite;
      BCollectionColors.themeMode = ThemeMode.dark;
      expect(CollectionThemeScreen.summary(), 'Graphite · Dark');
      BCollectionColors.themeMode = ThemeMode.system;
      expect(CollectionThemeScreen.summary(), 'Graphite · Follows the phone');
    });
  });
}
