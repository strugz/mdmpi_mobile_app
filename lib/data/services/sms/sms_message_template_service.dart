import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';
import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/data/services/sms/sms_request_payload.dart';

/// Builds SMS text from status and payload.
class SmsMessageTemplateService {
  String createMessage(String status, SmsRequestPayload payload) {
    final documentReferencesText = payload.documentReferences.isEmpty
        ? 'N/A'
        : formatDocumentReferencesForSms(payload.documentReferences);
    final targetDateLine =
        payload.targetDate.isEmpty ? '' : '\nTarget Date: ${payload.targetDate}.';
    final completionActorLine = payload.completionActor.isEmpty
        ? ''
        : '${payload.completionActorLabel}: ${payload.completionActor}\n';
    final completionTimeLine = payload.completionAt.isEmpty
        ? ''
        : '${payload.completionTimeLabel}: ${formatTimeForSms(payload.completionAt)}\n';
    final dispatchTimeLine = payload.dispatchAt.isEmpty
        ? ''
        : '\nDispatched At: ${formatTimeForSms(payload.dispatchAt)}.';
    final completionStatus = payload.completionStatusLabel.isEmpty
        ? status.toUpperCase()
        : payload.completionStatusLabel;
    final cancellationRemarks =
        payload.cancelRemarks.isEmpty ? 'Not provided.' : payload.cancelRemarks;

    final inventoryItemsText = payload.inventoryItems.isEmpty
        ? ''
        : '\nItems:\n${formatInventoryItemsForSms(payload.inventoryItems)}';

    switch (status) {
      case BTexts.statusNewRequest:
        return '${payload.clientName} \n'
            'Document References:\n'
            '$documentReferencesText\n'
            'Status: Allocated and for Preparation.'
            '$targetDateLine'
            '$inventoryItemsText';
      case BTexts.statusGettingSuppliesReady:
        return '${payload.clientName} \n'
            'Document References:\n'
            '$documentReferencesText\n'
            'Your request is currently being processed. We are preparing the '
            'necessary supplies for your delivery.\n'
            'Status: Getting Supplies Ready.'
            '$targetDateLine';
      case BTexts.statusItemPrepared:
        return '${payload.clientName} \n'
            'Document References:\n'
            '$documentReferencesText\n'
            'Status: Ready for Delivery.'
            '$targetDateLine';
      case BTexts.statusForDelivery:
        return '${payload.clientName} \n'
            'Document References:\n'
            '$documentReferencesText\n'
            'Your items are now out for delivery.\n'
            'Status: For Delivery.'
            '$dispatchTimeLine'
            '$targetDateLine';
      case BTexts.statusDispatch:
        // Air / Sea / Land courier pressed Dispatch.
        return '${payload.clientName} \n'
            'Document References:\n'
            '$documentReferencesText\n'
            'Status: $status.'
            '$dispatchTimeLine'
            '$targetDateLine';
      case BTexts.statusItemPacked:
      case BTexts.statusForDispatch:
      case BTexts.statusForPullOut:
      case BTexts.statusInTransit:
      case BTexts.statusEndorsedToGuard:
      case BTexts.statusDropOff:
      case BTexts.statusProvincialPickUp:
      case BTexts.statusProvincialInTransit:
        return '${payload.clientName} \n'
            'Document References:\n'
            '$documentReferencesText\n'
            'Status: $status.'
            '$targetDateLine';
      case BTexts.statusDoneDelivery:
      case BTexts.statusReceived:
      case BTexts.statusTakenOut:
      case BTexts.statusProvincialDelivered:
        return '${payload.clientName} \n'
            '$completionActorLine'
            '$completionTimeLine'
            'Document References:\n'
            '$documentReferencesText\n'
            'Status: $completionStatus.';
      case BTexts.statusOnHold:
        return '${payload.clientName} \n'
            'Document References:\n'
            '$documentReferencesText\n'
            'Your pull out is temporarily on hold and has been reverted to '
            'For Pull Out. It will resume shortly.\n'
            'Status: ${BTexts.statusForPullOut}.'
            '$targetDateLine';
      case BTexts.statusCancelled:
        return '${payload.clientName} \n'
            'Document References:\n'
            '$documentReferencesText\n'
            'Status: Cancelled.\n'
            'Remarks: $cancellationRemarks';
      default:
        return '${payload.clientName} \n'
            'Document References:\n'
            '$documentReferencesText\n'
            'Status: $status.'
            '$targetDateLine';
    }
  }

  /// Renders a model timestamp (`DateTime.now().toString()` or ISO-8601) as
  /// e.g. `Sep 9, 2026 03:03 PM`; falls back to the raw value if unparsable.
  /// Timestamps are stamped on the courier's phone, so they are already in
  /// the courier's local time.
  String formatTimeForSms(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    final formatted = BFormatter.formatDateWithAmPm(trimmed);
    return formatted.isEmpty ? trimmed : formatted;
  }

  String formatDocumentReferencesForSms(List<String> documentReferences) {
    return documentReferences.join('\n');
  }

  String formatInventoryItemsForSms(List<InventoryItemModel> items) {
    return items.map((item) {
      final qty = item.qty % 1 == 0
          ? item.qty.toInt().toString()
          : item.qty.toString();

      final batchLines = item.batches.map((batch) {
        final batchQty = batch.batchQuantity % 1 == 0
            ? batch.batchQuantity.toInt().toString()
            : batch.batchQuantity.toString();
        final expiryText =
            batch.expiryDate.trim().isEmpty ? '' : ', Exp: ${batch.expiryDate.trim()}';
        return '  • Batch: ${batch.batchSerial} x$batchQty$expiryText';
      }).join('\n');

      final serialText = item.serialNo.trim().isEmpty
          ? ''
          : ' S/N: ${item.serialNo.trim()}';

      final itemLine =
          '- ${item.description} (${item.referenceCode}) x$qty ${item.unit}$serialText';

      if (batchLines.isEmpty) {
        return itemLine;
      }

      return '$itemLine\n$batchLines';
    }).join('\n');
  }
}


