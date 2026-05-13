import 'dart:async';

import 'package:another_telephony/telephony.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/air_sea_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pick_up_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/pull_out_model.dart';

import '../../features/logistics/models/standard_delivery_model.dart';

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

  static const Duration _smsSendConfirmationTimeout = Duration(seconds: 5);
  static const Duration _smsDeliveryConfirmationTimeout = Duration(seconds: 5);

  final Telephony _telephony;
  final _dbHelper = DatabaseHelper.instance;
  final Rxn<SmsResult> lastSmsResult = Rxn<SmsResult>();

  MessagingController({Telephony? telephony})
      : _telephony = telephony ?? Telephony.instance;

  Future<SmsResult> sendSmsMessage(
    String status,
    Object requestModel, {
    String? overrideCancelRemarks,
  }) async {
    if (!GetPlatform.isAndroid) {
      return _storeSmsResult(
        const SmsSendError(
          'SMS sending is only supported on Android devices.',
        ),
      );
    }

    try {
      final smsPayload = await _buildSmsRequestPayload(
        status,
        requestModel,
        overrideCancelRemarks: overrideCancelRemarks,
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
          : await _dbHelper
              .getUserAndManagerPhoneNumbers(smsPayload.requesterCode);

      recipients.addAll(managersPhoneNumber);

      final normalizedRecipients = _normalizeRecipients(recipients);

      if (normalizedRecipients.isEmpty) {
        return _storeSmsResult(
          const SmsSendError('No recipients available for SMS sending.'),
        );
      }

      bool? permissionsGranted = await _telephony.requestSmsPermissions;

      if (permissionsGranted != true) {
        return _storeSmsResult(
          const SmsPermissionDenied('SMS permission denied'),
        );
      }

      final String message = createMessage(status, smsPayload);

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

        BFullScreenLoader.openLoadingDialog(
            'Please wait message sending...', BImages.docerAnimation);
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
          BFullScreenLoader.stopLoading();
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
    final savedContactPhoneNumbers = await _dbHelper.getContactPhoneNumbers();
    return savedContactPhoneNumbers;
  }

  String createMessage(String status, _SmsRequestPayload requestModel) {
    final documentReferences = requestModel.documentReferences;
    final documentReferencesText =
        documentReferences.isEmpty ? 'N/A' : _formatDocumentReferencesForSms(documentReferences);
    final targetDateLine = requestModel.targetDate.isEmpty
        ? ''
        : '\nTarget Date: ${requestModel.targetDate}.';
    final completionActorLine = requestModel.completionActor.isEmpty
        ? ''
        : '${requestModel.completionActorLabel}: ${requestModel.completionActor}\n';
    final completionTimeLine = requestModel.completionAt.isEmpty
        ? ''
        : '${requestModel.completionTimeLabel}: ${requestModel.completionAt}\n';
    final completionStatus = requestModel.completionStatusLabel.isEmpty
        ? status.toUpperCase()
        : requestModel.completionStatusLabel;
    final cancellationRemarks = requestModel.cancelRemarks.isEmpty
        ? 'Not provided.'
        : requestModel.cancelRemarks;

    String message = '';
    switch (status) {
      case BTexts.statusNewRequest:
        message = '${requestModel.clientName} \n'
            'Document References:\n'
            '$documentReferencesText\n'
            'Status: Allocated and for Preparation.'
            '$targetDateLine';
        break;
      case BTexts.statusGettingSuppliesReady:
        message = '${requestModel.clientName} \n'
            'Document References:\n'
            '$documentReferencesText\n'
            'Your request is currently being processed. We are preparing the necessary supplies for your delivery.\n'
            'Status: Getting Supplies Ready.'
            '$targetDateLine';
        break;
      case BTexts.statusItemPrepared:
        message = '${requestModel.clientName} \n'
            'Document References:\n'
            '$documentReferencesText\n'
            'Status: Ready for Delivery.'
            '$targetDateLine';
        break;
      case BTexts.statusItemPacked:
      case BTexts.statusForDispatch:
      case BTexts.statusDispatch:
      case BTexts.statusInTransit:
      case BTexts.statusEndorsedToGuard:
      case BTexts.statusDropOff:
      case BTexts.statusProvincialPickUp:
      case BTexts.statusProvincialInTransit:
        message = '${requestModel.clientName} \n'
            'Document References:\n'
            '$documentReferencesText\n'
            'Status: $status.'
            '$targetDateLine';
        break;
      case BTexts.statusDoneDelivery:
      case BTexts.statusReceived:
      case BTexts.statusTakenOut:
      case BTexts.statusProvincialDelivered:
        message = '${requestModel.clientName} \n'
            '$completionActorLine'
            '$completionTimeLine'
            'Document References:\n'
            '$documentReferencesText\n'
            'Status: $completionStatus.';
        break;
      case BTexts.statusCancelled:
        message = '${requestModel.clientName} \n'
            'Document References:\n'
            '$documentReferencesText\n'
            'Status: Cancelled.\n'
            'Remarks: $cancellationRemarks';
        break;
      default:
        message = '${requestModel.clientName} \n'
            'Document References:\n'
            '$documentReferencesText\n'
            'Status: $status.'
            '$targetDateLine';
    }
    return message;
  }

  String _formatDocumentReferencesForSms(List<String> documentReferences) {
    return documentReferences.join('\n');
  }

  SmsResult _storeSmsResult(SmsResult result) {
    lastSmsResult.value = result;
    return result;
  }

  bool _requiresSmsForStatus(String status) {
    return status == BTexts.statusNewRequest ||
        status == BTexts.statusGettingSuppliesReady ||
        status == BTexts.statusItemPrepared ||
        status == BTexts.statusDoneDelivery ||
        status == BTexts.statusCancelled ||
        status == BTexts.statusItemPacked ||
        status == BTexts.statusReceived ||
        status == BTexts.statusInTransit ||
        status == BTexts.statusTakenOut ||
        status == BTexts.statusEndorsedToGuard ||
        status == BTexts.statusForDispatch ||
        status == BTexts.statusDispatch ||
        status == BTexts.statusDropOff ||
        status == BTexts.statusProvincialPickUp ||
        status == BTexts.statusProvincialInTransit ||
        status == BTexts.statusProvincialDelivered;
  }

  Future<_SmsRequestPayload?> _buildSmsRequestPayload(String status, Object requestModel, {String? overrideCancelRemarks,}) async {
    final normalizedCancelRemarks = overrideCancelRemarks?.trim() ?? '';

    switch (requestModel) {
      case StandardDeliveryModel model:
        final cancelRemarks = normalizedCancelRemarks.isNotEmpty
            ? normalizedCancelRemarks
            : status == BTexts.statusCancelled
                ? (await _dbHelper.getRequestRemarks(model.id)).remarks
                : model.cancelRemarks.remarks;

        return _SmsRequestPayload(
          requestId: model.id,
          requesterCode: model.requestBy,
          clientName: model.client.name,
          documentReferences: model.documentReference,
          targetDate: model.deliveryDate,
          completionActor: model.receiver,
          completionActorLabel: 'Received By',
          completionAt: model.deliveredEndAt,
          completionTimeLabel: 'Date Time Received',
          cancelRemarks: cancelRemarks,
          completionStatusLabel:
              model.documentReference.any((reference) =>
                      reference.toUpperCase().contains('PULL OUT'))
                  ? 'PULLED OUT'
                  : 'DELIVERED',
        );
      case PickUpModel model:
        return _SmsRequestPayload(
          requestId: model.id,
          requesterCode: model.createdBy,
          clientName: model.client.name,
          documentReferences: model.documentReference,
          targetDate: model.datePickUp,
          completionActor: model.receivedBy,
          completionActorLabel: 'Received By',
          completionAt: model.updatedAt,
          completionTimeLabel: 'Date Time Updated',
          cancelRemarks:
              normalizedCancelRemarks.isNotEmpty ? normalizedCancelRemarks : model.remarks,
          completionStatusLabel: 'RECEIVED',
        );
      case PullOutModel model:
        final isStockReceive = model.formCategoryId == '9';
        return _SmsRequestPayload(
          requestId: model.id,
          requesterCode:
              model.requestedBy.isNotEmpty ? model.requestedBy : model.createdBy,
          clientName: model.client.name,
          documentReferences: model.documentReference,
          targetDate: model.pullOutDate,
          completionActor: model.releasedBy,
          completionActorLabel: 'Released By',
          completionAt: model.pullOutDateEndAt,
          completionTimeLabel: 'Date Time Completed',
          cancelRemarks: normalizedCancelRemarks.isNotEmpty
              ? normalizedCancelRemarks
              : model.cancelRemarks.remarks,
          completionStatusLabel:
              isStockReceive ? 'STOCK RECEIVED' : 'TAKEN OUT',
        );
      case AirSeaModel model:
        return _SmsRequestPayload(
          requestId: model.id,
          requesterCode: model.createdBy,
          clientName: model.client.name,
          documentReferences: model.documentReference,
          targetDate: model.datePickUp,
          completionActor: _resolveAirSeaCompletionActor(status, model),
          completionActorLabel: _resolveAirSeaCompletionActorLabel(status),
          completionAt: _resolveAirSeaCompletionTime(status, model),
          completionTimeLabel: _resolveAirSeaCompletionTimeLabel(status),
          cancelRemarks: normalizedCancelRemarks.isNotEmpty
              ? normalizedCancelRemarks
              : model.cancelRemarks.remarks,
          completionStatusLabel: _resolveAirSeaCompletionStatusLabel(status),
        );
      default:
        return null;
    }
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
      await _telephony.sendSms(
        to: phoneNumber,
        message: message,
        isMultipart: message.length > 160,
        statusListener: (status) {
          if (status == SendStatus.SENT && !sentCompleter.isCompleted) {
            sentCompleter.complete();
          }

          if (status == SendStatus.DELIVERED &&
              !deliveredCompleter.isCompleted) {
            deliveredCompleter.complete();
          }
        },
      );

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
    final bool? isSmsCapable = await _tryGetBool(() => _telephony.isSmsCapable);
    if (isSmsCapable == false) {
      return 'This device is not capable of sending SMS messages.';
    }

    final SimState? simState = await _tryGetSimState(() => _telephony.simState);
    if (simState != null && !_isReadySimState(simState)) {
      return 'The SIM is not ready for SMS messaging '
          '(state: ${_enumLabel(simState.name)}).';
    }

    final ServiceState? serviceState =
        await _tryGetServiceState(() => _telephony.serviceState);
    if (serviceState != null && _isUnavailableServiceState(serviceState)) {
      final operatorName =
          await _tryGetString(() => _telephony.networkOperatorName);
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

  Future<ServiceState?> _tryGetServiceState(Future<ServiceState> Function() getter,) async {
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

  String _resolveAirSeaCompletionActor(String status, AirSeaModel model) {
    switch (status) {
      case BTexts.statusReceived:
        return model.receivedBy;
      case BTexts.statusEndorsedToGuard:
        return model.endorsedBy;
      case BTexts.statusDropOff:
        return model.receivedBy;
      case BTexts.statusProvincialDelivered:
        return model.provincialReceiverName;
      default:
        return model.receivedBy;
    }
  }

  String _resolveAirSeaCompletionActorLabel(String status) {
    switch (status) {
      case BTexts.statusEndorsedToGuard:
        return 'Endorsed By';
      default:
        return 'Received By';
    }
  }

  String _resolveAirSeaCompletionTime(String status, AirSeaModel model) {
    switch (status) {
      case BTexts.statusReceived:
        return model.receivedAt;
      case BTexts.statusDropOff:
        return model.dropOffAt;
      case BTexts.statusProvincialDelivered:
        return model.provincialDeliveredEndAt;
      default:
        return model.updatedAt;
    }
  }

  String _resolveAirSeaCompletionTimeLabel(String status) {
    switch (status) {
      case BTexts.statusDropOff:
        return 'Date Time Dropped Off';
      case BTexts.statusProvincialDelivered:
        return 'Date Time Delivered';
      default:
        return 'Date Time Received';
    }
  }

  String _resolveAirSeaCompletionStatusLabel(String status) {
    switch (status) {
      case BTexts.statusReceived:
        return 'RECEIVED';
      case BTexts.statusDropOff:
        return 'DROPPED OFF';
      case BTexts.statusProvincialDelivered:
        return 'PROVINCIAL DELIVERED';
      case BTexts.statusEndorsedToGuard:
        return 'ENDORSED TO GUARD';
      default:
        return status.toUpperCase();
    }
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

class _SmsRequestPayload {
  final String requestId;
  final String requesterCode;
  final String clientName;
  final List<String> documentReferences;
  final String targetDate;
  final String completionActor;
  final String completionActorLabel;
  final String completionAt;
  final String completionTimeLabel;
  final String cancelRemarks;
  final String completionStatusLabel;

  const _SmsRequestPayload({
    required this.requestId,
    required this.requesterCode,
    required this.clientName,
    required this.documentReferences,
    required this.targetDate,
    required this.completionActor,
    required this.completionActorLabel,
    required this.completionAt,
    required this.completionTimeLabel,
    required this.cancelRemarks,
    required this.completionStatusLabel,
  });
}

