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

  final userController = Get.find<UserController>();

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    getUserLocation();
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

  Set<Marker> riderBuildMarkers() {
    webSocketController.riderLocations.forEach((riderId, position) async {
      LatLng previousPosition = previousPositions[riderId] ?? LatLng(0, 0);
      double bearing = calculateBearing(previousPosition, position);
      final marker = Marker(
        markerId: MarkerId(riderId),
        position: position,
        infoWindow: InfoWindow(
            title: webSocketController.riderDestination.value,
            snippet: 'Rider: ${webSocketController.riderInitial} ETA: ${webSocketController.riderEta.value}, Distance: ${webSocketController.riderDistance.value}',
            onTap: () async {
              final String phoneNumber = await userController
                  .fetchUserPhoneNumberForDriver(webSocketController
                      .riderInitial.value); // Replace with your actual field

              if (phoneNumber.isNotEmpty) {
                CallFunctions.makePhoneCall(phoneNumber);
              } else {
                BHelperFunctions.showSnackBar(
                    'Dispatcher phone number not available.');
              }
            }),
        // ignore: deprecated_member_use
        icon: await BitmapDescriptor.fromAssetImage(
          ImageConfiguration(size: Size(100, 100)),
          BImages.riderCar,
        ),
        rotation: bearing,
      );
      updatedMarkers[riderId] = marker;
      previousPositions[riderId] = position;
    });
    return updatedMarkers.values.toSet();
  }

  Future<void> getUserLocation() async {
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
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
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
}
