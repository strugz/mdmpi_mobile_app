import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_settings_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/pages/settings/default_area_sheet.dart';

/// Settings → Default area (Collection TODO item 15).

class _Activity extends CollectionActivityController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

void main() {
  tearDown(Get.reset);

  late Map<String, dynamic> store;

  CollectionSettingsController build() => CollectionSettingsController(
        read: (k) => store[k],
        write: (k, v) async => store[k] = v,
      );

  setUp(() => store = {});

  group('readDefaultArea', () {
    test('accepts a known code in any case, else all areas', () {
      expect(CollectionSettingsController.readDefaultArea((_) => 'ncr'), 'NCR');
      expect(CollectionSettingsController.readDefaultArea((_) => ' VIS '), 'VIS');
      expect(CollectionSettingsController.readDefaultArea((_) => 'OTHERS'),
          'OTHERS');
      expect(CollectionSettingsController.readDefaultArea((_) => 'XYZ'), '');
      expect(CollectionSettingsController.readDefaultArea((_) => null), '');
      expect(CollectionSettingsController.readDefaultArea((_) => 42), '');
      expect(
          CollectionSettingsController.readDefaultArea(
              (_) => throw StateError('no storage')),
          '');
    });
  });

  test('starts from the saved value and labels it', () {
    store[CollectionSettingsController.defaultAreaKey] = 'MIN';
    final c = build()..onInit();
    expect(c.defaultArea.value, 'MIN');
    expect(c.defaultAreaLabel, 'Mindanao');

    store.clear();
    final none = build()..onInit();
    expect(none.defaultArea.value, '');
    expect(none.defaultAreaLabel, 'All areas');
  });

  test('setDefaultArea saves and applies to the open bucket at once', () async {
    final activity = _Activity();
    Get.put<CollectionActivityController>(activity);
    final c = build()..onInit();

    await c.setDefaultArea('ncr');
    expect(store[CollectionSettingsController.defaultAreaKey], 'NCR');
    expect(activity.selectedArea.value, 'NCR');

    await c.setDefaultArea('');
    expect(store[CollectionSettingsController.defaultAreaKey], '');
    expect(activity.selectedArea.value, '');
    expect(c.defaultAreaLabel, 'All areas');
  });

  test('a storage failure keeps the choice for this session', () async {
    final c = CollectionSettingsController(
      read: (_) => null,
      write: (_, __) async => throw Exception('disk full'),
    )..onInit();
    await c.setDefaultArea('VIS');
    expect(c.defaultArea.value, 'VIS');
  });

  testWidgets('the sheet lists All areas then every territory, and pops the code',
      (tester) async {
    String? picked;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async =>
              picked = await DefaultAreaSheet.show(context, selected: 'SLN'),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('default-area-all')), findsOneWidget);
    for (final code in DefaultAreaSheet.order) {
      expect(find.byKey(ValueKey('default-area-$code')), findsOneWidget);
    }
    expect(find.text('South Luzon'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('default-area-NCR')));
    await tester.pumpAndSettle();
    expect(picked, 'NCR');

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('default-area-all')));
    await tester.pumpAndSettle();
    expect(picked, '');
  });
}
