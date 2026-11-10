import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_clock.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/unfinished/unfinished_requests.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/unfinished/unfinished_requests_reminder.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/unfinished/unfinished_request.dart';

/// Reads every Logistics request on the phone (local SQLite).
typedef UnfinishedRequestLoader = Future<List<UnfinishedRequest>> Function();

/// Who is signed in: their comma-separated roles, initial and department.
typedef UnfinishedRequestUser = ({
  String role,
  String initial,
  String department,
});

typedef UnfinishedSettingReader = dynamic Function(String key);
typedef UnfinishedSettingWriter = Future<void> Function(
    String key, dynamic value);

/// The Logistics requests this user has not seen through to a final status
/// (docs/application/UNFINISHED_REQUESTS_REMINDER_PLAN.md).
///
/// Feeds the Unfinished requests screen and keeps the 08:00 reminder in
/// line with it: every request list load calls [requestSync] (through
/// [changed]), which reloads from the phone and reschedules.
class UnfinishedRequestsController extends GetxController {
  UnfinishedRequestsController({
    required UnfinishedRequestLoader loader,
    required UnfinishedRequestUser Function() currentUser,
    BUnfinishedRequestsReminder? Function()? reminder,
    Future<void> Function()? askPermission,
    UnfinishedSettingReader? read,
    UnfinishedSettingWriter? write,
    DateTime Function()? now,
  })  : _loader = loader,
        _currentUser = currentUser,
        _reminder = reminder ?? (() => null),
        _askPermission = askPermission,
        _read = read ?? _readStorage,
        _write = write ?? _writeStorage,
        _now = now ?? DateTime.now;

  static UnfinishedRequestsController get instance => Get.find();

  /// The reminder switch, on unless turned off.
  static const String reminderKey = 'logistics.unfinishedReminder';

  /// Set once the notification permission has been asked for.
  static const String permissionAskedKey =
      'logistics.unfinishedReminder.permissionAsked';

  final UnfinishedRequestLoader _loader;
  final UnfinishedRequestUser Function() _currentUser;
  final BUnfinishedRequestsReminder? Function() _reminder;
  final Future<void> Function()? _askPermission;
  final UnfinishedSettingReader _read;
  final UnfinishedSettingWriter _write;
  final DateTime Function() _now;

  /// The Manila day (`yyyy-MM-dd`) the notification last showed at once for
  /// a user, under this prefix plus their initial. Per user, so a different
  /// login on the same phone still gets theirs.
  static const String shownOnKeyPrefix = 'logistics.unfinishedReminder.shownOn.';

  final summary = UnfinishedSummary.empty.obs;
  final isLoading = false.obs;
  final reminderOn = true.obs;

  Future<void>? _refreshing;
  bool _again = false;

  @override
  void onInit() {
    super.onInit();
    reminderOn.value = readReminderOn(_read);
  }

  /// A request list was loaded or changed: refresh in the background.
  /// Safe to call when this controller is not registered (tests, Windows
  /// screens built without it).
  static void changed() {
    if (Get.isRegistered<UnfinishedRequestsController>()) {
      Get.find<UnfinishedRequestsController>().requestSync();
    }
  }

  /// Fire-and-forget [reload].
  void requestSync() => unawaited(reload());

  /// Reload from the phone and reschedule the reminder. Calls made while
  /// one runs fold into one more run. Never throws.
  Future<void> reload() async {
    if (_refreshing != null) {
      _again = true;
      return _refreshing;
    }
    _refreshing = _refresh();
    try {
      await _refreshing;
    } finally {
      _refreshing = null;
    }
    if (_again) {
      _again = false;
      await reload();
    }
  }

  Future<void> _refresh() async {
    isLoading.value = true;
    try {
      final user = _currentUser();
      final all = _isLogistics(user.department)
          ? await _loader()
          : const <UnfinishedRequest>[];
      summary.value = BUnfinishedRequests.summarize(all,
          roleField: user.role, initial: user.initial);
    } catch (e) {
      logDebug('UnfinishedRequestsController: refresh failed: $e');
    } finally {
      isLoading.value = false;
    }
    await _syncReminder();
  }

  /// The Collection department has its own reminders; everyone else is
  /// Logistics (Service and InHouse have no requests, so count 0).
  static bool _isLogistics(String department) =>
      department.trim().toLowerCase() != 'collection';

  Future<void> _syncReminder() async {
    final reminder = _reminder();
    if (reminder == null) return;
    if (reminderOn.value && summary.value.total > 0) {
      await _askPermissionOnce();
    }
    await reminder.sync(summary.value);
    await _showOncePerDay(reminder);
  }

  /// The first load after opening the app or logging in each day (Manila):
  /// show the notification at once, on top of the 08:00 one. Marked only
  /// when it actually showed, so a day that starts with nothing unfinished
  /// still gets one once something is.
  Future<void> _showOncePerDay(BUnfinishedRequestsReminder reminder) async {
    final initial = _currentUser().initial.trim().toUpperCase();
    if (initial.isEmpty) return;
    final key = '$shownOnKeyPrefix$initial';
    final today = BReconClock.stamp(_now()).substring(0, 10);
    try {
      if (_read(key) == today) return;
      if (await reminder.showNow(summary.value)) {
        await _write(key, today);
      }
    } catch (e) {
      logDebug('UnfinishedRequestsController: show once failed: $e');
    }
  }

  /// Android 13+ needs the notification permission. Asked once, the first
  /// time there is something to remind about; a refusal only loses the
  /// notification; the list stays in Settings.
  Future<void> _askPermissionOnce() async {
    final ask = _askPermission;
    if (ask == null) return;
    try {
      if (_read(permissionAskedKey) == true) return;
      await _write(permissionAskedKey, true);
      await ask();
    } catch (e) {
      logDebug('UnfinishedRequestsController: permission ask failed: $e');
    }
  }

  /// Save the reminder switch, and schedule or cancel at once.
  Future<void> setReminderOn(bool on) async {
    reminderOn.value = on;
    try {
      await _write(reminderKey, on);
    } catch (e) {
      logDebug('UnfinishedRequestsController: could not save switch: $e');
    }
    await _syncReminder();
  }

  /// The saved switch; on when never set or unreadable. Static so the
  /// reminder can read it without this controller being alive.
  static bool readReminderOn(UnfinishedSettingReader read) {
    try {
      return read(reminderKey) != false;
    } catch (_) {
      return true;
    }
  }

  /// [readReminderOn] from the phone's storage.
  static bool reminderOnInStorage() => readReminderOn(_readStorage);

  static dynamic _readStorage(String key) => GetStorage().read(key);
  static Future<void> _writeStorage(String key, dynamic value) =>
      GetStorage().write(key, value);
}
