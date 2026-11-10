import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/theme/theme.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_theme.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/home/widgets/theme_mode_toggle.dart';

/// The Light/Dark toggle in the Home header: it shows what a tap turns on,
/// the choice is kept on the phone, and it beats the phone's own setting.

void main() {
  tearDown(() {
    BCollectionColors.debugBrightness = null;
    BCollectionColors.themeMode = ThemeMode.system;
    BCollectionTheme.debugReset();
    Get.reset();
  });

  Widget host(Widget child) => MaterialApp(
        theme: BCollectionTheme.light,
        home: Scaffold(appBar: AppBar(actions: [child])),
      );

  testWidgets('light screens offer Dark; a tap asks for dark',
      (tester) async {
    final asked = <ThemeMode>[];
    await tester.pumpWidget(
        host(CollectionThemeModeToggle(onChanged: asked.add)));

    expect(find.byIcon(Iconsax.moon), findsOneWidget);
    expect(find.byTooltip('Dark mode'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('collection-theme-toggle')));
    expect(asked, [ThemeMode.dark]);
  });

  testWidgets('dark screens offer Light; a tap asks for light',
      (tester) async {
    BCollectionColors.themeMode = ThemeMode.dark;
    final asked = <ThemeMode>[];
    await tester.pumpWidget(
        host(CollectionThemeModeToggle(onChanged: asked.add)));

    expect(find.byIcon(Iconsax.sun_1), findsOneWidget);
    expect(find.byTooltip('Light mode'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('collection-theme-toggle')));
    expect(asked, [ThemeMode.light]);
  });

  group('the choice', () {
    test('beats the phone setting', () {
      BCollectionColors.themeMode = ThemeMode.dark;
      expect(BCollectionColors.isDark, isTrue);
      expect(BCollectionColors.surface, BCollectionPalette.dark.surface);
      BCollectionColors.themeMode = ThemeMode.light;
      expect(BCollectionColors.isDark, isFalse);
    });

    test('is saved, and read back', () {
      final store = <String, Object>{};
      BCollectionTheme.setMode(ThemeMode.dark,
          write: (k, v) => store[k] = v);
      expect(store, {BCollectionTheme.themeModeKey: 'dark'});
      expect(BCollectionColors.themeMode, ThemeMode.dark);
      expect(BCollectionTheme.readSavedMode((k) => store[k]), ThemeMode.dark);

      BCollectionTheme.setMode(ThemeMode.light,
          write: (k, v) => store[k] = v);
      expect(BCollectionTheme.readSavedMode((k) => store[k]),
          ThemeMode.light);
    });

    test('none saved, or unreadable: follow the phone', () {
      expect(BCollectionTheme.readSavedMode((_) => null), ThemeMode.system);
      expect(BCollectionTheme.readSavedMode((_) => 'purple'),
          ThemeMode.system);
      expect(
          BCollectionTheme.readSavedMode((_) => throw StateError('no storage')),
          ThemeMode.system);
    });
  });

  testWidgets('tapping it turns the whole app dark, and back',
      (tester) async {
    final store = <String, Object>{};
    late BuildContext ctx;
    await tester.pumpWidget(GetMaterialApp(
      themeMode: ThemeMode.system,
      theme: BAppTheme.lightTheme,
      darkTheme: BAppTheme.darkTheme,
      home: Builder(builder: (c) {
        ctx = c;
        return Scaffold(
          appBar: AppBar(actions: [
            CollectionThemeModeToggle(
                onChanged: (m) =>
                    BCollectionTheme.setMode(m, write: (k, v) => store[k] = v)),
          ]),
        );
      }),
    ));
    BCollectionTheme.applyFor('Collection');
    await tester.pumpAndSettle();
    expect(Theme.of(ctx).scaffoldBackgroundColor,
        BCollectionPalette.light.background);

    await tester.tap(find.byKey(const ValueKey('collection-theme-toggle')));
    await tester.pumpAndSettle();
    expect(Theme.of(ctx).scaffoldBackgroundColor,
        BCollectionPalette.dark.background);
    expect(find.byIcon(Iconsax.sun_1), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('collection-theme-toggle')));
    await tester.pumpAndSettle();
    expect(Theme.of(ctx).scaffoldBackgroundColor,
        BCollectionPalette.light.background);
    expect(store[BCollectionTheme.themeModeKey], 'light');
  });

  testWidgets('Logistics is not affected by a Collection choice',
      (tester) async {
    BCollectionColors.themeMode = ThemeMode.dark;
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
    expect(BCollectionColors.themeMode, ThemeMode.system);
    expect(Theme.of(ctx).scaffoldBackgroundColor, Colors.white,
        reason: 'a light phone stays light for Logistics');
  });
}
