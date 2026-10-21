import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/local/dao/common/client_alias_dao.dart';
import 'package:mdmpi_mobile_app/data/local/db_schema.dart';
import 'package:mdmpi_mobile_app/data/repositories/client/client_alias_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/client_matcher.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/scan/client_token_index.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/client_match_result.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/scan/scanned_client_header.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

ClientModel _c(String id, String name, [String address = 'N/A']) => ClientModel(
    id: id, name: name, address: address, contact: '', emailAddress: '');

ScannedClientHeader _h(String? name, [String? address]) =>
    ScannedClientHeader(label: 'Customer', name: name, address: address);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late ClientAliasDao dao;
  late ClientAliasRepository aliases;
  late ClientMatcher matcher;

  List<ClientModel> clients() => [
        _c('1', 'US DEPARTMENT OF VETERANS AFFAIRS', 'N/A'),
        _c('2', 'ST LUKES MEDICAL CENTER INC', 'Rizal Drive, Taguig'),
        _c('3', 'ST LUKES MEDICAL CENTER QUEZON CITY', '279 E Rodriguez Sr Ave'),
        _c('4', 'GALINATO CLINIC & HOSPITAL', ''),
        _c('5', 'QUEZON CITY GENERAL HOSPITAL', 'Seminary Road, Project 8'),
        _c('6', 'CHONG HUA HOSPITAL MANDAUE', 'Mandaue City, Cebu'),
        _c('7', 'CLINICA MANILA', '2nd Floor SM Megamall'),
      ];

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath,
        version: 1, onCreate: (db, v) async => ensureOneScanTablesForTest(db));
    dao = ClientAliasDao(db);
    aliases = ClientAliasRepository(dao: () async => dao);
    matcher = ClientMatcher(aliases: aliases);
  });

  tearDown(() async => db.close());

  group('ranking', () {
    test('normalized exact name ranks first, tagged Exact name', () async {
      final r = await matcher.match(_h('Galinato Clinic and Hospital'), clients());
      expect(r.kind, ClientMatchKind.exact);
      expect(r.candidates.first.client.id, '4');
      expect(r.candidates.first.label, 'Exact name');
      expect(r.showList, isTrue);
    });

    test('OCR digit slips still give an exact name', () async {
      final r = await matcher.match(_h('QUEZ0N C1TY GENERAL H0SPITAL'), clients());
      expect(r.kind, ClientMatchKind.exact);
      expect(r.candidates.first.client.id, '5');
    });

    test('abbreviated and misread names rank the right client first',
        () async {
      final r = await matcher.match(
          _h('U.S. Dept. of Veterams Affairs'), clients());
      expect(r.kind, ClientMatchKind.fuzzy);
      expect(r.candidates.first.client.id, '1');
      expect(r.candidates.first.score, greaterThanOrEqualTo(0.60));
      expect(r.showList, isTrue);
    });

    test('the scanned address tells two similar names apart', () async {
      final r = await matcher.match(
          _h("St. Luke's Med. Ctr.", 'Rizal Drive, Taguig City'), clients());
      expect(r.candidates.first.client.id, '2');
      expect(r.candidates[1].client.id, '3');
    });

    test('a learned alias ranks above everything, tagged Used before',
        () async {
      await aliases.remember('CHONG HUA HOSPITAL MANDAUE', '7');
      final r =
          await matcher.match(_h('CHONG HUA HOSPITAL- MANDAUE'), clients());
      expect(r.kind, ClientMatchKind.alias);
      expect(r.candidates.first.client.id, '7');
      expect(r.candidates.first.label, 'Used before');
      expect(r.candidates[1].client.id, '6', reason: 'the exact name next');
    });

    test('an alias whose client is gone is skipped and deleted', () async {
      await aliases.remember('CLINICA MANILA', 'gone');
      final r = await matcher.match(_h('Clinica Manila'), clients());
      expect(r.kind, ClientMatchKind.exact);
      expect(r.candidates.first.client.id, '7');
      await Future<void>.delayed(Duration.zero);
      expect(await dao.findByAlias('CLINICA MANILA'), isNull);
    });

    test('a weak match opens the search instead of a list', () async {
      final r = await matcher.match(_h('Manila Doctors Hospital'), clients());
      expect(r.showList, isFalse);
      expect(r.ocrName, 'Manila Doctors Hospital');
    });

    test('no name read → none', () async {
      expect((await matcher.match(_h(null), clients())).kind,
          ClientMatchKind.none);
      expect((await matcher.match(_h('  '), clients())).kind,
          ClientMatchKind.none);
      expect((await matcher.match(_h('X'), const [])).kind,
          ClientMatchKind.none);
    });

    test('at most five candidates, best first', () async {
      final many = [
        for (var i = 0; i < 9; i++) _c('$i', 'GENERAL HOSPITAL $i'),
      ];
      final r = await matcher.match(_h('General Hospital'), many);
      expect(r.candidates, hasLength(5));
      for (var i = 1; i < r.candidates.length; i++) {
        expect(r.candidates[i - 1].score,
            greaterThanOrEqualTo(r.candidates[i].score));
      }
    });
  });

  group('rare words and a clear lead (2026-10-21)', () {
    // Common words fill most client names; rare ones tell clients apart.
    final fillers = [
      for (var i = 0; i < 12; i++) _c('f$i', 'CLIENT$i MEDICAL CENTER HOSPITAL'),
    ];

    test('the client sharing the rare words ranks first', () async {
      final r = await matcher.match(_h('Red Cross Medical Center Hospital'), [
        ...fillers,
        _c('A', 'PHILIPPINE RED CROSS'),
        _c('B', 'MAKATI MEDICAL CENTER HOSPITAL'),
      ]);
      expect(r.candidates.first.client.id, 'A',
          reason: 'B shares three common words, A two rare ones');
    });

    test('a close race is never Strong, however high', () async {
      final r = await matcher.match(_h('St Lukes Medical Center'), [
        ...fillers,
        _c('G', 'ST LUKES MEDICAL CENTER GLOBAL CITY'),
        _c('Q', 'ST LUKES MEDICAL CENTER QUEZON CITY'),
      ]);
      expect(r.candidates.map((c) => c.client.id).take(2),
          unorderedEquals(['G', 'Q']));
      expect(r.candidates.every((c) => c.label == 'Possible'), isTrue);
    });

    test('a high score well ahead of the rest is Strong', () async {
      final r = await matcher.match(_h('Galinato Clinik and Hospital'), [
        ...fillers,
        ...clients(),
      ]);
      expect(r.kind, ClientMatchKind.fuzzy);
      expect(r.candidates.first.client.id, '4');
      expect(r.candidates.first.label, 'Strong');
      expect(r.candidates.skip(1).every((c) => !c.isStrong), isTrue);
    });
  });

  group('index cache', () {
    test('an unchanged list reuses the index', () async {
      final list = clients();
      await matcher.match(_h('Clinica Manila'), list);
      await matcher.match(_h('Clinica Manila'), list);
      expect(matcher.buildCount, 1);
    });

    test('a name changed in place rebuilds it', () async {
      final list = clients();
      await matcher.match(_h('Clinica Manila'), list);
      list[6].name = 'CLINICA MANILA INC';
      await matcher.match(_h('Clinica Manila'), list);
      expect(matcher.buildCount, 2);
    });

    test('an address changed in place rebuilds it', () async {
      final list = clients();
      await matcher.match(_h('Clinica Manila'), list);
      list[0].address = '1501 Roxas Boulevard';
      await matcher.match(_h('Clinica Manila'), list);
      expect(matcher.buildCount, 2);
    });

    test('same length, different content (assignAll) rebuilds it', () async {
      final list = clients();
      await matcher.match(_h('Clinica Manila'), list);
      list
        ..clear()
        ..addAll([
          for (final c in clients()) _c('${c.id}x', c.name, c.address),
        ]);
      await matcher.match(_h('Clinica Manila'), list);
      expect(matcher.buildCount, 2);
    });

    test('a list that changes during the build is not used stale', () async {
      final list = clients();
      var calls = 0;
      final m = ClientMatcher(
        aliases: aliases,
        buildIndex: (l) async {
          calls++;
          final index = ClientTokenIndex.build(l);
          if (calls == 1) l.add(_c('8', 'MAKATI MEDICAL CENTER'));
          return index;
        },
      );
      final r = await m.match(_h('Makati Medical Center'), list);
      expect(m.buildCount, 2);
      expect(r.candidates.first.client.id, '8');
    });

    test('clearCache empties it', () async {
      await matcher.match(_h('Clinica Manila'), clients());
      expect(matcher.hasCache, isTrue);
      matcher.clearCache();
      expect(matcher.hasCache, isFalse);
    });
  });
}

/// Only the alias table: the matcher needs nothing else from the database.
Future<void> ensureOneScanTablesForTest(Database db) async {
  await db.execute('CREATE TABLE ACCMST_ (ACCMID TEXT PRIMARY KEY, ACCMNM TEXT)');
  await ensureOneScanTables(db);
}
