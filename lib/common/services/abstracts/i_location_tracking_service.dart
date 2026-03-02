import 'package:geolocator/geolocator.dart';

/// Interface for location tracking services.
///
/// Manages continuous location tracking with customizable accuracy and filters.
abstract class ILocationTrackingService {
  /// Starts continuous location tracking.
  ///
  /// Returns a stream of Position updates.
  /// Respects distance filter to reduce updates frequency.
  ///
  /// Example:
  /// ```dart
  /// await locationTrackingService.startTracking(
  ///   accuracy: LocationAccuracy.high,
  ///   distanceFilter: 20, // meters
  /// ).listen((Position position) {
  ///   print('New location: ${position.latitude}, ${position.longitude}');
  /// });
  /// ```
  Stream<Position> startTracking({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 20,
  });

  /// Stops location tracking and cancels the stream.
  Future<void> stopTracking();

  /// Gets the current user location.
  ///
  /// Throws exception if location services are disabled or permissions denied.
  Future<Position> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
  });

  /// Checks if location services are enabled.
  Future<bool> isLocationServiceEnabled();

  /// Requests location permission.
  ///
  /// Returns the permission status after the request.
  Future<LocationPermission> requestLocationPermission();

  /// Checks current location permission status.
  Future<LocationPermission> checkLocationPermission();
}
