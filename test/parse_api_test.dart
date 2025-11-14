import 'package:flutter_test/flutter_test.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

void main() {
  test('parse sample API JSON into StandardDeliveryModel without exceptions', () {
    final List<Map<String, dynamic>> sample = [
      {
        "ID": "2025090002",
        "ClientID": "5efee5641f22272f3c7b49ba",
        "ShippingMethod": "Land",
        "DeliveryTerms": "Full",
        "DeliveryDate": "2025-09-19",
        "Preference": "Medium",
        "Status": "Item Prepared",
        "RequestBy": "JCA",
        "CreatedBy": "JCA",
        "CreatedAt": "2025-09-19 08:59:31",
        "ItemPreparedBy": "JCA",
        "DeliveredBy": "JCA",
        "ItemPreparedAt": "2025-09-19 15:06:33",
        "ItemPreparedEndAt": "2025-09-19 16:06:33",
        "DeliveredAt": null,
        "DeliveredEndAt": null,
        "MobileID": 3,
        "MobileName": "Isuzu",
        "Helper": "JCA",
        "Receiver": null,
        "TripTicketNumber": "1112223333",
        "Client": {
          "accmid": "5efee5641f22272f3c7b49ba",
          "accmsc": "PGHPLM",
          "accmnm": "Philippine General Hospital - ABG",
          "accmbc": "",
          "accmad": "University of the Philippines Manila",
          "accmph": "",
          "accmem": "",
          "accmws": "",
          "accsts": null,
          "accown": "Government"
        },
        "DocumentReference": ["DRNo.:690005196", "SINo.:700005196"],
        "CancelRemarks": null,
        "Image": null,
        "Signature": null
      },
      {
        "ID": "2025090003",
        "ClientID": "5efee5641f22272f3c7b49ba",
        "ShippingMethod": "Land",
        "DeliveryTerms": "Full",
        "DeliveryDate": "2025-09-19",
        "Preference": "Medium",
        "Status": "Cancelled",
        "RequestBy": "JCA",
        "CreatedBy": "JCA",
        "CreatedAt": "2025-09-19 08:59:52",
        "ItemPreparedBy": null,
        "DeliveredBy": null,
        "ItemPreparedAt": null,
        "ItemPreparedEndAt": null,
        "DeliveredAt": null,
        "DeliveredEndAt": null,
        "MobileID": null,
        "MobileName": null,
        "Helper": null,
        "Receiver": null,
        "TripTicketNumber": null,
        "Client": {
          "accmid": "5efee5641f22272f3c7b49ba",
          "accmsc": "PGHPLM",
          "accmnm": "Philippine General Hospital - ABG",
          "accmbc": "",
          "accmad": "University of the Philippines Manila",
          "accmph": "",
          "accmem": "",
          "accmws": "",
          "accsts": null,
          "accown": "Government"
        },
        "DocumentReference": ["DRNo.:690005196", "SINo.:700005196"],
        "CancelRemarks": null,
        "Image": null,
        "Signature": null
      },
      {
        "ID": "2025110002",
        "ClientID": null,
        "ShippingMethod": "",
        "DeliveryTerms": "",
        "DeliveryDate": null,
        "Preference": "",
        "Status": "",
        "RequestBy": "JCA",
        "CreatedBy": "",
        "CreatedAt": "2025-11-05 02:44:35",
        "ItemPreparedBy": null,
        "DeliveredBy": null,
        "ItemPreparedAt": null,
        "ItemPreparedEndAt": null,
        "DeliveredAt": null,
        "DeliveredEndAt": null,
        "MobileID": null,
        "MobileName": null,
        "Helper": null,
        "Receiver": null,
        "TripTicketNumber": null,
        "Client": null,
        "DocumentReference": ["DRNo.:690005196", "SINo.:700005196"],
        "CancelRemarks": null,
        "Image": null,
        "Signature": null
      }
    ];

    for (final item in sample) {
      final model = StandardDeliveryModel.fromJson(item);
      expect(model, isNotNull);
      // ensure id parses to non-null string
      expect(model.id, isA<String>());
    }
  });
}

