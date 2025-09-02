import 'package:another_telephony/telephony.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/full_screen_loader.dart';

import '../../features/logistics/models/request_model.dart';

sealed class SmsResult {}

class SmsSuccess extends SmsResult {
  final String message;
  SmsSuccess(this.message);
}

class SmsPermissionDenied extends SmsResult {
  final String message;
  SmsPermissionDenied(this.message);
}

class SmsSendError extends SmsResult {
  final String error;
  SmsSendError(this.error);
}

class MessagingController extends GetxController {
  static MessagingController get instance => Get.find();

  final Telephony _telephony;

  MessagingController({Telephony? telephony})
      : _telephony = telephony ?? Telephony.instance;

  Future<SmsResult> sendSmsMessage(List<String> phoneNumbers, String status,
      RequestModel requestModel) async {
    try {
      bool? permissionsGranted = await _telephony.requestSmsPermissions;

      if (permissionsGranted != true) {
        return SmsPermissionDenied("SMS permission denied");
      }
      final String message = await createMessage(status, requestModel);

      if (message.isEmpty) {
        return SmsSendError("No message content for status: $status");
      }
      if (status == BTexts.statusNewRequest ||
          status == BTexts.statusItemPrepared ||
          status == BTexts.statusDoneDelivery) {
        BFullScreenLoader.openLoadingDialog(
            'Please wait message sending...', BImages.docerAnimation);
        for (final String phoneNumber in phoneNumbers) {
          await _telephony.sendSms(
            to: phoneNumber,
            message: message,
            isMultipart: (message.length > 160),
          );
          await Future.delayed(
            Duration(seconds: 2),
          );
        }
        BFullScreenLoader.stopLoading();
        return SmsSuccess("SMS sent successfully");
      } else {
        return SmsSuccess("SMS not required for this status.");
      }
    } catch (e) {
      return SmsSendError('Error sending SMS: $e');
    }
  }

  Future<String> createMessage(String status, RequestModel requestModel) async {
    String message = '';
    switch (status) {
      case BTexts.statusNewRequest:
        message = '${requestModel.client.name} \n'
            'Document References:\n'
            '${_formatDocumentReferencesForSms(requestModel.documentReference)}\n'
            'Status: Allocated and for Preparation.\n'
            'Target Date: ${requestModel.targetDate}.';
        break;
      case BTexts.statusItemPrepared:
        message = '${requestModel.client.name} \n'
            'Document References:\n'
            '${_formatDocumentReferencesForSms(requestModel.documentReference)}\n'
            'Status: Ready for Delivery.\n'
            'Target Date: ${requestModel.targetDate}.';
        break;
      case BTexts.statusDoneDelivery:
        message = '${requestModel.client.name} \n'
            'Received By: ${requestModel.receiver}\n'
            'Date Time Received: ${requestModel.deliveredEndAt}\n'
            'Document References:\n'
            '${_formatDocumentReferencesForSms(requestModel.documentReference)}\n'
            'Status: ${_formatDocumentReferencesForSms(requestModel.documentReference).contains('PULL OUT') == true ? 'PULLED OUT' : 'DELIVERED'}.';
        break;
    }
    return message;
  }

  String _formatDocumentReferencesForSms(List<String> documentReferences) {
    return documentReferences.join('\n');
  }
}
