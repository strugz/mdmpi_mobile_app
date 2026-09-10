import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';

import 'package:mdmpi_mobile_app/features/logistics/controllers/delivery_location_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/web_socket_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/screens/delivery_location/widgets/live_deliveries_sheet.dart';

/// Live map of dispatched couriers.
///
/// The map is full-bleed; the live-deliveries sheet sits on the bottom edge
/// and pads itself for the navigation bar. Tapping a car selects it and the
/// sheet shows its card (Call / Center). The "show all" FAB rides the sheet's
/// top edge.
class LocationPageGoogle extends StatefulWidget {
  const LocationPageGoogle({super.key});

  @override
  State<LocationPageGoogle> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPageGoogle> {
  final delLocCon = Get.find<DeliveryLocationController>();

  @override
  void initState() {
    super.initState();
    Get.find<WebSocketDeliveryController>();
  }

  @override
  Widget build(BuildContext context) {
    final ws = delLocCon.webSocketController;

    return Scaffold(
      body: Obx(
        () {
          delLocCon.markerIconsReady.value;
          final sheetExtent = delLocCon.sheetExtent.value == 0
              ? LiveDeliveriesSheet.collapsedSize
              : delLocCon.sheetExtent.value;
          final sheetTop = MediaQuery.sizeOf(context).height * sheetExtent;

          // Only cars that are actually drawn belong in the list.
          final visible = WebSocketDeliveryController.visibleRequestIds(
            ws.riderLocationUpdates,
            now: DateTime.now(),
          );
          final deliveries = ws.riderLocationUpdates.values
              .where((d) => visible.contains(d.requestId))
              .toList()
            ..sort((a, b) => a.client.compareTo(b.client));

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: delLocCon.lastCameraPosition.value ??
                    const CameraPosition(
                      target: LatLng(12.8797, 121.7740), // Updated to PH
                      zoom: 13,
                    ),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                // The sheet covers the corner where Google draws its zoom
                // buttons; pinch to zoom, like the Request Transport map.
                zoomControlsEnabled: false,
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
                onTap: (_) => delLocCon.clearSelection(),
                markers: delLocCon.riderBuildMarkers(),
              ),

              // Fit every live car on screen. Sits just above the sheet edge.
              Positioned(
                right: 12,
                bottom: sheetTop + 12,
                child: FloatingActionButton.small(
                  heroTag: 'center-active-deliveries',
                  tooltip: 'Show all deliveries',
                  backgroundColor: BColors.primary,
                  foregroundColor: BColors.white,
                  onPressed: delLocCon.centerActiveDeliveries,
                  child: const Icon(Iconsax.routing),
                ),
              ),

              NotificationListener<DraggableScrollableNotification>(
                onNotification: (n) {
                  delLocCon.sheetExtent.value = n.extent;
                  return false;
                },
                child: LiveDeliveriesSheet(
                  deliveries: deliveries,
                  colorFor: (id) => ws.riderMarkerColors[id] ??
                      WebSocketDeliveryController.colorForRequestId(id),
                  selectedRequestId: delLocCon.selectedRequestId.value,
                  onSelect: delLocCon.selectDelivery,
                  onClearSelection: delLocCon.clearSelection,
                  onCall: delLocCon.callRider,
                  onCenter: delLocCon.centerDispatch,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
