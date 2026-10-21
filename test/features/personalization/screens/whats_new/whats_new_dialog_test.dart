import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/base/utils/app_build_info.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/whats_new_prompt_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/whats_new.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/whats_new/whats_new_dialog.dart';

class _FakeStorage implements GetStorage {
  final Map<String, dynamic> data = {};

  @override
  T? read<T>(String key) => data[key] as T?;

  @override
  Future<void> write(String key, dynamic value) async {
    data[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The mandatory What's new over Home after an update.
void main() {
  tearDown(Get.reset);

  const notes = WhatsNewGroup(version: '1.2.3', items: [
    WhatsNewItem(area: 'Collection', title: 'First', detail: 'one'),
    WhatsNewItem(area: 'Logistics', title: 'Trucks', detail: 'not ours'),
    WhatsNewItem(title: 'Second', detail: 'two'),
    WhatsNewItem(area: 'Collection', title: 'Third', detail: 'three'),
  ]);

  test('a department sees its own area and the items for everyone', () {
    expect(notes.itemsFor(' Collection ').map((i) => i.title),
        ['First', 'Second', 'Third']);
    expect(
        notes.itemsFor('logistics').map((i) => i.title), ['Trucks', 'Second']);
  });

  test('the prompt only uses notes filed under the running version', () {
    final newest = BWhatsNew.groups.first;
    expect(BWhatsNew.exactly(newest.version), same(newest));
    expect(BWhatsNew.exactly('9.9.9'), isNull);
  });

  group('due', () {
    late _FakeStorage storage;
    WhatsNewPromptController controller(String version) =>
        WhatsNewPromptController(
          storage: storage,
          load: () async =>
              AppBuildInfo(appName: 'a', version: version, build: ''),
        );

    setUp(() => storage = _FakeStorage());

    test('Collection gets the running version until it is marked seen',
        () async {
      final version = BWhatsNew.groups.first.version;
      final c = controller(version);
      final due = await c.due(department: 'Collection', userId: 'u1');
      expect(due?.version, version);
      expect(due!.items.every((i) => i.area == null || i.area == 'Collection'),
          isTrue);

      await c.markSeen(version, userId: 'u1');
      expect(await c.due(department: 'Collection', userId: 'u1'), isNull);
      // Another collector on the same phone still gets it.
      expect(await c.due(department: 'Collection', userId: 'u2'), isNotNull);
    });

    test('nothing for other departments, unknown or note-less builds',
        () async {
      final version = BWhatsNew.groups.first.version;
      expect(
          await controller(version).due(department: 'Logistics', userId: 'u'),
          isNull);
      expect(await controller('').due(department: 'Collection', userId: 'u'),
          isNull);
      expect(
          await controller('9.9.9').due(department: 'Collection', userId: 'u'),
          isNull);
    });
  });

  Future<List<bool?>> open(WidgetTester tester) async {
    final results = <bool?>[];
    await tester.pumpWidget(GetMaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async => results.add(await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (_) => WhatsNewDialog(
                    group: WhatsNewGroup(
                        version: notes.version,
                        items: notes.itemsFor('Collection'))),
              )),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  testWidgets('cards come one at a time and only the last one closes',
      (tester) async {
    final results = await open(tester);
    final next = find.byKey(const ValueKey('whats-new-next'));

    expect(find.text('First'), findsOneWidget);
    expect(find.text('1 of 3'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // No way out: not the barrier, not system back.
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(WhatsNewDialog), findsOneWidget);

    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsOneWidget);
    expect(find.text('2 of 3'), findsOneWidget);

    // Back rereads; it does not skip.
    await tester.tap(find.byKey(const ValueKey('whats-new-back')));
    await tester.pumpAndSettle();
    expect(find.text('1 of 3'), findsOneWidget);

    await tester.tap(next);
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('Third'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
    expect(results, isEmpty);

    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.byType(WhatsNewDialog), findsNothing);
    expect(results, [true]);
  });
}
