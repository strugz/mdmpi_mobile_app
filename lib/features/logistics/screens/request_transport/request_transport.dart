import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/request_transport_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_request_transport_client_search.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/request_transport/widgets/b_request_transport_dispatcher.dart';

import '../../controllers/request_controller.dart';
import '../../models/request_model.dart';

class RequestTransport extends StatelessWidget {
  RequestTransport(
      {super.key, required this.request, required this.requestController});

  final RequestModel request;
  final RequestController requestController;

  final GlobalKey _bottomSheetKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final reqTranController = Get.find<RequestTransportController>();

    final box = GetStorage();
    final destination = box.read('destination${request.requestID}');

    if (destination != null) {
      reqTranController.addressTextController.text = destination;
    } else {
      reqTranController.addressTextController.text =
          request.client.address == ''
              ? request.client.name
              : request.client.address;
    }

    // Get the bottom padding of the device
    final double bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final bool isGestureNavigation = bottomPadding > 0.0;

    // Calculate FAB position after the layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_bottomSheetKey.currentContext != null) {
        final RenderBox renderBox =
            _bottomSheetKey.currentContext!.findRenderObject() as RenderBox;
        final bottomSheetHeight = renderBox.size.height;
        // Add some padding if you want the FAB slightly above the bottomSheet
        const fabPadding = 16.0;
        reqTranController.fabBottomOffset.value =
            bottomSheetHeight + fabPadding;
      }
    });

    return SafeArea(
      top: false,
      bottom: !isGestureNavigation,
      child: Scaffold(
        body: Obx(
          () => Stack(
            children: [
              Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: GoogleMap(
                      initialCameraPosition: reqTranController
                                  .currentLocation.value ==
                              LatLng(0, 0)
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
                        if (reqTranController.lastCameraPosition.value !=
                            null) {
                          reqTranController.mapController.value!.animateCamera(
                              CameraUpdate.newCameraPosition(
                                  reqTranController.lastCameraPosition.value!));
                        }
                      },
                      onCameraMove: (position) {
                        reqTranController.lastCameraPosition.value = position;
                      },
                      markers: reqTranController.buildMarkers(),
                      polylines: reqTranController.polyLines.value,
                      onTap: (LatLng tappedPoint) {
                        if (request.status != "For Delivery") {
                          reqTranController.selectedDestinationMarkerId.value =
                              null;
                          reqTranController.destination.value = tappedPoint;
                          reqTranController.polyLines.value.clear();
                          reqTranController
                              .getAddressFromCoordinates(tappedPoint);
                        }
                      },
                    ),
                  ),
                ],
              ),

              /// Text and Text Search for mapping
              Positioned(
                top: 30.0, //changed from 10 to 0
                left: 10.0, //changed from 10 to 0
                right: 10.0,
                child: BRequestTransportClientSearch(),
              ),

              /// Floating user location button
              Positioned(
                bottom: reqTranController.fabBottomOffset.value,
                right: 5,
                child: FloatingActionButton(
                  backgroundColor: BColors.white,
                  onPressed: () {
                    reqTranController.selectedDestinationMarkerId.value = null;
                    reqTranController.destination.value = LatLng(0, 0);
                    reqTranController.polyLines.value.clear();
                    reqTranController.getUserLocation();
                  },
                  child: const Icon(Icons.my_location, color: BColors.dark),
                ),
              ),
            ],
          ),
        ),
        resizeToAvoidBottomInset: true,
        bottomSheet: BRequestTransportDispatcher(key: _bottomSheetKey),
      ),
    );
  }
}
