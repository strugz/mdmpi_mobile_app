import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import 'package:mdmpi_mobile_app/common/services/abstracts/i_permission_service.dart';

import '../abstracts/i_location_tracking_service.dart';

/// Implementation of ILocationTrackingService using Geolocator plugin.
class LocationTrackingService implements ILocationTrackingService {
  StreamSubscription<Position>? _positionStream;

  IPermissionService? get _permissionServiceOrNull {
    if (Get.isRegistered<IPermissionService>()) {
      return Get.find<IPermissionService>();
    }
    return null;
  }

  @override
  Stream<Position> startTracking({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 20,
    bool useForegroundService = false,
    String? notificationTitle,
    String? notificationText,
  }) {
    final locationSettings = _buildLocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
      useForegroundService: useForegroundService,
      notificationTitle: notificationTitle,
      notificationText: notificationText,
    );

    final positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).asBroadcastStream();

    _positionStream = positionStream.listen(
      (position) {
        logDebug(
          'Location update: ${position.latitude}, ${position.longitude}',
        );
      },
      onError: (e) {
        logDebug('Location tracking error: $e');
      },
    );

    return positionStream;
  }

  LocationSettings _buildLocationSettings({
    required LocationAccuracy accuracy,
    required int distanceFilter,
    required bool useForegroundService,
    String? notificationTitle,
    String? notificationText,
  }) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        intervalDuration: const Duration(seconds: 10),
        foregroundNotificationConfig: useForegroundService
            ? ForegroundNotificationConfig(
                notificationTitle:
                    notificationTitle ?? 'MDMPI delivery tracking active',
                notificationText: notificationText ??
                    'Your delivery location is being shared in realtime.',
                notificationChannelName: 'Delivery Location Tracking',
                enableWakeLock: true,
                setOngoing: true,
              )
            : null,
      );
    }

    return LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );
  }

  @override
  Future<void> stopTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
    logDebug('Location tracking stopped');
  }

  @override
  Future<Position> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    final permissionResult = await _permissionServiceOrNull?.requireForFeature(
      PermissionType.location,
      featureName: 'Current location',
    );
    if (permissionResult != null && !permissionResult.granted) {
      throw Exception('Location permission denied');
    }

    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      BLoaders.warningSnackBar(
        title: 'Location',
        message: 'Location services are disabled.',
      );
      throw Exception('Location services disabled');
    }

    final permission = await checkLocationPermission();
    if (permission == LocationPermission.denied) {
      final newPermission = await requestLocationPermission();
      if (newPermission == LocationPermission.denied) {
        BLoaders.warningSnackBar(
          title: 'Location',
          message: 'Location permissions are denied.',
        );
        throw Exception('Location permissions denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      BLoaders.warningSnackBar(
        title: 'Location',
        message: 'Location permissions are permanently denied.',
      );
      throw Exception('Location permissions permanently denied');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: accuracy),
    );

    logDebug(
      'Current location obtained: ${position.latitude}, ${position.longitude}',
    );
    return position;
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }

  @override
  Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }
}
