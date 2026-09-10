import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/constants/image_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/call_functions.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_permission_service.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/delivery_vehicle_model.dart';

import '../../../base/utils/helpers/helper_functions.dart';
import '../../personalization/controller/user_controller.dart';
import 'web_socket_delivery_controller.dart';

class DeliveryLocationController extends GetxController {
  static DeliveryLocationController get instance => Get.find();

  final mapController = Rx<GoogleMapController?>(null);
  final currentLocation = Rx<LatLng>(LatLng(0, 0));
  final destination = Rx<LatLng>(LatLng(0, 0));
  final polylines = Rx<Set<Polyline>>({});
  final distance = Rx<String?>("");
  final eta = Rx<String?>("");
  final lastCameraPosition = Rx<CameraPosition?>(null);
  final selectedVehicleMarkerId = Rx<MarkerId?>(null);
  final selectedVehicle = Rx<DeliveryVehicleModel?>(null);
  final String _apiKey = dotenv.env['API_KEY']!;

  /// web socket variables
  final webSocketController = Get.find<WebSocketDeliveryController>();
  final RxSet<Marker> markers = <Marker>{}.obs;
  final Map<String, LatLng> previousPositions = {};
  final Map<String, Marker> updatedMarkers = {};
  final Map<String, double> markerBearings = {};
  final Map<String, BitmapDescriptor> _dispatchMarkerIcons = {};
  final markerIconsReady = false.obs;
  Worker? _riderLocationWorker;
  bool _hasCenteredInitialRiders = false;

