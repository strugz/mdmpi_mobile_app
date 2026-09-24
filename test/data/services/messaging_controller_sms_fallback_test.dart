import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/data/services/messaging_controller.dart';
import 'package:mdmpi_mobile_app/data/services/sms/sms_message_template_service.dart';
import 'package:mdmpi_mobile_app/data/services/sms/sms_payload_builder.dart';
import 'package:mdmpi_mobile_app/data/services/sms/sms_request_payload.dart';
import 'package:mdmpi_mobile_app/data/services/sms/sms_status_policy.dart';

class _FakePayloadBuilder extends SmsPayloadBuilder {
  const _FakePayloadBuilder();

  @override
  Future<SmsRequestPayload?> build(
    String status,
    Object requestModel, {
    String? overrideCancelRemarks,
    List<InventoryItemModel>? inventoryItems,
  }) async {
    return const SmsRequestPayload(
      requestId: 'REQ-1',
      requesterCode: '',
      clientName: 'Client',
      documentReferences: <String>[],
      targetDate: '',
      completionActor: '',
      completionActorLabel: '',
      completionAt: '',
      completionTimeLabel: '',
      cancelRemarks: '',
      completionStatusLabel: '',
    );
  }
}

class _FakeTemplate extends SmsMessageTemplateService {
  @override
  String createMessage(String status, SmsRequestPayload payload) =>
      'Hello & welcome, ${payload.clientName}';
}

class _AlwaysRequiredPolicy extends SmsStatusPolicy {
  @override
  bool requiresSmsForStatus(String status) => true;
}

MessagingController _controller({
  required Future<bool> Function(List<String>, String) launcher,
  bool? permission = false,
}) {
  return MessagingController(
    smsPayloadBuilder: const _FakePayloadBuilder(),
    smsMessageTemplateService: _FakeTemplate(),
    smsStatusPolicy: _AlwaysRequiredPolicy(),
    isAndroidChecker: () => true,
    contactPhoneNumbersProvider: () async => ['09171234567', ' 09179876543 '],
    managerPhoneNumbersProvider: (_) async => [],
    smsPermissionRequester: () async => permission,
    messagingAppLauncher: launcher,
  );
}

void main() {
  test('permission refused -> hands message off to the Messages app', () async {
    List<String>? recipients;
    String? body;
    final controller = _controller(launcher: (r, m) async {
      recipients = r;
      body = m;
      return true;
    });

    final result = await controller.sendSmsMessage('Any', Object());

    expect(result, isA<SmsHandedOffToMessagingApp>());
    expect((result as SmsHandedOffToMessagingApp).recipientCount, 2);
    expect(recipients, ['09171234567', '09179876543']);
    expect(body, 'Hello & welcome, Client');
    expect(controller.lastSmsResult.value, same(result));
  });

  test('permission refused and no Messages app -> permission denied', () async {
    final controller = _controller(launcher: (_, __) async => false);

    final result = await controller.sendSmsMessage('Any', Object());

    expect(result, isA<SmsPermissionDenied>());
  });

  test('launcher throwing is treated as permission denied', () async {
    final controller =
        _controller(launcher: (_, __) async => throw StateError('boom'));

    final result = await controller.sendSmsMessage('Any', Object());

    expect(result, isA<SmsPermissionDenied>());
  });

  test('smsto URI joins recipients with ; and encodes the body', () {
    final uri = MessagingController.buildMessagingAppUri(
      ['09171234567', '09179876543'],
      'Hello & welcome',
    );

    expect(uri.scheme, 'smsto');
    expect(uri.path, '09171234567;09179876543');
    expect(uri.queryParameters['body'], 'Hello & welcome');
  });
}
