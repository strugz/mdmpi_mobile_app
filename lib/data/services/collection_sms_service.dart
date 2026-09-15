import 'package:another_telephony/telephony.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_permission_service.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';

/// Sends an SMS to the Collection head(s) on each recorded collection.
///
/// Works over the cellular radio, so it functions offline (no internet needed)
/// as long as a SIM is present. Android-only: a clean no-op on Windows, matching
/// [MessagingController]. Recipients are the contacts tagged with department
/// "Collection" in the Contact Directory.
class CollectionSmsService extends GetxController {
  static CollectionSmsService get instance => Get.find();

  /// Department tag used to select Collection SMS recipients in the Contact
  /// Directory (`contacts` table).
  static const String recipientDepartment = 'Collection';

  Telephony? _telephony;
  Telephony get _telephonyInstance => _telephony ??= Telephony.instance;

  /// Fire-and-forget notification for a single collection/engagement.
  Future<void> notifyEngagement({
    required String clientName,
    required double amountCollected,
    required String outcome,
    required String collectorName,
    String documentReference = '',
  }) async {
    final ref = documentReference.isEmpty ? '' : ' (Inv $documentReference)';
    final message =
        'MDMPI Collection: $clientName$ref — $outcome, PHP ${amountCollected.toStringAsFixed(2)} '
        'collected by $collectorName.';
    await _send(message);
  }

  /// Notification for a batch collection (one cheque, several invoices).
  Future<void> notifyBatch({
    required String clientName,
    required int invoiceCount,
    required double totalAmount,
    required String collectorName,
  }) async {
    final message =
        'MDMPI Collection: $clientName — batch of $invoiceCount invoice(s), '
        'PHP ${totalAmount.toStringAsFixed(2)} collected by $collectorName.';
    await _send(message);
  }

  Future<void> _send(String message) async {
    // SMS is Android-only; silently skip on other platforms (e.g. Windows).
    if (!GetPlatform.isAndroid) {
      logDebug('CollectionSmsService: skipped (not Android)');
      return;
    }

    try {
      final recipients = await _recipients();
      if (recipients.isEmpty) {
        logDebug('CollectionSmsService: no Collection recipients configured');
        return;
      }

      final granted = await _ensurePermission();
      if (!granted) {
        logDebug('CollectionSmsService: SMS permission not granted');
        return;
      }

      final isMultipart = message.length > 160;
      for (final to in recipients) {
        try {
          await _telephonyInstance.sendSms(
            to: to,
            message: message,
            isMultipart: isMultipart,
          );
        } catch (e) {
          // One recipient failing must not block the others.
          logDebug('CollectionSmsService: send to $to failed: $e');
        }
      }
      logDebug('CollectionSmsService: sent to ${recipients.length} recipient(s)');
    } catch (e) {
      logDebug('CollectionSmsService._send error: $e');
    }
  }

  Future<List<String>> _recipients() async {
    final dao = await DatabaseHelper.instance.contactDao;
    final numbers = await dao.getPhoneNumbersByDepartment(recipientDepartment);
    return numbers.toSet().toList(growable: false);
  }

  Future<bool> _ensurePermission() async {
    if (Get.isRegistered<IPermissionService>()) {
      final permission = await Get.find<IPermissionService>().requireForFeature(
        PermissionType.sms,
        featureName: 'Collection SMS notification',
      );
      if (!permission.granted) return false;
    }
    final granted = await _telephonyInstance.requestSmsPermissions;
    return granted ?? false;
  }
}