  final userController = Get.find<UserController>();
  IPermissionService get _permissionService => Get.find<IPermissionService>();

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    getUserLocation();
    loadDispatchMarkerIcons();
    _riderLocationWorker = ever(
      webSocketController.riderLocations,
      (_) => _handleRiderLocationsChanged(),
    );
  }

  Future<void> getRoute(LatLng location, LatLng destination) async {
    if (location == LatLng(0, 0) || destination == LatLng(0, 0)) return;
    final String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${location.latitude},${location.longitude}&destination=${destination.latitude},${destination.longitude}&key=$_apiKey";

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == "OK") {
      String encodedPolyline = data["routes"][0]["overview_polyline"]["points"];
      List<LatLng> routePoints = _decodePolyline(encodedPolyline);

      polylines.value = {
        Polyline(
          polylineId: const PolylineId("route"),
          points: routePoints,
          color: Colors.blue,
          width: 5,
        ),
      };
      distance.value = data["routes"][0]["legs"][0]["distance"]["text"];
      eta.value = data["routes"][0]["legs"][0]["duration"]["text"];
    }
  }

  /// -- Camera Position to view the location and destination
  LatLngBounds getLatLngBounds(LatLng loc, LatLng des) {
    final southwest = LatLng(
      math.min(loc.latitude, des.latitude),
      math.min(loc.longitude, des.longitude),
    );

    final northeast = LatLng(
      math.max(loc.latitude, des.latitude),
      math.max(loc.longitude, des.longitude),
    );

    return LatLngBounds(southwest: southwest, northeast: northeast);
  }

  Future<void> loadDispatchMarkerIcons() async {
    for (final assetPath in BImages.riderCarVariants) {
      try {
        _dispatchMarkerIcons[assetPath] = await _loadAssetMarkerIcon(assetPath);
      } catch (e) {
        logDebug(
            'DeliveryLocation: Rider car variant "$assetPath" failed to load. Fallback car icon will be used. $e');
      }
    }

    markerIconsReady.value = true;
  }

  Future<BitmapDescriptor> _loadAssetMarkerIcon(String assetPath) {
    return BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(100, 100)),
      assetPath,
      width: 48,
      height: 48,
    );
  }

  Set<Marker> riderBuildMarkers() {
    final nextMarkers = <String, Marker>{};

    // Retire cars that stopped reporting, then draw at most one car per
    // rider — a finished request's last position must not sit under the
    // courier's current one (TODO item 17).
    webSocketController.pruneStale();
    final visible = WebSocketDeliveryController.visibleRequestIds(
      webSocketController.riderLocationUpdates,
      now: DateTime.now(),
    );
    previousPositions
        .removeWhere((id, _) => !webSocketController.riderLocations.containsKey(id));
    markerBearings
        .removeWhere((id, _) => !webSocketController.riderLocations.containsKey(id));

    webSocketController.riderLocations.forEach((requestId, position) {
      if (position.latitude == 0.0 || position.longitude == 0.0) return;
      if (!visible.contains(requestId)) return;

      final previousPosition = previousPositions[requestId];
      final movementMeters = previousPosition == null
          ? 0.0
          : Geolocator.distanceBetween(
              previousPosition.latitude,
              previousPosition.longitude,
              position.latitude,
              position.longitude,
            );
      final bearing = previousPosition != null && movementMeters >= 2
          ? calculateBearing(previousPosition, position)
          : markerBearings[requestId] ?? 0.0;
      markerBearings[requestId] = bearing;
      final update = webSocketController.riderLocationUpdates[requestId];
      final marker = Marker(
        markerId: MarkerId(requestId),
        position: position,
        infoWindow: InfoWindow(
            title: '${update?.client ?? 'Dispatch'} - $requestId',
            snippet:
                'Rider: ${update?.riderInitial ?? ''} ETA: ${update?.eta ?? ''}, Distance: ${update?.distance ?? ''}, Status: ${update?.status ?? ''}',
            onTap: () async {
              final String phoneNumber = await userController
                  .fetchUserPhoneNumberForDriver(update?.riderInitial ?? '');

              if (phoneNumber.isNotEmpty) {
                CallFunctions.makePhoneCall(phoneNumber);
              } else {
                BHelperFunctions.showSnackBar(
                    'Dispatcher phone number not available.');
              }
            }),
        icon: _iconForRequest(requestId),
        rotation: bearing,
      );
      nextMarkers[requestId] = marker;
      previousPositions[requestId] = position;
    });

    updatedMarkers
      ..clear()
      ..addAll(nextMarkers);

    return updatedMarkers.values.toSet();
  }

  BitmapDescriptor _iconForRequest(String requestId) {
    final assetPath = _assetPathForRequest(requestId);

    return _dispatchMarkerIcons[assetPath] ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
  }

  String _assetPathForRequest(String requestId) {
    final index = WebSocketDeliveryController.dispatchMarkerIndexForRequestId(
      requestId,
      BImages.riderCarVariants.length,
    );

    return BImages.riderCarVariants[index];
  }

  void _handleRiderLocationsChanged() {
    if (!_hasCenteredInitialRiders &&
        selectedVehicle.value == null &&
        webSocketController.riderLocations.isNotEmpty) {
      _hasCenteredInitialRiders = true;
      Future.delayed(const Duration(milliseconds: 300), centerActiveDeliveries);
    }
  }

  Future<void> centerActiveDeliveries() async {
    final controller = mapController.value;
    final positions = webSocketController.riderLocations.values
        .where(
            (position) => position.latitude != 0.0 && position.longitude != 0.0)
        .toList();

    if (controller == null || positions.isEmpty) return;

    if (positions.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(positions.first, 15),
      );
      return;
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(_boundsForPositions(positions), 80),
    );
  }

  Future<void> centerDispatch(String requestId) async {
    final controller = mapController.value;
    final position = webSocketController.riderLocations[requestId];

    if (controller == null || position == null) return;

    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(position, 16),
    );
  }

  LatLngBounds _boundsForPositions(List<LatLng> positions) {
    var minLat = positions.first.latitude;
    var maxLat = positions.first.latitude;
    var minLng = positions.first.longitude;
    var maxLng = positions.first.longitude;

    for (final position in positions.skip(1)) {
      minLat = math.min(minLat, position.latitude);
      maxLat = math.max(maxLat, position.latitude);
      minLng = math.min(minLng, position.longitude);
      maxLng = math.max(maxLng, position.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<void> getUserLocation() async {
    final permissionCheck = await _permissionService.requireForFeature(
      PermissionType.location,
      featureName: 'Delivery location map',
    );
    if (!permissionCheck.granted) return;

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high));
    currentLocation.value = LatLng(position.latitude, position.longitude);

    mapController.value
        ?.animateCamera(CameraUpdate.newLatLngZoom(currentLocation.value, 14));
  }

  double calculateBearing(LatLng startPoint, LatLng endPoint) {
    final double startLat = toRadians(startPoint.latitude);
    final double startLng = toRadians(startPoint.longitude);
    final double endLat = toRadians(endPoint.latitude);
    final double endLng = toRadians(endPoint.longitude);

    final double deltaLng = endLng - startLng;
    final double y = math.sin(deltaLng) * math.cos(endLat);
    final double x = math.cos(startLat) * math.sin(endLat) -
        math.sin(startLat) * math.cos(endLat) * math.cos(deltaLng);

    final double bearing = math.atan2(y, x);
    return (toDegrees(bearing) + 360) % 360;
  }

  double toRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  double toDegrees(double radians) {
    return radians * (180.0 / math.pi);
  }

  Set<Marker> buildMarkers() {
    final markers = <Marker>{};
    if (currentLocation.value != LatLng(0, 0) &&
        selectedVehicle.value == null) {
      markers.add(
        Marker(
          markerId: const MarkerId('myLocation'),
          position: currentLocation.value,
          infoWindow: const InfoWindow(title: 'My Location'),
        ),
      );
    }
    return markers;
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polylineCoordinates = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int shift = 0, result = 0;
      int byte;

      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      int deltaLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += deltaLat;

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      int deltaLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += deltaLng;

      polylineCoordinates.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polylineCoordinates;
  }

  @override
  void onClose() {
    _riderLocationWorker?.dispose();
    super.onClose();
  }
}
