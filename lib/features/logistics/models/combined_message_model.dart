import 'package:mdmpi_mobile_app/features/logistics/models/rider_location_model.dart';

import 'notification_model.dart';

class WebSocketCombinedMessageModel {
  String message;
  RiderLocationModel locationUpdate;
  NotificationModel notificationUpdate;

  WebSocketCombinedMessageModel({
    required this.message,
    required this.locationUpdate,
    required this.notificationUpdate,
  });

  static WebSocketCombinedMessageModel empty() => WebSocketCombinedMessageModel(
        message: '',
        locationUpdate: RiderLocationModel.empty(),
        notificationUpdate: NotificationModel.empty(),
      );

  Map<String, dynamic> toJson() {
    return {
      'Message': message,
      'LocationUpdate': locationUpdate.toJson(),
      'NotificationUpdate': notificationUpdate.toJson(),
    };
  }

  factory WebSocketCombinedMessageModel.fromJson(Map<String, dynamic> json) {
    return WebSocketCombinedMessageModel(
      message: json['Message'],
      locationUpdate: RiderLocationModel.fromJson(json['LocationUpdate']),
      notificationUpdate:
          NotificationModel.fromJson(json['NotificationUpdate']),
    );
  }
}
