import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/base/utils/app_build_info.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/features/personalization/controller/user_controller.dart';
import 'package:mdmpi_mobile_app/features/personalization/models/whats_new.dart';
import 'package:mdmpi_mobile_app/features/personalization/screens/whats_new/whats_new_dialog.dart';

/// After login, Home opens under a mandatory What's new for the running
/// version: one card at a time, Next on each, dismissed only from the last.
/// Shown once per version for each user on the phone, and only once the walk
/// is finished, so a phone closed halfway shows it again next time.
class WhatsNewPromptController extends GetxController {
  WhatsNewPromptController({GetStorage? storage, BuildInfoLoader? load})
      : _storage = storage ?? GetStorage(),
        _load = load ?? BAppBuildInfo.current;

  final GetStorage _storage;
  final BuildInfoLoader _load;

  /// Departments that get the prompt. Collection only for now; Logistics
  /// still reads its notes on Settings → About.
  static const departments = {'collection'};

  bool _showing = false;

  static String seenKey(String userId) =>
      userId.isEmpty ? 'WhatsNewSeenVersion' : 'WhatsNewSeenVersion_$userId';

  /// The cards [userId] in [department] has still to walk through, or null.
  Future<WhatsNewGroup?> due(
      {required String department, required String userId}) async {
    if (!departments.contains(department.trim().toLowerCase())) return null;
    final info = await _load();
    if (!info.hasVersion) return null;
    final group = BWhatsNew.exactly(info.version);
    if (group == null) return null;
    if (_storage.read<String>(seenKey(userId)) == group.version) return null;
    final items = group.itemsFor(department);
    if (items.isEmpty) return null;
    return WhatsNewGroup(version: group.version, items: items);
  }

  Future<void> markSeen(String version, {required String userId}) =>
      _storage.write(seenKey(userId), version);

  /// Called once the main navigation is up (Home is the first tab).
  Future<void> showIfDue() async {
    if (_showing) return;
    _showing = true;
    try {
      final user = Get.find<UserController>().user.value;
      final group = await due(department: user.department, userId: user.id);
      if (group == null) return;
      final finished = await Get.dialog<bool>(
        WhatsNewDialog(group: group),
        barrierDismissible: false,
      );
      // Null when something else closed it (a logout): show it again later.
      if (finished == true) await markSeen(group.version, userId: user.id);
    } catch (e) {
      logDebug('WhatsNewPromptController: not shown: $e');
    } finally {
      _showing = false;
    }
  }
}
