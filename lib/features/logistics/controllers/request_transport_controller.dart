import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/constants/text_string.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/web_socket_dispatcher_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';

import '../models/rider_location_model.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';

class RequestTransportController extends GetxController {
  static RequestTransportController get instance => Get.find();

  /// Google Map Controller
  final mapController = Rx<GoogleMapController?>(null);
  final currentLocation = Rx<LatLng>(LatLng(0, 0));
  final destination = Rx<LatLng>(LatLng(0, 0));
  final polyLines = Rx<Set<Polyline>>({});
  final distance = Rx<String?>("");
  final eta = Rx<String?>("");
  final lastCameraPosition = Rx<CameraPosition?>(null);
  final selectedDestinationMarkerId = Rx<MarkerId?>(null);
  final placeController = Rx<String?>("");
  final String _apiKey = dotenv.env['API_KEY']!;

  final addressTextController = TextEditingController();
  final suggestions = RxList([]);

  /// Variables for Animated Container
  final searchBarHeight = RxDouble(0.0); // Height of the search bar
  final expandedSearchHeight =
      RxDouble(300.0); // Height when search is expanded
  final isSearching = false.obs;

  /// Variables for Location Listening
  StreamSubscription<Position>? positionStream;

  /// WebSocket Controller
  final webSocketController = Get.find<WebSocketDispatcherController>();

// You'll need access to RequestController if it's separate
  final StandardDeliveryController _requestController = Get.find<StandardDeliveryController>(); // Or inject it
  // Add a new RxBool for loading state
  final RxBool isLoadingAction = false.obs; // <--- New loading state

  // --- New state variables ---
  final RxBool isRouteLoaded = false.obs; // Flag to check if a route is loaded

  final Rx<LatLng?> _currentRouteDestination =
      Rx<LatLng?>(null); // Store the destination for the current route

  // Add a variable to store the FAB's bottom offset
  final RxDouble fabBottomOffset = 16.0.obs;

