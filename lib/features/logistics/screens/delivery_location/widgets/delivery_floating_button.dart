import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mdmpi_mobile_app/common/widgets/custom_shapes/containers/rounded_container.dart';
import 'package:mdmpi_mobile_app/common/widgets/texts/product_title_text.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/delivery_vehicle_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/delivery_vehicle_model.dart';

class BDeliveryFloatingButton extends StatelessWidget {
  const BDeliveryFloatingButton({super.key, required this.vehicles});

  final List<DeliveryVehicleModel> vehicles;

  @override
  Widget build(BuildContext context) {
    final deliveryVehicleController = Get.find<DeliveryVehicleController>();
    return BRoundedContainer(
      width: MediaQuery.of(context).size.width * 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          BProductTitleText(title: 'On-going Delivery'),
          BRoundedContainer(
            height: 120,
            width: MediaQuery.of(context).size.width * 0.5,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: deliveryVehicleController.allVehicleDelivery.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, index) {
                final deliveryVehicle =
                    deliveryVehicleController.allVehicleDelivery[index];
                return InkWell(
                  onTap: () {
                    deliveryVehicleController.selectedVehicle.value =
                        deliveryVehicle;
                    deliveryVehicleController.selectedVehicleMarker.value =
                        MarkerId(deliveryVehicle.name);
                    deliveryVehicleController.destination.value =
                        deliveryVehicle.destination;
                    deliveryVehicleController.polylines.value
                        .clear(); // Clear existing polylines
                    deliveryVehicleController.mapController.value
                        ?.animateCamera(
                      CameraUpdate.newLatLngBounds(
                        deliveryVehicleController.selectedVehicle.value != null
                            ? LatLngBounds(
                                southwest: LatLng(
                                    min(
                                        deliveryVehicleController
                                            .selectedVehicle
                                            .value!
                                            .location
                                            .latitude,
                                        deliveryVehicleController
                                            .selectedVehicle
                                            .value!
                                            .location
                                            .longitude),
                                    min(
                                        deliveryVehicleController
                                            .selectedVehicle
                                            .value!
                                            .location
                                            .latitude,
                                        deliveryVehicleController
                                            .selectedVehicle
                                            .value!
                                            .location
                                            .longitude)),
                                northeast: LatLng(
                                    max(
                                        deliveryVehicleController
                                            .selectedVehicle
                                            .value!
                                            .location
                                            .latitude,
                                        deliveryVehicleController
                                            .selectedVehicle
                                            .value!
                                            .location
                                            .longitude),
                                    max(
                                        deliveryVehicleController
                                            .selectedVehicle
                                            .value!
                                            .location
                                            .latitude,
                                        deliveryVehicleController
                                            .selectedVehicle
                                            .value!
                                            .location
                                            .longitude)),
                              )
                            : LatLngBounds(
                                southwest: LatLng(0, 0),
                                northeast: LatLng(0, 0)),
                        100,
                      ),
                    );
                    if (deliveryVehicleController.selectedVehicle.value != null) {

                    }
                  },
                  child: Container(),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
