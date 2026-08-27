import 'package:mdmpi_mobile_app/data/models/inventory_item_model.dart';
import 'package:mdmpi_mobile_app/data/services/sms/sms_request_payload.dart';

class SmsPayloadFixtures {
  static SmsRequestPayload base({
    String targetDate = '2026-05-13',
    String cancelRemarks = '',
    String completionActor = 'John Doe',
    String completionActorLabel = 'Received By',
    String completionAt = '2026-05-13 10:00',
    String completionTimeLabel = 'Date Time Received',
    String completionStatusLabel = 'DELIVERED',
    List<InventoryItemModel> inventoryItems = const [],
  }) {
    return SmsRequestPayload(
      requestId: 'REQ-001',
      requesterCode: 'USR-001',
      clientName: 'Test Client',
      documentReferences: const <String>['DR-1001', 'DR-1002'],
      targetDate: targetDate,
      completionActor: completionActor,
      completionActorLabel: completionActorLabel,
      completionAt: completionAt,
      completionTimeLabel: completionTimeLabel,
      cancelRemarks: cancelRemarks,
      completionStatusLabel: completionStatusLabel,
      inventoryItems: inventoryItems,
    );
  }

  static InventoryItemModel inventoryItemWithBatch() {
    return InventoryItemModel(
      itemCode: 'ITM-001',
      description: 'Paracetamol',
      qty: 2,
      unit: 'box',
      batches: <InventoryBatchModel>[
        InventoryBatchModel(
          batchSerial: 'B-123',
          batchQuantity: 2,
          expiryDate: '2027-01-01',
        ),
      ],
    );
  }
}

