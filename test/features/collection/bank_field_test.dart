import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_bank_dao.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:mdmpi_mobile_app/features/collection/models/bank_model.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/widgets/bank_field.dart';
import 'package:iconsax/iconsax.dart';
import 'package:path/path.dart' show join;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Reported from the field: the Bank field opened the keyboard instead of the
/// picker. Two separate reasons, both pinned here.

/// The real controller resolves a repository, a sync manager and the local
/// database in `onInit`. None of that is what this is about, and the widget
/// only ever reads `banks`.
class _StubController extends CollectionActivityController {
  @override
  void onInit() {}
}

const _banks = [
  BankModel(id: '3', code: 'BPI', name: 'Bank of the Philippine Islands'),
  BankModel(id: '14', code: 'MET', name: 'Metrobank'),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('the cache table', () {
    test('is added to a database that predates it', () async {
      // An install already at the current schema version: onCreate and
      // onUpgrade have both been and gone, so a table added afterwards only
      // ever arrives if something runs on open.
      final db = await openDatabase(inMemoryDatabasePath, version: 1);
      await db.execute('CREATE TABLE a_tblCollectionItems (id TEXT)');

      final before = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE name = 'a_tblCollectionBank'");
      expect(before, isEmpty, reason: 'the table this bug was about');

      await ensureCollectionTables(db);

      final after = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE name = 'a_tblCollectionBank'");
      expect(after, hasLength(1));
      await db.close();
    });

    test('survives being ensured twice, and keeps what is in it', () async {
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, _) => ensureCollectionTables(db),
      );
      final dao = CollectionBankDao(db);
      await dao.replaceAll(_banks);

      // Every open runs this, so it has to be harmless.
      await ensureCollectionTables(db);

      expect((await dao.getAll()).length, 2);
      await db.close();
    });

    test('what was downloaded is still there after a restart', () async {
      // The question this has to answer: a collector downloads the list on
      // wifi in the morning and opens the app again in the field with no
      // signal. In-memory would pass everything above and still fail here.
      final dir = await Directory.systemTemp.createTemp('banklist');
      final path = join(dir.path, 'restart.db');
      addTearDown(() => dir.delete(recursive: true));

      var db = await openDatabase(path,
          version: 1, onCreate: (db, _) => ensureCollectionTables(db));
      await CollectionBankDao(db).replaceAll(_banks);
      await db.close();

      // A cold start: nothing in memory, only what is on disk.
      db = await openDatabase(path,
          version: 1, onCreate: (db, _) => ensureCollectionTables(db));
      final restored = await CollectionBankDao(db).getAll();

      expect(restored.map((b) => b.code), containsAll(['BPI', 'MET']));
      expect(restored.firstWhere((b) => b.code == 'BPI').name,
          'Bank of the Philippine Islands');
      await db.close();
    });

    test('an empty download never wipes a list the collector can still use',
        () async {
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, _) => ensureCollectionTables(db),
      );
      final dao = CollectionBankDao(db);
      await dao.replaceAll(_banks);

      await dao.replaceAll(const []);

      expect((await dao.getAll()).length, 2);
      await db.close();
    });
  });

  group('the field', () {
    setUp(() => Get.put<CollectionActivityController>(_StubController()));
    tearDown(Get.reset);

    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BBankField(controller: TextEditingController()),
        ),
      ));
      await tester.pumpAndSettle();
    }

    bool isPicker(WidgetTester tester) =>
        tester.widget<TextFormField>(find.byType(TextFormField)).enabled &&
        find.byIcon(Iconsax.arrow_down_1).evaluate().isNotEmpty;

    testWidgets('is plain text while the list is empty', (tester) async {
      await pump(tester);

      expect(find.byIcon(Iconsax.arrow_down_1), findsNothing,
          reason: 'nothing to pick from yet, so it must still be typable');
    });

    testWidgets('becomes a picker when the list arrives after it is built',
        (tester) async {
      await pump(tester);
      expect(find.byIcon(Iconsax.arrow_down_1), findsNothing);

      // The download lands a moment after the screen opens. Read once rather
      // than watched, the field would stay plain text for the life of the
      // screen — a picker that never appears, which is what was reported.
      CollectionActivityController.instance.banks.assignAll(_banks);
      await tester.pumpAndSettle();

      expect(find.byIcon(Iconsax.arrow_down_1), findsOneWidget);
      expect(isPicker(tester), isTrue);
    });

    testWidgets('opens the picker on tap once it has a list', (tester) async {
      await pump(tester);
      CollectionActivityController.instance.banks.assignAll(_banks);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();

      expect(find.text('Select bank'), findsOneWidget);
      expect(find.text('Bank of the Philippine Islands'), findsOneWidget);
    });

    testWidgets('writes the code it was given', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BBankField(controller: controller)),
      ));
      CollectionActivityController.instance.banks.assignAll(_banks);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Metrobank'));
      await tester.pumpAndSettle();

      expect(controller.text, 'MET');
    });
  });
}
