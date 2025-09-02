import 'package:google_maps_flutter/google_maps_flutter.dart';

class DeliveryVehicleModel {
  String name;
  LatLng location;
  LatLng destination;

  DeliveryVehicleModel(
      {required this.name, required this.location, required this.destination});

  /// Empty Helper Function
  static DeliveryVehicleModel empty() =>
      DeliveryVehicleModel(name: '', location: LatLng(0, 0), destination: LatLng(0, 0));

  /// Convert model to Json structure so that you can store data
  Map<String, dynamic> toJson() {
    return {'Name': name, 'Location': location, 'Destination': destination};
  }

  /// Map Json oriented document snapshot from API to VehicleModel
  factory DeliveryVehicleModel.fromJson(Map<String, dynamic> json) {
    return DeliveryVehicleModel(
        name: json['Name'],
        location: json['Location'],
        destination: json['Destination']);
  }
}
