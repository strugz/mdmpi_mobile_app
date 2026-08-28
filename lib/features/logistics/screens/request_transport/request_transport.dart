import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/request_transport_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_client_search.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_dispatcher.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_route_loading_overlay.dart';

import '../../../../common/services/abstracts/i_delivery_request_controller.dart';
import '../../models/standard_delivery_model.dart';

class RequestTransport extends StatelessWidget {
  const RequestTransport({
    super.key,
    required this.request,
    required this.requestController,
  });

  final StandardDeliveryModel request;
  final IDeliveryRequestController requestController;

  @override
  Widget build(BuildContext context) {
    final reqTranController = Get.find<RequestTransportController>();

    if (requestController.currentSelectedRequest.value?.id != request.id) {
      requestController.currentSelectedRequest.value = request;
    }

    final box = GetStorage();
    final destination = box.read('destination${request.id}');

    if (destination != null) {
      reqTranController.addressTextController.text = destination;
    } else {
      reqTranController.addressTextController.text =
          request.client.address == ''
              ? request.client.name
              : request.client.address;
    }

    // Initialize route after setting the address
    WidgetsBinding.instance.addPostFrameCallback((_) {
      reqTranController.initializeRoute();
    });

    return SafeArea(
      top: false,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Obx(() {
          final currentRequest =
              requestController.currentSelectedRequest.value ?? request;

          return Stack(
            children: [
              // Map fills full screen behind the draggable sheet
              GoogleMap(
                initialCameraPosition:
                    reqTranController.currentLocation.value == LatLng(0, 0)
                        ? const CameraPosition(
                            target: LatLng(12.8797, 121.7740),
                            zoom: 14,
                          )
                        : CameraPosition(
                            target: reqTranController.currentLocation.value,
                            zoom: 14,
                          ),
                scrollGesturesEnabled: true,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                trafficEnabled: true,
                tiltGesturesEnabled: false,
                zoomControlsEnabled: false,
                onMapCreated: (controller) {
                  reqTranController.mapController.value = controller;
                  if (reqTranController.lastCameraPosition.value != null) {
                    reqTranController.mapController.value!.animateCamera(
                      CameraUpdate.newCameraPosition(
                        reqTranController.lastCameraPosition.value!,
                      ),
                    );
                  }
                },
                onCameraMove: (position) {
                  reqTranController.lastCameraPosition.value = position;
                },
                markers: reqTranController.buildMarkers(),
                polylines: reqTranController.polyLines.value,
                onTap: (LatLng tappedPoint) {
                  if (currentRequest.status != BTexts.statusForDelivery) {
                    reqTranController.selectedDestinationMarkerId.value = null;
                    reqTranController.destination.value = tappedPoint;
                    reqTranController.polyLines.value.clear();
                    reqTranController.getAddressFromCoordinates(tappedPoint);
                  }
                },
              ),

              /// Text and Text Search for mapping
              Positioned(
                top: 30.0,
                left: 10.0,
                right: 10.0,
                child: BClientSearch(),
              ),

              /// Floating user location button — positioned above initial sheet
              Positioned(
                bottom: MediaQuery.of(context).size.height * 0.45 + 16,
                right: 5,
                child: FloatingActionButton(
                  heroTag: 'request_transport_my_location',
                  backgroundColor: BColors.white,
                  onPressed: () {
                    // Once dispatched (For Delivery), the route is locked in —
                    // only recenter the camera, never clear the destination.
                    if (currentRequest.status != BTexts.statusForDelivery) {
                      reqTranController.selectedDestinationMarkerId.value =
                          null;
                      reqTranController.destination.value = LatLng(0, 0);
                      reqTranController.polyLines.value.clear();
                    }
                    reqTranController.getUserLocation();
                  },
                  child: const Icon(Icons.my_location, color: BColors.dark),
                ),
              ),

              if (currentRequest.status == BTexts.statusForDelivery)
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.45 + 88,
                  right: 5,
                  child: FloatingActionButton(
                    heroTag: 'request_transport_external_navigation',
                    tooltip: 'Open navigation',
                    backgroundColor: BColors.primary,
                    onPressed: reqTranController.openExternalNavigation,
                    child: const Icon(Icons.navigation, color: BColors.white),
                  ),
                ),

              /// Route loading overlay
              if (!reqTranController.isRouteLoaded.value)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 200,
                  child: Center(child: RouteLoadingOverlay()),
                ),

              /// Draggable bottom sheet dispatcher
              BDispatcher(requestController: requestController),
            ],
          );
        }),
      ),
    );
  }
}
