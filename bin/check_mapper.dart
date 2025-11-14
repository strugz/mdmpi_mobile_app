import 'dart:convert';

import 'package:mdmpi_mobile_app/features/logistics/dtos/standard_delivery_dto.dart';
import 'package:mdmpi_mobile_app/features/logistics/mappers/standard_delivery_mapper.dart';

void main() {
  final sampleJson = {
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
    "DocumentReference": [
      "DRNo.:690005196",
      "SINo.:700005196"
    ],
    "CancelRemarks": null,
    "Image": null,
    "Signature": null
  };

  final dto = StandardDeliveryDto.fromJson(sampleJson);
  print('DTO parsed: id=${dto.id}, client=${dto.client?.name}, docs=${dto.documentReference}');

  final model = StandardDeliveryMapper.fromDto(dto);
  print('Model mapped: id=${model.id}, client=${model.client.name}, image=${model.image}, signature=${model.signature}, cancelRemarks=${model.cancelRemarks.remarks}');

  final dto2 = StandardDeliveryMapper.toDto(model);
  print('DTO back: id=${dto2.id}, client=${dto2.client?.name}, mobileID=${dto2.mobileID}, docs=${dto2.documentReference}');

  final jsonFromModel = model.toJson();
  print('JSON from model: ${jsonEncode(jsonFromModel)}');
}
