import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/collection_area.dart';
import 'package:mdmpi_mobile_app/features/collection/presentation/controllers/collection_activity_controller.dart';

typedef SettingReader = dynamic Function(String key);
typedef SettingWriter = Future<void> Function(String key, dynamic value);

/// Collection preferences kept on the phone (Collection TODO item 15).
///
/// **Default area.** A collector who works one territory sets it once; the
/// bucket opens filtered to it on every launch, instead of starting at "all
/// areas" and being narrowed by hand each morning. Stored in GetStorage
/// under [defaultAreaKey] ('' = all areas). Changing it applies to the live
/// bucket at once.
class CollectionSettingsController extends GetxController {
  CollectionSettingsController({SettingReader? read, SettingWriter? write})
      : _read = read ?? _readStorage,
        _write = write ?? _writeStorage;

  static CollectionSettingsController get instance => Get.find();

  static const String defaultAreaKey = 'collection.defaultArea';

  final SettingReader _read;
  final SettingWriter _write;

  /// The saved default area code; '' when the bucket should open on all areas.
  final defaultArea = ''.obs;

  @override
  void onInit() {
    super.onInit();
    defaultArea.value = readDefaultArea(_read);
  }

  String get defaultAreaLabel => defaultArea.value.isEmpty
      ? 'All areas'
      : BCollectionArea.labelFor(defaultArea.value);

  /// Save [code] ('' clears) and apply it to the open bucket.
  Future<void> setDefaultArea(String code) async {
    final area = normalizeArea(code);
    defaultArea.value = area;
    try {
      await _write(defaultAreaKey, area);
    } catch (e) {
      logDebug('CollectionSettingsController: could not save default area: $e');
    }
    if (Get.isRegistered<CollectionActivityController>()) {
      Get.find<CollectionActivityController>().selectedArea.value = area;
    }
  }

  /// A known area code, upper-cased, or '' for anything else.
  static String normalizeArea(String? code) {
    final area = (code ?? '').trim().toUpperCase();
    return BCollectionArea.names.containsKey(area) ? area : '';
  }

  /// The saved default, validated; '' when none or unreadable. Static so
  /// [CollectionActivityController.onInit] can apply it without this
  /// controller being alive yet.
  static String readDefaultArea(SettingReader read) {
    try {
      return normalizeArea(read(defaultAreaKey)?.toString());
    } catch (_) {
      return '';
    }
  }

  static dynamic _readStorage(String key) => GetStorage().read(key);
  static Future<void> _writeStorage(String key, dynamic value) =>
      GetStorage().write(key, value);
}
