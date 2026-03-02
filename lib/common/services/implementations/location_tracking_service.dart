import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import 'package:mdmpi_mobile_app/base/utils/popups/loaders.dart';
import '../abstracts/i_location_tracking_service.dart';

/// Implementation of ILocationTrackingService using Geolocator plugin.
class LocationTrackingService implements ILocationTrackingService {
  StreamSubscription<Position>? _positionStream;

  @override
  Stream<Position> startTracking({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 20,
  }) {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    ).listen(
      (position) {
        logDebug(
          '📍 Location update: ${position.latitude}, ${position.longitude}',
        );
      },
      onError: (e) {
        logDebug('✗ Location tracking error: $e');
      },
    );

    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  @override
  Future<void> stopTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
    logDebug('⏹ Location tracking stopped');
  }

  @override
  Future<Position> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
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
      '📍 Current location obtained: ${position.latitude}, ${position.longitude}',
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
