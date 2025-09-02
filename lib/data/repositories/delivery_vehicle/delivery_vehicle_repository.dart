import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/delivery_vehicle_model.dart';

class DeliveryVehicleRepository extends GetxController {
  static DeliveryVehicleRepository get instance => Get.find();

  Future<List<DeliveryVehicleModel>> getALlVehicle() async {
    try {
      return [
        DeliveryVehicleModel(
            name: "Vehicle 1",
            location: const LatLng(14.5550, 121.0228),
            destination: const LatLng(14.5995, 120.9842)),
        DeliveryVehicleModel(
            name: "Vehicle 2",
            location: const LatLng(14.5600, 121.0300),
            destination: const LatLng(14.5800, 121.0500)),
        DeliveryVehicleModel(
            name: "Vehicle 3",
            location: const LatLng(14.5700, 121.0400),
            destination: const LatLng(14.5900, 121.0200)),
      ];
    } catch (e) {
      throw Exception('Something went wrong. Please try again: $e');
    }
  }
}
