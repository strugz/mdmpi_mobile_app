import 'dart:async';

import 'package:another_telephony/telephony.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/data/services/sms/sms_message_template_service.dart';
import 'package:mdmpi_mobile_app/data/services/sms/sms_payload_builder.dart';
import 'package:mdmpi_mobile_app/data/services/sms/sms_request_payload.dart';
import 'package:mdmpi_mobile_app/data/services/sms/sms_status_policy.dart';

sealed class SmsResult {
  const SmsResult();
}

class SmsSuccess extends SmsResult {
  final String message;
  final int attemptedRecipients;
  final int sentRecipients;
  final int deliveredRecipients;

  const SmsSuccess(
    this.message, {
    this.attemptedRecipients = 0,
    this.sentRecipients = 0,
    this.deliveredRecipients = 0,
  });
}

class SmsPermissionDenied extends SmsResult {
  final String message;

  const SmsPermissionDenied(this.message);
}

class SmsLikelyNetworkIssue extends SmsResult {
  final String message;

  const SmsLikelyNetworkIssue(this.message);
}

class SmsPartialSuccess extends SmsResult {
  final String message;
  final int attemptedRecipients;
  final int sentRecipients;
  final int deliveredRecipients;

  const SmsPartialSuccess(
    this.message, {
    required this.attemptedRecipients,
    required this.sentRecipients,
    required this.deliveredRecipients,
  });
}

class SmsSendError extends SmsResult {
  final String error;
  final bool isLikelyNetworkIssue;

  const SmsSendError(this.error, {this.isLikelyNetworkIssue = false});
}

class MessagingController extends GetxController {
  static MessagingController get instance => Get.find();

  static const Duration _smsSendConfirmationTimeout = Duration(seconds: 3);
  static const Duration _smsDeliveryConfirmationTimeout = Duration(seconds: 3);

  Telephony? _telephony;
  final SmsStatusPolicy _smsStatusPolicy;
  final SmsMessageTemplateService _smsMessageTemplateService;
  final SmsPayloadBuilder _smsPayloadBuilder;
  final bool Function()? _isAndroidChecker;
  final Future<List<String>> Function()? _contactPhoneNumbersProvider;
  final Future<List<String>> Function(String requesterCode)?
      _managerPhoneNumbersProvider;
  final Future<bool?> Function()? _smsPermissionRequester;
  final Future<void> Function({
    required String to,
    required String message,
    required bool isMultipart,
    required void Function(SendStatus status) statusListener,
  })? _smsSender;
  final Future<String?> Function()? _networkIssueChecker;
  final void Function(String text, String animation)? _openLoadingDialog;
  final void Function()? _closeLoadingDialog;
  final _dbHelper = DatabaseHelper.instance;
  final Rxn<SmsResult> lastSmsResult = Rxn<SmsResult>();

  Telephony get _telephonyInstance => _telephony ??= Telephony.instance;

  MessagingController({
    Telephony? telephony,
    SmsStatusPolicy? smsStatusPolicy,
    SmsMessageTemplateService? smsMessageTemplateService,
    SmsPayloadBuilder? smsPayloadBuilder,
    bool Function()? isAndroidChecker,
    Future<List<String>> Function()? contactPhoneNumbersProvider,
    Future<List<String>> Function(String requesterCode)?
        managerPhoneNumbersProvider,
    Future<bool?> Function()? smsPermissionRequester,
    Future<void> Function({
      required String to,
      required String message,
      required bool isMultipart,
      required void Function(SendStatus status) statusListener,
    })? smsSender,
    Future<String?> Function()? networkIssueChecker,
    void Function(String text, String animation)? openLoadingDialog,
    void Function()? closeLoadingDialog,
  })  : _telephony = telephony,
        _smsStatusPolicy = smsStatusPolicy ?? SmsStatusPolicy(),
        _smsMessageTemplateService =
            smsMessageTemplateService ?? SmsMessageTemplateService(),
        _smsPayloadBuilder = smsPayloadBuilder ??
            SmsPayloadBuilder(
              cancelRemarksResolver: (id) async =>
                  (await DatabaseHelper.instance.getRequestRemarks(id)).remarks,
            ),
        _isAndroidChecker = isAndroidChecker,
        _contactPhoneNumbersProvider = contactPhoneNumbersProvider,
        _managerPhoneNumbersProvider = managerPhoneNumbersProvider,
        _smsPermissionRequester = smsPermissionRequester,
        _smsSender = smsSender,
        _networkIssueChecker = networkIssueChecker,
        _openLoadingDialog = openLoadingDialog,
        _closeLoadingDialog = closeLoadingDialog;

