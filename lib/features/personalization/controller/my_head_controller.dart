import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/result.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/models/directory_user.dart';
import 'package:mdmpi_mobile_app/data/repositories/user/user_directory_repository.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/user_model.dart';

typedef DirectoryLoader = Future<Result<List<DirectoryUser>>> Function(
    {bool refresh});
typedef HeadSaver = Future<void> Function(
    {required String key, required String name});
typedef SuggestedHeadLoader = Future<String?> Function(String ownCode);

/// Settings → *My Head* (Collection TODO item 13): the user picks who their
/// Head is from the user directory (item 14).
///
/// The choice is saved on the user's Firestore doc and cached with the user,
/// so it follows them to another phone and still reads offline. The Done
/// Engagement SMS (item 10) goes to this person.
///
/// When nothing is chosen, the first manager in the user's CNTMST `CNTTGP`
/// hierarchy is offered as a suggestion; it is not the Head until the user
/// confirms it.
class MyHeadController extends GetxController {
  MyHeadController({
    DirectoryLoader? directory,
    HeadSaver? save,
    UserModel Function()? currentUser,
    SuggestedHeadLoader? suggestedHeadKey,
  })  : _directory = directory ?? _directoryFromRepository,
        _save = save ?? _saveOnUser,
        _currentUser = currentUser ?? _userFromController,
        _suggestedHeadKey = suggestedHeadKey ?? _suggestedFromCntmst;

  static MyHeadController get instance => Get.find();

  final DirectoryLoader _directory;
  final HeadSaver _save;
  final UserModel Function() _currentUser;
  final SuggestedHeadLoader _suggestedHeadKey;

  /// Everyone in the directory, by name.
  final people = <DirectoryUser>[].obs;

  /// The current search text; [filtered] follows it.
  final query = ''.obs;

  /// The chosen Head, or null when none is chosen.
  final head = Rxn<DirectoryUser>();

  /// The Head as saved (key and name) when the directory does not list the
  /// person any more, so the choice is still shown and can be cleared.
  final savedHeadName = ''.obs;
  final savedHeadKey = ''.obs;

  /// From the CNTMST hierarchy, only while nothing is chosen.
  final suggestion = Rxn<DirectoryUser>();

  final isLoading = false.obs;
  final isSaving = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// People matching [query] on name, code or department; everyone when the
  /// query is blank. The chosen Head is listed too (marked in the UI).
  List<DirectoryUser> get filtered {
    final q = query.value.trim().toLowerCase();
    if (q.isEmpty) return people;
    return people
        .where((u) =>
            u.name.toLowerCase().contains(q) ||
            u.key.toLowerCase().contains(q) ||
            u.department.toLowerCase().contains(q))
        .toList();
  }

  bool get hasHead => savedHeadKey.value.isNotEmpty;

  /// The name to show for the Head: the directory's current name when the
  /// person is listed, else the name saved with the choice.
  String get headDisplayName => head.value?.name ?? savedHeadName.value;

  bool isHead(DirectoryUser u) => u.key == savedHeadKey.value;

  Future<void> load({bool refresh = false}) async {
    isLoading.value = true;
    error.value = null;
    try {
      final user = _currentUser();
      savedHeadKey.value = DirectoryUser.normalizeKey(user.headKey);
      savedHeadName.value = user.headName.trim();

      final result = await _directory(refresh: refresh);
      if (result.isFailure) {
        error.value = result.error;
        people.clear();
      } else {
        people.assignAll(result.value);
      }
      head.value = _find(savedHeadKey.value);

      suggestion.value = null;
      if (!hasHead) {
        final code = await _suggestedHeadKey(user.initial);
        final key = DirectoryUser.normalizeKey(code);
        if (key.isNotEmpty &&
            key != DirectoryUser.normalizeKey(user.initial)) {
          suggestion.value = _find(key);
        }
      }
    } catch (e) {
      logDebug('MyHeadController.load error: $e');
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void search(String text) => query.value = text;

  /// Make [person] the Head. Returns null on success, else a message.
  Future<String?> choose(DirectoryUser person) =>
      _persist(key: person.key, name: person.name);

  /// Remove the choice. Returns null on success, else a message.
  Future<String?> clear() => _persist(key: '', name: '');

  Future<String?> _persist({required String key, required String name}) async {
    if (isSaving.value) return null;
    isSaving.value = true;
    try {
      await _save(key: key, name: name);
      savedHeadKey.value = key;
      savedHeadName.value = name;
      head.value = _find(key);
      if (hasHead) suggestion.value = null;
      return null;
    } catch (e) {
      logDebug('MyHeadController.save error: $e');
      return e.toString();
    } finally {
      isSaving.value = false;
    }
  }

  DirectoryUser? _find(String key) =>
      key.isEmpty ? null : people.firstWhereOrNull((u) => u.key == key);

  // --- defaults: the real app wiring ---

  static Future<Result<List<DirectoryUser>>> _directoryFromRepository(
          {bool refresh = false}) =>
      UserDirectoryRepository.instance.load(refresh: refresh);

  static Future<void> _saveOnUser(
          {required String key, required String name}) =>
      UserController.instance.setHead(key: key, name: name);

  static UserModel _userFromController() => UserController.instance.user.value;

  /// The first manager in the user's `CNTTGP` chain (`A/B/C`), skipping the
  /// company-wide `EGL` group the SMS hierarchy also skips.
  static Future<String?> _suggestedFromCntmst(String ownCode) async {
    if (ownCode.trim().isEmpty) return null;
    final dao = await DatabaseHelper.instance.cntmstDao;
    final row = await dao.getByCode(ownCode);
    return firstManagerOf(row?.cnttgp);
  }

  /// Pure: the first non-`EGL` segment of a `CNTTGP` chain, or null.
  static String? firstManagerOf(String? hierarchy) {
    for (final segment in (hierarchy ?? '').split('/')) {
      final code = segment.trim();
      if (code.isNotEmpty && code.toUpperCase() != 'EGL') return code;
    }
    return null;
  }
}
