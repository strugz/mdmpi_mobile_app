import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/helper_functions.dart';

import 'package:mdmpi_mobile_app/features/logistics/controllers/delivery_location_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/delivery_vehicle_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/web_socket_delivery_controller.dart';

class LocationPageGoogle extends StatefulWidget {
  const LocationPageGoogle({super.key});

  @override
  State<LocationPageGoogle> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPageGoogle> {
  final delLocCon = Get.find<DeliveryLocationController>();
  final delVehCon =
      Get.find<DeliveryVehicleController>(); // Inject the controller

  @override
  void initState() {
    super.initState();
    Get.find<WebSocketDeliveryController>();
  }

  @override
  Widget build(BuildContext context) {
    final dark = BHelperFunctions.isDarkMode(context);
    return Scaffold(
      drawer: Drawer(
        child: Obx(
          () => ListView(
            children: <Widget>[
              DrawerHeader(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'List of On-Going Delivery',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge!
                        .apply(color: dark ? BColors.light : BColors.black),
                  ),
                ),
              ),
              ...delVehCon.allVehicleDelivery.map(
                (vehicle) => ListTile(
                  onTap: () {
                    delLocCon.selectedVehicle.value = vehicle;
                    delLocCon.selectedVehicleMarkerId.value =
                        MarkerId(vehicle.name);
                    delLocCon.destination.value = vehicle.destination;
                    delLocCon.polylines.value.clear();

                    delLocCon.getRoute(vehicle.location, vehicle.destination);
                    delLocCon.mapController.value!.animateCamera(
                        CameraUpdate.newLatLngBounds(
                            delLocCon.getLatLngBounds(
                                vehicle.location, vehicle.destination),
                            100));
                  },
                  title: Text(vehicle.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall!
                          .apply(color: dark ? BColors.light : BColors.black)),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Obx(
        () => Stack(
          children: [
            GoogleMap(
              initialCameraPosition: delLocCon.lastCameraPosition.value ??
                  const CameraPosition(
                    target: LatLng(12.8797, 121.7740), // Updated to PH
                    zoom: 13,
                  ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              onMapCreated: (controller) {
                delLocCon.mapController.value = controller;
                if (delLocCon.lastCameraPosition.value != null) {
                  delLocCon.mapController.value!.animateCamera(
                      CameraUpdate.newCameraPosition(
                          delLocCon.lastCameraPosition.value!));
                }
              },
              onCameraMove: (position) {
                delLocCon.lastCameraPosition.value = position;
              },
              markers: delLocCon.riderBuildMarkers(),
              polylines: delLocCon.polylines.value,
            ),
          ],
        ),
      ),
    );
  }
}
