import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Utility class for common Google Maps operations.
///
/// Provides helper methods for marker creation, bounds calculation, and map geometry.
class MapHelper {
  /// Builds a set of markers for current location and destination.
  ///
  /// Creates two markers:
  /// - Blue marker at current location
  /// - Orange marker at destination
  ///
  /// Example:
  /// ```dart
  /// final currentLoc = LatLng(40.7128, -74.0060);
  /// final destLoc = LatLng(40.7580, -73.9855);
  /// final markers = MapHelper.buildMarkers(currentLoc, destLoc);
  /// ```
  static Set<Marker> buildMarkers({
    required LatLng currentLocation,
    required LatLng destination,
    String? eta,
  }) {
    final markers = <Marker>{};

    // Add current location marker
    if (currentLocation != LatLng(0, 0)) {
      markers.add(
        Marker(
          markerId: const MarkerId('myLocation'),
          position: currentLocation,
          infoWindow: const InfoWindow(title: 'My Location'),
        ),
      );
    }

    // Add destination marker
    if (destination != LatLng(0, 0)) {
      markers.add(
        Marker(
          markerId: const MarkerId('myTappedDestination'),
          position: destination,
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: eta != null ? "ETA: $eta" : null,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      );
    }

    return markers;
  }

  /// Calculates LatLngBounds that encompasses both locations.
  ///
  /// Useful for animating camera to fit both origin and destination on screen.
  ///
  /// Example:
  /// ```dart
  /// final bounds = MapHelper.getLatLngBounds(
  ///   LatLng(40.7128, -74.0060),
  ///   LatLng(40.7580, -73.9855),
  /// );
  /// controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  /// ```
  static LatLngBounds getLatLngBounds(LatLng location, LatLng destination) {
    final southwest = LatLng(
      min(location.latitude, destination.latitude),
      min(location.longitude, destination.longitude),
    );

    final northeast = LatLng(
      max(location.latitude, destination.latitude),
      max(location.longitude, destination.longitude),
    );

    return LatLngBounds(southwest: southwest, northeast: northeast);
  }

  /// Calculates the distance between two coordinates in kilometers.
  ///
  /// Uses the Haversine formula for great-circle distance.
  ///
  /// Example:
  /// ```dart
  /// final distKm = MapHelper.calculateDistance(
  ///   LatLng(40.7128, -74.0060),
  ///   LatLng(40.7580, -73.9855),
  /// );
  /// print('Distance: ${distKm.toStringAsFixed(2)} km');
  /// ```
  static double calculateDistance(LatLng location1, LatLng location2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((location2.latitude - location1.latitude) * p) / 2 +
        cos(location1.latitude * p) *
            cos(location2.latitude * p) *
            (1 - cos((location2.longitude - location1.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  /// Converts degrees to radians.
  static double _toRad(double value) => value * pi / 180;
}
