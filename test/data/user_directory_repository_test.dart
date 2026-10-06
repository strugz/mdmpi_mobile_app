import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/models/cntmst_model.dart';
import 'package:mdmpi_mobile_app/data/models/directory_user.dart';
import 'package:mdmpi_mobile_app/data/repositories/user/user_directory_repository.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/user_model.dart';

/// One user directory from CNTMST (key CNTMNN) and Firestore Users (key
/// initial): the same code for the same person (Collection TODO item 14).

CNTMSTModel _cnt(
  String? code, {
  String? full,
  String? first,
  String? last,
  String? dept,
  String? phone,
  String? status = '1',
}) =>
    CNTMSTModel(
      cntmid: 'ID-${code ?? 'none'}-${full ?? first ?? ''}',
      cntmnn: code,
      cntmcn: full,
      cntmfn: first,
      cntmln: last,
      cntdpt: dept,
      cntnum: phone,
      cntsts: status,
    );

UserModel _fs(
  String initial, {
  String first = '',
  String last = '',
  String dept = '',
  String phone = '',
  String id = '',
}) =>
    UserModel(
      id: id.isEmpty ? 'uid-$initial' : id,
      firstName: first,
      lastName: last,
      username: initial.toLowerCase(),
      email: '${initial.trim().toLowerCase()}@mdmpi.test',
      phoneNumber: phone,
      profilePicture: '',
      initial: initial,
      department: dept,
    );

void main() {
  group('merge', () {
    test(
        'one person in both sources is one entry; Firestore wins, CNTMST fills',
        () {
      final people = UserDirectoryRepository.merge(
        [
          _cnt('JCA',
              full: 'ABAOAG, JAY BRYAN',
              dept: 'COLLECTION',
              phone: '0917 000 0001')
        ],
        [_fs('jca', first: 'Jay Bryan', last: 'Abaoag', phone: '')],
      );

      final jca = people.single;
      expect(jca.key, 'JCA');
      expect(jca.name, 'Jay Bryan Abaoag', reason: 'Firestore wins for name');
      expect(jca.department, 'COLLECTION', reason: 'Firestore left it blank');
      expect(jca.phone, '0917 000 0001', reason: 'Firestore left it blank');
      expect(jca.inCntmst, isTrue);
      expect(jca.inFirestore, isTrue);
      expect(jca.firestoreId, 'uid-jca');
      expect(jca.email, 'jca@mdmpi.test');
    });

    test('Firestore phone and department win when present', () {
      final p = UserDirectoryRepository.merge(
        [_cnt('MDD', full: 'Head', dept: 'SALES', phone: '0917 111')],
        [
          _fs('MDD',
              first: 'Maria',
              last: 'Dela Cruz',
              dept: 'COLLECTION',
              phone: '0918 222')
        ],
      ).single;
      expect(p.phone, '0918 222');
      expect(p.department, 'COLLECTION');
    });

    test('codes match whatever the case or surrounding spaces', () {
      final people = UserDirectoryRepository.merge(
        [_cnt(' rdr ', full: 'R. D. Reyes')],
        [_fs('RDR  ', first: 'Rico', last: 'Reyes')],
      );
      expect(people, hasLength(1));
      expect(people.single.key, 'RDR');
    });

    test('duplicates within one source are one person, first value kept', () {
      final people = UserDirectoryRepository.merge(
        [
          _cnt('ABC', full: 'First Name', phone: ''),
          _cnt('abc', full: 'Second Name', phone: '0917 333'),
        ],
        const [],
      );
      final abc = people.single;
      expect(abc.name, 'First Name');
      expect(abc.phone, '0917 333', reason: 'the first non-blank value');
    });

    test(
        'an inactive CNTMST row is dropped unless the person has an app account',
        () {
      final people = UserDirectoryRepository.merge(
        [
          _cnt('OLD', full: 'Left The Company', status: '0'),
          _cnt('APP', full: 'Still Uses The App', status: '0'),
          _cnt('NUL', full: 'No Status', status: null),
        ],
        [_fs('APP', first: 'App', last: 'User')],
      );
      expect(people.map((p) => p.key), unorderedEquals(['APP', 'NUL']));
    });

    test('rows without a code are skipped in both sources', () {
      final people = UserDirectoryRepository.merge(
        [_cnt(null, full: 'No Code'), _cnt('  ', full: 'Blank Code')],
        [_fs('', first: 'No', last: 'Initial')],
      );
      expect(people, isEmpty);
    });

    test('a name falls back to first + last, then to the code; sorted by name',
        () {
      final people = UserDirectoryRepository.merge(
        [
          _cnt('ZED', first: 'Zed', last: 'Alpha'),
          _cnt('XYZ'),
          _cnt('BEA', full: '  Bea   Santos  '),
        ],
        const [],
      );
      expect(people.map((p) => p.name), ['Bea Santos', 'XYZ', 'Zed Alpha'],
          reason: 'blank names become the code; spaces are collapsed');
    });

    test('a Firestore-only person is kept, with no CNTMST data', () {
      final p = UserDirectoryRepository.merge(
        const [],
        [_fs('NEW', first: 'New', last: 'Hire', phone: '0919 444')],
      ).single;
      expect(p.inCntmst, isFalse);
      expect(p.hasPhone, isTrue);
    });
  });

  group('load', () {
    test('Firestore unavailable: the directory is CNTMST alone', () async {
      final repo = UserDirectoryRepository(
        cntmst: () async => [_cnt('JCA', full: 'Jay')],
        firestoreUsers: () async => throw Exception('offline'),
      );
      final result = await repo.load();
      expect(result.isSuccess, isTrue);
      expect(result.value.single.inFirestore, isFalse);
    });

    test('no Firebase at all (desktop): CNTMST alone, no error', () async {
      final repo = UserDirectoryRepository(
          cntmst: () async => [_cnt('JCA', full: 'Jay')]);
      final result = await repo.load();
      expect(result.value.map((p) => p.key), ['JCA']);
    });

    test('a failure only when neither source can be read', () async {
      final repo = UserDirectoryRepository(
        cntmst: () async => throw Exception('no db'),
        firestoreUsers: () async => throw Exception('offline'),
      );
      final result = await repo.load();
      expect(result.isFailure, isTrue);
      expect(result.error, contains('Could not load the user directory'));
    });

    test('cached after the first load; refresh reads again; find by any case',
        () async {
      var reads = 0;
      final repo = UserDirectoryRepository(cntmst: () async {
        reads++;
        return [_cnt('JCA', full: 'Jay')];
      });

      await repo.load();
      await repo.load();
      expect(reads, 1);

      await repo.load(refresh: true);
      expect(reads, 2);

      expect((await repo.find(' jca '))?.name, 'Jay');
      expect(await repo.find('nobody'), isNull);
      expect(await repo.find(''), isNull);
      expect(reads, 2, reason: 'find uses the cache');
    });
  });

  test('normalizeKey trims and upper-cases', () {
    expect(DirectoryUser.normalizeKey('  jca '), 'JCA');
    expect(DirectoryUser.normalizeKey(null), '');
  });
}