  Future<SmsResult> sendSmsMessage(
    String status,
    Object requestModel, {
    String? overrideCancelRemarks,
    List<InventoryItemModel>? inventoryItems,
  }) async {
    if (!(_isAndroidChecker?.call() ?? GetPlatform.isAndroid)) {
      return _storeSmsResult(
        const SmsSendError(
          'SMS sending is only supported on Android devices.',
        ),
      );
    }

    try {
      final smsPayload = await _smsPayloadBuilder.build(
        status,
        requestModel,
        overrideCancelRemarks: overrideCancelRemarks,
        inventoryItems: inventoryItems,
      );

      if (smsPayload == null) {
        return _storeSmsResult(
          SmsSendError(
            'SMS sending is not supported for request type '
            '${requestModel.runtimeType}.',
          ),
        );
      }

      final recipients = await _resolveSmsRecipients();

      final managersPhoneNumber = smsPayload.requesterCode.isEmpty
          ? <String>[]
          : await _resolveManagerPhoneNumbers(smsPayload.requesterCode);

      recipients.addAll(managersPhoneNumber);

      final normalizedRecipients = _normalizeRecipients(recipients);

      if (normalizedRecipients.isEmpty) {
        return _storeSmsResult(
          const SmsSendError('No recipients available for SMS sending.'),
        );
      }

      bool? permissionsGranted = await _requestSmsPermissions();

      if (permissionsGranted != true) {
        return _storeSmsResult(
          const SmsPermissionDenied('SMS permission denied'),
        );
      }

      final String message = _createMessage(status, smsPayload);
      if (message.isEmpty) {
        return _storeSmsResult(
          SmsSendError('No message content for status: $status'),
        );
      }

      if (_requiresSmsForStatus(status)) {
        final likelyNetworkIssue = await _getLikelyMessagingNetworkIssue();
        if (likelyNetworkIssue != null) {
          return _storeSmsResult(SmsLikelyNetworkIssue(likelyNetworkIssue));
        }

        (_openLoadingDialog ?? BFullScreenLoader.openLoadingDialog)(
          'Please wait message sending...',
          BImages.docerAnimation,
        );
        final sendResults = <_RecipientSendResult>[];

        try {
          for (final String phoneNumber in normalizedRecipients) {
            sendResults.add(
              await _sendSmsToRecipient(
                  phoneNumber: phoneNumber, message: message),
            );
            await Future.delayed(const Duration(seconds: 1));
          }
        } finally {
          (_closeLoadingDialog ?? BFullScreenLoader.stopLoading)();
        }

        final result = _summarizeSendResults(sendResults);
        _logSmsResult(result);
        return _storeSmsResult(result);
      } else {
        return _storeSmsResult(
          const SmsSuccess('SMS not required for this status.'),
        );
      }
    } on PlatformException catch (e) {
      final result = await _classifyPlatformException(e);
      _logSmsResult(result);
      return _storeSmsResult(result);
    } catch (e) {
      final result = await _classifyUnexpectedSmsError(e);
      _logSmsResult(result);
      return _storeSmsResult(result);
    }
  }

  Future<List<String>> _resolveSmsRecipients() async {
    if (_contactPhoneNumbersProvider != null) {
      return _contactPhoneNumbersProvider();
    }
    return _dbHelper.getContactPhoneNumbers();
  }

  Future<List<String>> _resolveManagerPhoneNumbers(String requesterCode) async {
    if (_managerPhoneNumbersProvider != null) {
      return _managerPhoneNumbersProvider(requesterCode);
    }
    return _dbHelper.getUserAndManagerPhoneNumbers(requesterCode);
  }

  Future<bool?> _requestSmsPermissions() async {
    if (_smsPermissionRequester != null) {
      return _smsPermissionRequester();
    }
    return _telephonyInstance.requestSmsPermissions;
  }

  String _createMessage(String status, SmsRequestPayload payload) {
    return _smsMessageTemplateService.createMessage(status, payload);
  }

  SmsResult _storeSmsResult(SmsResult result) {
    lastSmsResult.value = result;
    return result;
  }

  bool _requiresSmsForStatus(String status) {
    return _smsStatusPolicy.requiresSmsForStatus(status);
  }

