import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/data/local/dao/collection/collection_sms_outbox_dao.dart';
import 'package:mdmpi_mobile_app/data/services/collection_sms_service.dart';

/// Settings → SMS Outbox: the day's Collection SMS, how each went, and a
/// way to send at once the ones not sent yet. The service sends them in the
/// background by itself; Send now goes to every original recipient not
/// confirmed, "not confirmed" ones included.
class CollectionSmsOutboxController extends GetxController {
  CollectionSmsOutboxController({CollectionSmsService? sms}) : _sms = sms;

  final CollectionSmsService? _sms;

  CollectionSmsService get sms => _sms ?? CollectionSmsService.instance;

  final RxList<SmsOutboxRecord> messages = <SmsOutboxRecord>[].obs;
  final RxBool isLoading = false.obs;

  /// The message being resent, or null.
  final RxnString resending = RxnString();
  final RxBool resendingAll = false.obs;

  Worker? _worker;

  @override
  void onInit() {
    super.onInit();
    _worker = ever(sms.outboxVersion, (_) => load());
    load();
  }

  @override
  void onClose() {
    _worker?.dispose();
    super.onClose();
  }

  /// Not sent yet: sending, retrying, failed, not confirmed, nobody to text.
  List<SmsOutboxRecord> get needsAttention =>
      messages.where((m) => m.needsAttention).toList();

  /// Sent today, newest first.
  List<SmsOutboxRecord> get delivered =>
      messages.where((m) => !m.needsAttention).toList();

  /// The ones Send all now can do something with.
  List<SmsOutboxRecord> get resendable => needsAttention
      .where((m) => m.unconfirmedNumbers.isNotEmpty)
      .toList();

  Future<void> load() async {
    isLoading.value = true;
    try {
      messages.assignAll(await sms.outboxMessages());
    } catch (e) {
      logDebug('CollectionSmsOutboxController.load error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<CollectionSmsOutcome?> resend(String id) async {
    if (resending.value != null || resendingAll.value) return null;
    resending.value = id;
    try {
      return await sms.resend(id);
    } finally {
      resending.value = null;
      await load();
    }
  }

  /// Sends a message that already went out again, to all its recipients.
  Future<CollectionSmsOutcome?> resendSent(String id) async {
    if (resending.value != null || resendingAll.value) return null;
    resending.value = id;
    try {
      return await sms.resendToEveryone(id);
    } finally {
      resending.value = null;
      await load();
    }
  }

  /// Every message that did not go out, one after another. Returns how many
  /// went out in full.
  Future<int> resendAll() async {
    if (resending.value != null || resendingAll.value) return 0;
    resendingAll.value = true;
    try {
      return await sms.resendAll(resendable.map((m) => m.id));
    } finally {
      resendingAll.value = false;
      await load();
    }
  }

  Future<void> discard(String id) async {
    await sms.discard(id);
    await load();
  }
}
