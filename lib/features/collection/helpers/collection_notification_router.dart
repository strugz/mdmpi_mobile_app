import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/routes.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_reminder_scheduler.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/upload_reminder.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/unfinished/unfinished_requests_reminder.dart';

/// Opens the screen a Collection reminder is about when the collector taps
/// it: a follow-up reminder opens its reconciliation case, the end-of-day
/// upload reminder opens Upload Collections. It also routes the Logistics
/// 08:00 unfinished-requests reminder to its list, so there is one tap path.
///
/// A tap while the app runs opens it at once. A tap that launched the app is
/// held ([holdLaunch]) until the main navigation is up ([openPending], from
/// `NavigationController.onReady`), so the screen opens over the home screen
/// instead of before login and routing have finished.
class BCollectionNotificationRouter {
  BCollectionNotificationRouter._();

  static ({String route, Object? arguments})? _pending;

  /// Where [payload] leads; null for a notification that is not ours.
  static ({String route, Object? arguments})? destinationFor(String? payload) {
    if (payload == BUploadReminder.payload) {
      return (route: BRoutes.collectionUploadOutbox, arguments: null);
    }
    if (payload == BUnfinishedRequestsReminder.payload) {
      return (route: BRoutes.unfinishedRequests, arguments: null);
    }
    final caseId = ReconReminderScheduler.caseIdFrom(payload);
    if (caseId != null) {
      return (route: BRoutes.reconciliationCase, arguments: caseId);
    }
    return null;
  }

  /// Handles [payload] if it is one of ours; false otherwise, so the caller
  /// keeps its own handling for other notifications.
  static bool onTap(String? payload) {
    final to = destinationFor(payload);
    if (to == null) return false;
    _open(to);
    return true;
  }

  /// Keep where the notification that launched the app leads, for
  /// [openPending].
  static void holdLaunch(String? payload) {
    final to = destinationFor(payload);
    if (to != null) _pending = to;
  }

  /// Open the held screen, once.
  static void openPending() {
    final to = _pending;
    _pending = null;
    if (to != null) _open(to);
  }

  static void _open(({String route, Object? arguments}) to) {
    try {
      Get.toNamed(to.route, arguments: to.arguments);
    } catch (e) {
      logDebug('BCollectionNotificationRouter: could not open ${to.route}: $e');
    }
  }
}