  final FocusNode searchFocusNode = FocusNode();

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    getUserLocation();
    startLocationTracking();
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  Future<void> startLocationTracking() async {
    positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      ),
    ).listen((Position position) {
      LatLng newPosition = LatLng(position.latitude, position.longitude);

      // Update the current location
      currentLocation.value = newPosition; // Keep track of the current location

      mapController.value?.animateCamera(
        CameraUpdate.newLatLng(newPosition),
      );

      if (_requestController.currentSelectedRequest.value!.status ==
          BTexts.statusForDelivery) {
        getCoordinatesFromPlace(addressTextController.text);

        if (webSocketController.isConnected.value) {
          final riderLocation = RiderLocationModel(
            type: 'location_update',
            requestId:
                _requestController.currentSelectedRequest.value!.id,
            latitude: position.latitude,
            longitude: position.longitude,
            timestamp: position.timestamp,
            status: 'en_route',
            riderInitial:
                _requestController.currentSelectedRequest.value!.deliveredBy,
            // Ensure eta.value and distance.value are not null before sending
            eta: eta.value ?? "Calculating...",
            distance: distance.value ?? "Calculating...",
            client:
                _requestController.currentSelectedRequest.value!.client.name,
          );
          logDebug('1${jsonEncode(riderLocation)}');
          webSocketController.sendMessage(jsonEncode(riderLocation.toJson()));
        } else {
          webSocketController.reconnectWebSocket();
        }
      }
    });
  }

  /// -- Google Place Autocomplete API
  Future<void> getSuggestions(String input) async {
    if (input.isEmpty) {
      suggestions.clear();
      return;
    }
    final String apiUrl =
        'https://google-place-autocomplete-and-place-info.p.rapidapi.com/maps/api/place/autocomplete/json?input=$input';
    final Map<String, String> headers = {
      'x-rapidapi-host':
          'google-place-autocomplete-and-place-info.p.rapidapi.com',
      'x-rapidapi-key':
          '4f82d3507fmsh8737922d6f89c00p1e27f4jsn31c6824aadc7', // Replace with your actual RapidAPI key
    };

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          suggestions.value = data['predictions'];
        } else {
          logDebug('Error fetching suggestions: ${data['status']}');
          suggestions.clear();
        }
      } else {
        logDebug('HTTP error: ${response.statusCode}');
        suggestions.clear();
      }
    } catch (e) {
      logDebug('Error during API call: $e');
      suggestions.clear();
    }
  }

  Future<void> getRoute(LatLng location, LatLng destination) async {
    if (location == LatLng(0, 0) || destination == LatLng(0, 0)) return;

    final String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${location.latitude},${location.longitude}&destination=${destination.latitude},${destination.longitude}&key=$_apiKey";
    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == "OK") {
        String encodedPolyline =
            data["routes"][0]["overview_polyline"]["points"];
        List<LatLng> routePoints = _decodePolyline(encodedPolyline);

        String address = data["routes"][0]["legs"][0]["end_address"];

        polyLines.value = {
          Polyline(
            polylineId: const PolylineId("route"),
            points: routePoints,
            color: Colors.blue,
            width: 5,
          ),
        };

        distance.value = data["routes"][0]["legs"][0]["distance"]["text"];
        eta.value = data["routes"][0]["legs"][0]["duration"]["text"];

        mapController.value!.animateCamera(CameraUpdate.newLatLngBounds(
            getLatLngBounds(location, destination), 100));

        addressTextController.text = address;

        isRouteLoaded.value = true; // Mark route as loaded
        _currentRouteDestination.value =
            destination; // Store the destination for this route
      } else {
        isRouteLoaded.value = false;
        _currentRouteDestination.value = null;
      }
    } catch (e) {
      isRouteLoaded.value = false;
      _currentRouteDestination.value = null;
      // Handle exception
    } finally {
      // BFullScreenLoader.stopLoading(); // Stop loader
    }
  }

  Future<void> getCoordinatesFromPlace(String place) async {
    // When a new place is searched, we assume a new route is needed.
    isRouteLoaded.value = false;
    _currentRouteDestination.value = null; // Clear previous route destination
    final String url =
        "https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(place)}&key=$_apiKey";
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);
    if (data["status"] == "OK") {
      double lat = data["results"][0]["geometry"]["location"]["lat"];
      double lng = data["results"][0]["geometry"]["location"]["lng"];

      destination.value = LatLng(lat, lng);

      getRoute(currentLocation.value, destination.value);
    }
  }

  Future<void> getAddressFromCoordinates(LatLng latLng) async {
    // When a new location is tapped, we assume a new route is needed.
    isRouteLoaded.value = false;
    _currentRouteDestination.value = null; // Clear previous route destination
    final String url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$_apiKey";

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data["status"] == "OK" &&
        data["results"] != null &&
        data["results"].isNotEmpty) {
      String address =
          data["results"][0]["formatted_address"] ?? "Address not found";

      placeController.value = address;

      if (data["routes"] != null && data["routes"].isNotEmpty) {
        eta.value = data["routes"][0]["legs"][0]["duration"]["text"] ??
            "ETA not available";
      } else {
        eta.value = "ETA not available";
      }

      destination.value = latLng;

      getRoute(currentLocation.value, destination.value);

      addressTextController.text = address;
    } else {
      logDebug("Error: ${data["status"]}");
    }
  }

  Future<void> getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      // You might want to show a dialog or a snack bar here.
      BLoaders.warningSnackBar(
          title: 'Location', message: "Location services are disabled.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        BLoaders.warningSnackBar(
            title: 'Location', message: "Location permissions are denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      // You might want to guide the user to app settings.
      BLoaders.warningSnackBar(
          title: 'Location',
          message:
              "Location permissions are permanently denied, we cannot request permissions.");
      return;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
    currentLocation.value = LatLng(position.latitude, position.longitude);

    mapController.value
        ?.animateCamera(CameraUpdate.newLatLngZoom(currentLocation.value, 14));

    // If there's text in the destination text field, it implies a destination was previously entered or loaded.
    // Try to get coordinates for it. getCoordinatesFromPlace will reset isRouteLoaded.
    if (addressTextController.text.isNotEmpty) {
      // We call this, which will set destination.value and also reset
      // isRouteLoaded.value = false and _currentRouteDestination.value = null.
      // The startLocationTracking method will then pick up this change
      // and call getRoute if necessary.
      await getCoordinatesFromPlace(addressTextController.text);
    }
    // If a destination is already set (e.g. from a previous session, not via text input)
    // AND no route is currently loaded for it, then fetch the route.
    // This handles cases where destination.value might be populated by other means
    // than the textEditingController (e.g., loaded from GetStorage onInit).
    else if (destination.value != LatLng(0, 0) &&
        (!isRouteLoaded.value ||
            _currentRouteDestination.value != destination.value)) {
      // Ensure currentLocation is valid before trying to fetch a route.
      if (currentLocation.value != LatLng(0, 0)) {
        // Call getRoute directly.
        // No need to await if you want it to happen in the background,
        // but awaiting ensures it completes before any subsequent logic relying on it.
        await getRoute(currentLocation.value, destination.value);
      }
    }
  }

  Set<Marker> buildMarkers() {
    final markers = <Marker>{};
    if (currentLocation.value != LatLng(0, 0)) {
      markers.add(
        Marker(
          markerId: const MarkerId('myLocation'),
          position: currentLocation.value,
          infoWindow: const InfoWindow(title: 'My Location'),
        ),
      );
    }

    if (destination.value != LatLng(0, 0)) {
      markers.add(
        Marker(
          markerId: const MarkerId('myTappedDestination'),
          position: destination.value,
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: "ETA: $eta", // Shortened "Distance" to "Dist"
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }

    return markers;
  }

  /// Handle search here button press
  Future<void> onSearchHerePressed() async {
    if (!isSearching.value) {
      isSearching.value = true;
    } else {
      isSearching.value = false;
    }
  }

  /// -- Camera Position to view the location and destination
  LatLngBounds getLatLngBounds(LatLng loc, LatLng des) {
    final southwest = LatLng(
      min(loc.latitude, des.latitude),
      min(loc.longitude, des.longitude),
    );

    final northeast = LatLng(
      max(loc.latitude, des.latitude),
      max(loc.longitude, des.longitude),
    );

    return LatLngBounds(southwest: southwest, northeast: northeast);
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

  Future<void> processRequestDispatchOrDropOff(
      StandardDeliveryModel currentRequest, userInitial) async {
    if (isLoadingAction.value) return;
    isLoadingAction.value = true; // <--- Start loading

    if (eta.value!.isEmpty &&
        currentRequest.status == BTexts.statusItemPrepared) {
      BLoaders.warningSnackBar(
          title: 'Error', message: 'Please check address, No Route found.');
      isLoadingAction.value = false;
      return;
    }

    try {
      String newStatus = "";
      if (currentRequest.status == BTexts.statusItemPrepared) {
        newStatus = BTexts.statusForDelivery;
        currentRequest.locationStartedAt =
            '${currentLocation.value.latitude} ${currentLocation.value.longitude}';
      } else if (currentRequest.status == BTexts.statusForDelivery) {
        newStatus = BTexts.statusDoneDelivery;
        currentRequest.locationEndAt =
            '${currentLocation.value.latitude} ${currentLocation.value.longitude}';
        webSocketController.onClose();
      } else {
        isLoadingAction.value = false; // <--- Stop loading on error
      }
      await _requestController.updateRequestStatus(
          currentRequest, newStatus, userInitial);
    } catch (e) {
      BLoaders.errorSnackBar(
          title: "Error",
          message: "Could not update request status. Please try again.");
    } finally {
      isLoadingAction.value = false;
    }
  }
}