  List<String> _normalizeRecipients(List<String> recipients) {
    return recipients
        .map((phoneNumber) => phoneNumber.trim())
        .where((phoneNumber) => phoneNumber.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  Future<_RecipientSendResult> _sendSmsToRecipient({
    required String phoneNumber,
    required String message,
  }) async {
    final sentCompleter = Completer<void>();
    final deliveredCompleter = Completer<void>();

    try {
      void statusListener(SendStatus status) {
        if (status == SendStatus.SENT && !sentCompleter.isCompleted) {
          sentCompleter.complete();
        }
        if (status == SendStatus.DELIVERED && !deliveredCompleter.isCompleted) {
          deliveredCompleter.complete();
        }
      }

      if (_smsSender != null) {
        await _smsSender(
          to: phoneNumber,
          message: message,
          isMultipart: message.length > 160,
          statusListener: statusListener,
        );
      } else {
        await _telephonyInstance.sendSms(
          to: phoneNumber,
          message: message,
          isMultipart: message.length > 160,
          statusListener: statusListener,
        );
      }

      final bool sentConfirmed = await _waitForStatus(
        sentCompleter,
        _smsSendConfirmationTimeout,
      );
      final bool deliveredConfirmed = sentConfirmed
          ? await _waitForStatus(
              deliveredCompleter,
              _smsDeliveryConfirmationTimeout,
            )
          : false;

      final warning = sentConfirmed
          ? null
          : 'SMS was not confirmed as sent within 5 seconds for this phone '
              'number. This may be caused by insufficient SIM balance, '
              'carrier credit limits, or a mobile network/carrier delay.';

      return _RecipientSendResult(
        phoneNumber: phoneNumber,
        requestAccepted: true,
        sendConfirmed: sentConfirmed,
        deliveryConfirmed: deliveredConfirmed,
        issue: warning,
      );
    } on PlatformException catch (e) {
      final likelyNetworkIssue = await _getLikelyMessagingNetworkIssue();
      return _RecipientSendResult(
        phoneNumber: phoneNumber,
        requestAccepted: false,
        sendConfirmed: false,
        deliveryConfirmed: false,
        issue: likelyNetworkIssue ?? _formatPlatformException(e),
        isLikelyNetworkIssue: likelyNetworkIssue != null,
      );
    } catch (e) {
      final likelyNetworkIssue = await _getLikelyMessagingNetworkIssue();
      return _RecipientSendResult(
        phoneNumber: phoneNumber,
        requestAccepted: false,
        sendConfirmed: false,
        deliveryConfirmed: false,
        issue: likelyNetworkIssue ?? 'Unexpected SMS error: $e',
        isLikelyNetworkIssue: likelyNetworkIssue != null,
      );
    }
  }

  Future<bool> _waitForStatus(
    Completer<void> completer,
    Duration timeout,
  ) async {
    if (completer.isCompleted) {
      return true;
    }

    try {
      await completer.future.timeout(timeout);
      return true;
    } on TimeoutException {
      return false;
    }
  }

  Future<String?> _getLikelyMessagingNetworkIssue() async {
    if (_networkIssueChecker != null) {
      return _networkIssueChecker();
    }

    final bool? isSmsCapable =
        await _tryGetBool(() => _telephonyInstance.isSmsCapable);
    if (isSmsCapable == false) {
      return 'This device is not capable of sending SMS messages.';
    }

    final SimState? simState =
        await _tryGetSimState(() => _telephonyInstance.simState);
    if (simState != null && !_isReadySimState(simState)) {
      return 'The SIM is not ready for SMS messaging '
          '(state: ${_enumLabel(simState.name)}).';
    }

    final ServiceState? serviceState =
        await _tryGetServiceState(() => _telephonyInstance.serviceState);
    if (serviceState != null && _isUnavailableServiceState(serviceState)) {
      final operatorName =
          await _tryGetString(() => _telephonyInstance.networkOperatorName);
      final operatorSuffix =
          (operatorName != null && operatorName.trim().isNotEmpty)
              ? ' on ${operatorName.trim()}'
              : '';

      return 'The mobile network service appears unavailable$operatorSuffix '
          'for SMS (state: ${_enumLabel(serviceState.name)}).';
    }

    return null;
  }

  Future<bool?> _tryGetBool(Future<bool?> Function() getter) async {
    try {
      return await getter();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _tryGetString(Future<String?> Function() getter) async {
    try {
      return await getter();
    } catch (_) {
      return null;
    }
  }

  Future<SimState?> _tryGetSimState(Future<SimState> Function() getter) async {
    try {
      return await getter();
    } catch (_) {
      return null;
    }
  }

  Future<ServiceState?> _tryGetServiceState(
    Future<ServiceState> Function() getter,
  ) async {
    try {
      return await getter();
    } catch (_) {
      return null;
    }
  }

  bool _isReadySimState(SimState simState) {
    return simState == SimState.READY ||
        simState == SimState.LOADED ||
        simState == SimState.PRESENT;
  }

  bool _isUnavailableServiceState(ServiceState serviceState) {
    return serviceState == ServiceState.OUT_OF_SERVICE ||
        serviceState == ServiceState.POWER_OFF;
  }

  Future<SmsResult> _classifyPlatformException(PlatformException error) async {
    final likelyNetworkIssue = await _getLikelyMessagingNetworkIssue();
    final errorMessage = _formatPlatformException(error);

    if (likelyNetworkIssue != null) {
      return SmsLikelyNetworkIssue(
        '$likelyNetworkIssue Original error: $errorMessage',
      );
    }

    if (error.code.toLowerCase().contains('permission')) {
      return const SmsPermissionDenied('SMS permission denied');
    }

    return SmsSendError(errorMessage);
  }

  Future<SmsResult> _classifyUnexpectedSmsError(Object error) async {
    final likelyNetworkIssue = await _getLikelyMessagingNetworkIssue();
    if (likelyNetworkIssue != null) {
      return SmsLikelyNetworkIssue(
        '$likelyNetworkIssue Original error: $error',
      );
    }

    return SmsSendError('Error sending SMS: $error');
  }

  String _formatPlatformException(PlatformException error) {
    final details = [error.code, error.message]
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .join(' - ');

    return details.isEmpty ? 'Platform error while sending SMS.' : details;
  }

  SmsResult _summarizeSendResults(List<_RecipientSendResult> sendResults) {
    final attemptedRecipients = sendResults.length;
    final acceptedCount =
        sendResults.where((result) => result.requestAccepted).length;
    final sentCount =
        sendResults.where((result) => result.sendConfirmed).length;
    final deliveredCount =
        sendResults.where((result) => result.deliveryConfirmed).length;
    final failedResults = sendResults
        .where((result) => !result.requestAccepted)
        .toList(growable: false);
    final pendingConfirmationCount = acceptedCount - sentCount;

    if (failedResults.isEmpty) {
      final message = pendingConfirmationCount > 0
          ? 'SMS send request was submitted to $acceptedCount '
              'recipient(s). Send confirmation was not received within 5 '
              'seconds for $pendingConfirmationCount recipient(s). This may '
              'be caused by insufficient SIM balance, carrier credit '
              'limits, or a mobile network/carrier delay.'
          : 'SMS sent successfully to $sentCount recipient(s).';

      return SmsSuccess(
        message,
        attemptedRecipients: attemptedRecipients,
        sentRecipients: sentCount,
        deliveredRecipients: deliveredCount,
      );
    }

    final networkFailures =
        failedResults.where((result) => result.isLikelyNetworkIssue).toList();
    final issueSummary = failedResults
        .map((result) =>
            '${result.phoneNumber}: ${result.issue ?? 'Unknown issue'}')
        .join(' | ');

    if (acceptedCount == 0 && networkFailures.isNotEmpty) {
      return SmsLikelyNetworkIssue(
        'SMS sending likely failed because the messaging network is unavailable. '
        '$issueSummary',
      );
    }

    return SmsPartialSuccess(
      'SMS was submitted to $acceptedCount of $attemptedRecipients recipient(s). '
      'Failures: $issueSummary',
      attemptedRecipients: attemptedRecipients,
      sentRecipients: sentCount,
      deliveredRecipients: deliveredCount,
    );
  }

  void _logSmsResult(SmsResult result) {
    switch (result) {
      case SmsSuccess():
        logDebug('📨 SMS success: ${result.message}');
        break;
      case SmsPartialSuccess():
        logDebug('📨 SMS partial success: ${result.message}');
        break;
      case SmsLikelyNetworkIssue():
        logDebug('📨 SMS likely network issue: ${result.message}');
        break;
      case SmsPermissionDenied():
        logDebug('📨 SMS permission denied: ${result.message}');
        break;
      case SmsSendError():
        logDebug('📨 SMS send error: ${result.error}');
        break;
    }
  }

  String _enumLabel(String value) {
    return value.toLowerCase().replaceAll('_', ' ');
  }
}

class _RecipientSendResult {
  final String phoneNumber;
  final bool requestAccepted;
  final bool sendConfirmed;
  final bool deliveryConfirmed;
  final String? issue;
  final bool isLikelyNetworkIssue;

  const _RecipientSendResult({
    required this.phoneNumber,
    required this.requestAccepted,
    required this.sendConfirmed,
    required this.deliveryConfirmed,
    this.issue,
    this.isLikelyNetworkIssue = false,
  });
}
