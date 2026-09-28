import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/models/cntmst_model.dart';
import 'package:mdmpi_mobile_app/data/models/directory_user.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/user_model.dart';

/// Loads one source of people; throws on failure (the repository catches).
typedef CntmstLoader = Future<List<CNTMSTModel>> Function();
typedef FirestoreUsersLoader = Future<List<UserModel>> Function();

/// One user directory from CNTMST and Firestore `Users` (Collection TODO
/// item 14). It feeds the Head picker (item 13) and the Done Engagement SMS
/// (item 10).
///
/// A person is in CNTMST (key `CNTMNN`), in Firestore `Users` (key
/// `initial`), or in both under the same code. Codes compare trimmed and
/// upper-cased. When a person is in both, Firestore wins for name, phone and
/// department (it is the app account, kept current by the person), and CNTMST
/// fills whatever Firestore leaves blank.
///
/// CNTMST is on the phone (downloaded with the other masters); Firestore is
/// read when Firebase is available. On Windows, where Firebase may not be
/// initialised, or when Firestore fails, the directory is CNTMST alone.
///
/// Read-only, cached in memory after the first load; [load] with
/// `refresh: true` reads both sources again.
class UserDirectoryRepository extends GetxController {
  UserDirectoryRepository({CntmstLoader? cntmst, this.firestoreUsers})
      : _cntmst = cntmst ?? _cntmstFromDatabase;

  static UserDirectoryRepository get instance => Get.find();

  final CntmstLoader _cntmst;

  /// Null when Firebase is not available: the directory is CNTMST only.
  final FirestoreUsersLoader? firestoreUsers;

  List<DirectoryUser>? _cache;

  static Future<List<CNTMSTModel>> _cntmstFromDatabase() async =>
      (await DatabaseHelper.instance.cntmstDao).getAll();

  /// Everyone, by name. A failure only when neither source could be read.
  Future<Result<List<DirectoryUser>>> load({bool refresh = false}) async {
    final cached = _cache;
    if (cached != null && !refresh) return Result.success(cached);

    List<CNTMSTModel>? cntmst;
    String? cntmstError;
    try {
      cntmst = await _cntmst();
    } catch (e) {
      cntmstError = e.toString();
      logDebug('UserDirectoryRepository: CNTMST unavailable: $e');
    }

    List<UserModel>? firestore;
    String? firestoreError;
    final loader = firestoreUsers;
    if (loader != null) {
      try {
        firestore = await loader();
      } catch (e) {
        firestoreError = e.toString();
        logDebug('UserDirectoryRepository: Firestore users unavailable: $e');
      }
    }

    if (cntmst == null && firestore == null) {
      return Result.failure(
          'Could not load the user directory: ${cntmstError ?? firestoreError ?? 'no source'}');
    }

    final merged = merge(cntmst ?? const [], firestore ?? const []);
    _cache = merged;
    logDebug('UserDirectoryRepository: ${merged.length} people '
        '(CNTMST ${cntmst?.length ?? 0}, Firestore ${firestore?.length ?? 0}'
        '${loader == null ? ', Firebase not available' : ''})');
    return Result.success(merged);
  }

  /// The person with [code], or null. Loads the directory if needed.
  Future<DirectoryUser?> find(String? code) async {
    final key = DirectoryUser.normalizeKey(code);
    if (key.isEmpty) return null;
    final result = await load();
    if (result.isFailure) return null;
    return result.value.firstWhereOrNull((u) => u.key == key);
  }

  /// The merge itself: pure, so it is tested without a database or Firebase.
  ///
  /// - CNTMST rows without a code are skipped; an inactive one (`CNTSTS` '0')
  ///   is dropped unless the same person has a Firestore account.
  /// - Firestore users without an `initial` cannot be matched to anyone and
  ///   are skipped.
  /// - Duplicate codes within one source (differing only in case or spaces)
  ///   are one person; the first non-blank value of each field is kept.
  static List<DirectoryUser> merge(
      List<CNTMSTModel> cntmst, List<UserModel> firestore) {
    final byKey = <String, _Draft>{};

    for (final row in cntmst) {
      final key = DirectoryUser.normalizeKey(row.cntmnn);
      if (key.isEmpty) continue;
      final d = byKey.putIfAbsent(key, () => _Draft(key));
      d.inCntmst = true;
      d.cntmstActive = d.cntmstActive || (row.cntsts ?? '').trim() != '0';
      d.cntmstName ??= _nonBlank(row.cntmcn) ??
          _nonBlank('${row.cntmfn ?? ''} ${row.cntmln ?? ''}');
      d.cntmstDepartment ??= _nonBlank(row.cntdpt);
      d.cntmstPhone ??= _nonBlank(row.cntnum);
    }

    for (final user in firestore) {
      final key = DirectoryUser.normalizeKey(user.initial);
      if (key.isEmpty) continue;
      final d = byKey.putIfAbsent(key, () => _Draft(key));
      d.inFirestore = true;
      d.firestoreId ??= _nonBlank(user.id);
      d.firestoreName ??= _nonBlank(user.fullName);
      d.firestoreDepartment ??= _nonBlank(user.department);
      d.firestorePhone ??= _nonBlank(user.phoneNumber);
      d.email ??= _nonBlank(user.email);
      d.username ??= _nonBlank(user.username);
    }

    final people = [
      for (final d in byKey.values)
        if (d.inFirestore || d.cntmstActive) d.build(),
    ]..sort((a, b) {
        final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        return byName != 0 ? byName : a.key.compareTo(b.key);
      });
    return people;
  }

  static String? _nonBlank(String? value) {
    final t = (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
    return t.isEmpty ? null : t;
  }
}

class _Draft {
  _Draft(this.key);

  final String key;
  bool inCntmst = false;
  bool inFirestore = false;
  bool cntmstActive = false;
  String? cntmstName, cntmstDepartment, cntmstPhone;
  String? firestoreName, firestoreDepartment, firestorePhone;
  String? firestoreId, email, username;

  DirectoryUser build() => DirectoryUser(
        key: key,
        name: firestoreName ?? cntmstName ?? key,
        department: firestoreDepartment ?? cntmstDepartment ?? '',
        phone: firestorePhone ?? cntmstPhone ?? '',
        inCntmst: inCntmst,
        inFirestore: inFirestore,
        firestoreId: firestoreId ?? '',
        email: email ?? '',
        username: username ?? '',
      );
}
