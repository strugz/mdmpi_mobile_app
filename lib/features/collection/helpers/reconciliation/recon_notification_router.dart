import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/routes/routes.dart';
import 'package:mdmpi_mobile_app/features/collection/helpers/reconciliation/recon_reminder_scheduler.dart';

/// Opens the case a follow-up reminder was about, when the collector taps it.
///
/// A tap while the app runs opens the case at once. A tap that launched the
/// app is held ([holdLaunch]) until the main navigation is up
/// ([openPending], from `NavigationController.onReady`), so the case opens
/// over the home screen instead of before login and routing have finished.
class BReconNotificationRouter {
  BReconNotificationRouter._();

  static String? _pending;

  /// Handles [payload] if it is a reconciliation reminder; false otherwise,
  /// so the caller keeps its own handling for other notifications.
  static bool onTap(String? payload) {
    final caseId = ReconReminderScheduler.caseIdFrom(payload);
    if (caseId == null) return false;
    _open(caseId);
    return true;
  }

  /// Keep the case of the reminder that launched the app, for [openPending].
  static void holdLaunch(String? payload) {
    final caseId = ReconReminderScheduler.caseIdFrom(payload);
    if (caseId != null) _pending = caseId;
  }

  /// Open the held case, once.
  static void openPending() {
    final caseId = _pending;
    _pending = null;
    if (caseId != null) _open(caseId);
  }

  static void _open(String caseId) {
    try {
      Get.toNamed(BRoutes.reconciliationCase, arguments: caseId);
    } catch (e) {
      logDebug('BReconNotificationRouter: could not open $caseId: $e');
    }
  }
}
