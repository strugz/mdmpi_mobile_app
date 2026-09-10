import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/text_strings.dart';
import 'package:mdmpi_mobile_app/base/utils/helpers/map_helper.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_delivery_request_controller.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_location_tracking_service.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_maps_service.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_permission_service.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_places_service.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/location_alternative_service.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/standard_delivery_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/hotline_direct_controller.dart';
import 'package:mdmpi_mobile_app/data/repositories/app_data/backload_item_repository.dart';
import 'package:mdmpi_mobile_app/features/logistics/controllers/rider_realtime_tracking_controller.dart';
import 'package:mdmpi_mobile_app/features/logistics/helpers/crew_assignment.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/backload_item_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/location_alternative_model.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/standard_delivery_model.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../base/utils/local_storage/text_storage_service.dart';

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
  final imageProofPath = Rx<String?>("");

  final addressTextController = TextEditingController();
  final suggestions = RxList([]);

  /// Variables for Animated Container
  final searchBarHeight = RxDouble(0.0); // Height of the search bar
  final expandedSearchHeight =
      RxDouble(300.0); // Height when search is expanded
  final isSearching = false.obs;

  /// Variables for Location Listening
  StreamSubscription<Position>? positionStream;

  RiderRealtimeTrackingController get riderTrackingController =>
      Get.find<RiderRealtimeTrackingController>();

  /// New loading state
  final RxBool isLoadingAction = false.obs;

  /// Route state variables
  final RxBool isRouteLoaded = false.obs;
  final Rx<LatLng?> _currentRouteDestination = Rx<LatLng?>(null);

  /// FAB bottom offset
  final RxDouble fabBottomOffset = 16.0.obs;

  final FocusNode searchFocusNode = FocusNode();

  /// Service dependencies
  late final IMapsService _mapsService;
  late final IPlacesService _placesService;
  late final ILocationTrackingService _locationTrackingService;
  late final ILocationAlternativeService _locationAlternativeService;

  IPermissionService get _permissionService => Get.find<IPermissionService>();

  /// Reactive fields for location alternatives tracking
  final RxBool hasLocationAlternative = false.obs;
  final Rx<LocationAlternativeModel?> currentLocationAlternative =
      Rx<LocationAlternativeModel?>(null);
  final RxList<LocationAlternativeModel> savedAlternatives = RxList([]);
  final TextStorageService _textStorageService = TextStorageService();

  @override
  void onInit() {
    super.onInit();
    // Initialize services from GetX DI
    _mapsService = Get.find<IMapsService>();
    _placesService = Get.find<IPlacesService>();
    _locationTrackingService = Get.find<ILocationTrackingService>();
    _locationAlternativeService = Get.find<ILocationAlternativeService>();

    // Request controller is lazily initialized on first access via getter

    reInitialize();
    getUserLocation();
    startLocationTracking();
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  /// Lazy getter for request controller - tries to find the appropriate controller
  /// when accessed, not during onInit
  IDeliveryRequestController get _requestController {
    try {
      // Try StandardDeliveryController first
      return Get.find<StandardDeliveryController>();
    } catch (e) {
      try {
        // Try HotlineDirectController second
        return Get.find<HotlineDirectController>();
      } catch (e) {
        throw Exception(
          'Request controller not found in DI. '
          'Make sure StandardDeliveryController or HotlineDirectController is registered.',
        );
      }
    }
  }

  Future<void> reInitialize() async {
    if (imageProofPath.value?.isEmpty ?? true) {
      imageProofPath.value =
          _textStorageService.getText("proofImagePath") ?? "";
    }
  }

  Future<void> startLocationTracking() async {
    final permission = await _permissionService.requireForFeature(
      PermissionType.location,
      featureName: 'Delivery tracking',
    );
    if (!permission.granted) return;

    positionStream = _locationTrackingService
        .startTracking(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20,
    )
        .listen((Position position) {
      LatLng newPosition = LatLng(position.latitude, position.longitude);

      // Update the current location
      currentLocation.value = newPosition;

      mapController.value?.animateCamera(
        CameraUpdate.newLatLng(newPosition),
      );

      // Only send rider location updates when in delivery status
      final currentRequest = _requestController.currentSelectedRequest.value;
      if (currentRequest == null) return;

      if (currentRequest.status == BTexts.statusForDelivery) {
        riderTrackingController.startTrackingForRequest(
          currentRequest,
          eta: eta.value,
          distance: distance.value,
        );
      } else if (riderTrackingController.activeRequestId.value ==
          currentRequest.id) {
        riderTrackingController.stopTracking();
      }
    });
  }

  /// -- Google Place Autocomplete API
  Future<void> getSuggestions(String input) async {
    if (input.isEmpty) {
      suggestions.clear();
      return;
    }

    try {
      final result = await _placesService.getSuggestions(input);
      suggestions.value = result;
    } catch (e) {
      suggestions.clear();
    }
  }

  Future<void> getRoute(LatLng location, LatLng destination) async {
    if (location == LatLng(0, 0) || destination == LatLng(0, 0)) return;

    try {
      final routeData = await _mapsService.getRoute(location, destination);

      polyLines.value = {
        Polyline(
          polylineId: const PolylineId("route"),
          points: routeData['polylinePoints'],
          color: Colors.blue,
          width: 5,
        ),
      };

      distance.value = routeData['distance'];
      eta.value = routeData['eta'];

      // Only animate camera if map controller is initialized
      if (mapController.value != null) {
        mapController.value!.animateCamera(CameraUpdate.newLatLngBounds(
            MapHelper.getLatLngBounds(location, destination), 100));
      }

      addressTextController.text = routeData['address'];

      isRouteLoaded.value = true; // Mark route as loaded
      _currentRouteDestination.value =
          destination; // Store the destination for this route
    } catch (e) {
      isRouteLoaded.value = false;
      _currentRouteDestination.value = null;
    }
  }

  Future<void> getCoordinatesFromPlace(String place) async {
    // When a new place is searched, we assume a new route is needed.
    isRouteLoaded.value = false;
    _currentRouteDestination.value = null; // Clear previous route destination

    try {
      final placeData = await _mapsService.getCoordinatesFromPlace(place);

      destination.value = LatLng(placeData['latitude'], placeData['longitude']);

      await getRoute(currentLocation.value, destination.value);
    } catch (e) {
      logDebug('✗ Error getting coordinates from place: $e');
    }
  }

  Future<void> getAddressFromCoordinates(LatLng latLng) async {
    // When a new location is tapped, we assume a new route is needed.
    isRouteLoaded.value = false;
    _currentRouteDestination.value = null; // Clear previous route destination

    try {
      final addressData = await _mapsService.getAddressFromCoordinates(latLng);

      final address = addressData['address'] ?? "Address not found";
      placeController.value = address;

      destination.value = latLng;
      await getRoute(currentLocation.value, destination.value);
      addressTextController.text = address;
    } catch (e) {
      BLoaders.warningSnackBar(
        title: 'Address Error',
        message:
            'Could not find address for this location. Location saved anyway.',
      );
      logDebug('✗ Error getting address from coordinates: $e');
    }
  }

  /// Initialize route after address is set by the screen.
  /// Call this method after setting addressTextController.text in the UI.
  Future<void> initializeRoute() async {
    // Wait for current location to be available
    if (currentLocation.value == LatLng(0, 0)) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (currentLocation.value == LatLng(0, 0)) {
        return;
      }
    }

    // Load saved location alternatives from local database
    await loadLocationAlternatives();

    // Check if we have a saved alternative
    if (hasLocationAlternative.value &&
        currentLocationAlternative.value != null) {
      final savedLocation = currentLocationAlternative.value;

      // Use saved alternative coordinates directly (no need to geocode)
      destination.value =
          LatLng(savedLocation!.latitude, savedLocation.longitude);
      addressTextController.text = savedLocation.address;

      // Calculate route with saved coordinates directly
      await getRoute(currentLocation.value, destination.value);
    } else {
      if (addressTextController.text.isNotEmpty) {
        await getCoordinatesFromPlace(addressTextController.text);
      } else {
        logDebug('⚠️ No address set for route initialization');
      }
    }

    logDebug('✓ initializeRoute() completed');
  }

  /// Load all saved location alternatives for current request
  Future<void> loadLocationAlternatives() async {
    try {
      final currentRequest = _requestController.currentSelectedRequest.value;
      if (currentRequest == null) {
        hasLocationAlternative.value = false;
        currentLocationAlternative.value = null;
        savedAlternatives.clear();
        return;
      }

      final requestId = currentRequest.id;

      savedAlternatives.value = await _locationAlternativeService
          .getLocationAlternativesByRequestId(requestId);

      // Set current alternative to the latest one
      if (savedAlternatives.isNotEmpty) {
        currentLocationAlternative.value = savedAlternatives.first;
        hasLocationAlternative.value = true;
      } else {
        currentLocationAlternative.value = null;
        hasLocationAlternative.value = false;
      }
    } catch (e) {
      hasLocationAlternative.value = false;
      currentLocationAlternative.value = null;
    }
  }

  Future<void> getUserLocation() async {
    try {
      final permission = await _permissionService.requireForFeature(
        PermissionType.location,
        featureName: 'Request transport map',
      );
      if (!permission.granted) return;

      final position = await _locationTrackingService.getCurrentLocation(
        accuracy: LocationAccuracy.high,
      );

      currentLocation.value = LatLng(position.latitude, position.longitude);

      mapController.value?.animateCamera(
          CameraUpdate.newLatLngZoom(currentLocation.value, 14));

      // Note: We no longer fetch the route here automatically.
      // The screen should call initializeRoute() after setting the address.
    } catch (e) {
      logDebug('✗ Error getting user location: $e');
    }
  }

  Set<Marker> buildMarkers() {
    return MapHelper.buildMarkers(
      currentLocation: currentLocation.value,
      destination: destination.value,
      eta: eta.value,
    );
  }

  Future<void> openExternalNavigation() async {
    final origin = currentLocation.value;
    final destinationPoint = _effectiveNavigationDestination();

    if (origin == LatLng(0, 0)) {
      BLoaders.warningSnackBar(
        title: 'Navigation',
        message: 'Current location is not ready yet.',
      );
      return;
    }

    if (destinationPoint == null || destinationPoint == LatLng(0, 0)) {
      BLoaders.warningSnackBar(
        title: 'Navigation',
        message: 'Destination is not ready yet.',
      );
      return;
    }

    final originText = '${origin.latitude},${origin.longitude}';
    final destinationText =
        '${destinationPoint.latitude},${destinationPoint.longitude}';

    final launchCandidates = <Uri>[
      Uri.parse('waze://?ll=$destinationText&navigate=yes'),
      Uri.parse('google.navigation:q=$destinationText&mode=d'),
      Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=$originText'
        '&destination=$destinationText'
        '&travelmode=driving',
      ),
    ];

    for (final uri in launchCandidates) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    BLoaders.errorSnackBar(
      title: 'Navigation',
      message: 'No navigation app is available.',
    );
  }

  LatLng? _effectiveNavigationDestination() {
    final savedLocation = currentLocationAlternative.value;
    if (hasLocationAlternative.value && savedLocation != null) {
      return LatLng(savedLocation.latitude, savedLocation.longitude);
    }

    return destination.value;
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
    return MapHelper.getLatLngBounds(loc, des);
  }

  /// ========================================================================
  /// Location Alternative Management (for corrected addresses)
  /// ========================================================================

  /// Save a corrected location when user taps the map to correct wrong address
  Future<void> saveLocationAlternative(
    LatLng coordinates,
    String address,
    String id, {
    String? notes,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final model = LocationAlternativeModel.fromStringId(
        stringRequestId: id,
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        address: address,
        createdAt: now,
        notes: notes,
      );

      // Save to database
      await _locationAlternativeService.saveLocationAlternative(model);

      // Update reactive state
      currentLocationAlternative.value = model;
      hasLocationAlternative.value = true;

      // Reload alternatives list
      await loadLocationAlternatives();
    } catch (e) {
      logDebug('Failed to save corrected location: $e');
      BLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to save location: $e',
      );
    }
  }

  /// Clear all location alternatives for current request (called on drop-off)
  Future<void> clearLocationAlternativesOnDropOff() async {
    try {
      final currentRequest = _requestController.currentSelectedRequest.value;
      if (currentRequest == null) {
        logDebug('⚠️ No request selected');
        return;
      }

      final requestId = currentRequest.id;
      await _locationAlternativeService.deleteLocationAlternativesByRequestId(
        requestId,
      );

      // Update reactive state
      savedAlternatives.clear();
      currentLocationAlternative.value = null;
      hasLocationAlternative.value = false;
    } catch (e) {
      logDebug('✗ Error clearing location alternatives: $e');
    }
  }

  /// Delete a specific location alternative
  Future<void> deleteLocationAlternativeById(int id) async {
    try {
      await _locationAlternativeService.deleteLocationAlternativeById(id);
      savedAlternatives.removeWhere((alt) => alt.requestId == id);
      hasLocationAlternative.value = savedAlternatives.isNotEmpty;
    } catch (e) {
      logDebug('✗ Error deleting location alternative: $e');
    }
  }

  Future<void> processRequestDispatchOrDropOff(
    StandardDeliveryModel currentRequest,
    String userInitial,
    IDeliveryRequestController requestController,
  ) async {
    if (isLoadingAction.value) return;

    // Dispatch / Drop Off are reserved for the assigned driver or helper. The
    // list and the action button already enforce this; this is the last line
    // of defence for any other route into the screen.
    if (!CrewAssignment.canOperate(currentRequest, userInitial: userInitial)) {
      BLoaders.warningSnackBar(
          title: 'Not assigned',
          message:
              'Only the assigned driver or helper can update this request.');
      return;
    }

    isLoadingAction.value = true; // <--- Start loading

    if ((eta.value?.isEmpty ?? true) &&
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
        // Release assigns the driver at Item Prepared; keep it. Only fill the
        // slot when it is empty so a helper pressing Dispatch does not become
        // the driver.
        if (currentRequest.deliveredBy.trim().isEmpty) {
          currentRequest.deliveredBy = userInitial;
        }
        currentRequest.locationStartedAt =
            '${currentLocation.value.latitude} ${currentLocation.value.longitude}';

        await saveLocationAlternative(
          destination.value,
          addressTextController.text,
          currentRequest.id,
          notes: 'User-corrected location from map tap',
        );
      } else if (currentRequest.status == BTexts.statusForDelivery) {
        newStatus = BTexts.statusDoneDelivery;

        // Record backloaded items before completing — the request is not
        // marked Done Delivery unless they are saved, and the courier's
        // entries survive the failure.
        final formState = requestController.formState;
        if (formState.backloadItemRemarks.isNotEmpty &&
            formState.backloadItemsRequestId.value == currentRequest.id) {
          final backloadItems = formState.backloadItemRemarks.entries
              .map((e) =>
                  BackloadItemModel(itemCode: e.key, remarks: e.value))
              .toList();
          final saveResult = await BackloadItemRepository.instance
              .replaceForRequest(currentRequest.id, backloadItems);
          if (saveResult.isFailure) {
            BLoaders.errorSnackBar(
              title: 'Backloaded Items',
              message:
                  'Could not save the backloaded items. Please try again.',
            );
            isLoadingAction.value = false;
            return;
          }
        }

        currentRequest.locationEndAt =
            '${currentLocation.value.latitude} ${currentLocation.value.longitude}';

        // CLEAR location alternatives on successful drop-off
        await clearLocationAlternativesOnDropOff();
        _textStorageService.clearAll();

        await riderTrackingController.stopTracking();
      } else {
        isLoadingAction.value = false; // <--- Stop loading on error
      }

      await requestController.updateRequestStatus(
          currentRequest, newStatus, userInitial);
      if (newStatus == BTexts.statusDoneDelivery) {
        requestController.formState.backloadItemRemarks.clear();
        requestController.formState.backloadItemsRequestId.value = '';
      }
      if (newStatus == BTexts.statusForDelivery) {
        await riderTrackingController.startTrackingForRequest(
          currentRequest,
          eta: eta.value,
          distance: distance.value,
        );
      }
    } catch (e) {
      BLoaders.errorSnackBar(
          title: "Error",
          message: "Could not update request status. Please try again.");
    } finally {
      isLoadingAction.value = false;
    }
  }
}
