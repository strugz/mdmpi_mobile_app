import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/local/dao/pick_up/pick_up_dao.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:mdmpi_mobile_app/data/repositories/pick_up/pick_up_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/request_date_scope.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pick_up_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Guards the data-loss hazard introduced by scoped fetching.
///
/// Before scoping, every fetch was a full snapshot, so the repositories could
/// safely `deleteAll()` before inserting. A scoped fetch only ever sees part of
/// the data, so wiping first would erase every other day's rows from the local
/// cache and break Local-storage mode and offline use.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('PickUpRepository.cacheRequests', () {
    late Database db;
    late PickUpRepository repository;

    PickUpModel pickUp(String id, String datePickUp, {String status = 'New'}) =>
        PickUpModel(
          id: id,
          datePickUp: datePickUp,
          status: status,
          clientId: '1',
        );

    Future<List<Map<String, Object?>>> rows() =>
        db.query('a_tblRequestPickUp', orderBy: 'RequestID');

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async => createAllTables(db),
      );
      repository = PickUpRepository();
      repository.daoForTesting = PickUpDao(db);

      // A row from an earlier day, already cached.
      await repository.cacheRequests(
        [pickUp('1', '2026-09-11')],
        scope: RequestDateScope.all,
      );
    });

    tearDown(() async => db.close());

    test('a scoped fetch keeps rows outside its date window', () async {
      await repository.cacheRequests(
        [pickUp('2', '2026-09-18')],
        scope: RequestDateScope.today,
      );

      final cached = await rows();
      expect(cached, hasLength(2),
          reason: 'last week\'s row must survive a Today-only fetch');
      expect(
        cached.map((r) => r['RequestID'].toString()),
        containsAll(<String>['1', '2']),
      );
    });

    test('an unscoped fetch still replaces the table wholesale', () async {
      await repository.cacheRequests(
        [pickUp('2', '2026-09-18')],
        scope: RequestDateScope.all,
      );

      final cached = await rows();
      expect(cached, hasLength(1),
          reason: 'a full snapshot is authoritative, so stale rows go');
      expect(cached.single['RequestID'].toString(), '2');
    });

    test('a scoped fetch still refreshes a row it did see', () async {
      await repository.cacheRequests(
        [pickUp('1', '2026-09-11', status: 'Item Prepared')],
        scope: RequestDateScope.today,
      );

      final cached = await rows();
      expect(cached, hasLength(1), reason: 'upsert, not duplicate');
      expect(cached.single['Status'], isNot('New'));
    });
  });
}
