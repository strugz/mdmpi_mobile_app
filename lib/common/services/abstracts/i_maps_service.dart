import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Interface for Google Maps directions and geocoding services.
///
/// Handles:
/// - Route calculation between two coordinates
/// - Geocoding (address → coordinates)
/// - Reverse geocoding (coordinates → address)
abstract class IMapsService {
  /// Calculates a route between origin and destination.
  ///
  /// Returns route details including:
  /// - encoded polyline
  /// - distance
  /// - estimated time of arrival (ETA)
  /// - end address
  ///
  /// Throws exception if route cannot be calculated.
  Future<Map<String, dynamic>> getRoute(
    LatLng origin,
    LatLng destination,
  );

  /// Gets coordinates from a place address.
  ///
  /// Example:
  /// ```dart
  /// final result = await mapsService.getCoordinatesFromPlace('Times Square, NY');
  /// print('Latitude: ${result['latitude']}, Longitude: ${result['longitude']}');
  /// ```
  Future<Map<String, dynamic>> getCoordinatesFromPlace(String place);

  /// Gets address from coordinates (reverse geocoding).
  ///
  /// Example:
  /// ```dart
  /// final result = await mapsService.getAddressFromCoordinates(
  ///   LatLng(40.7580, -73.9855),
  /// );
  /// print('Address: ${result['address']}');
  /// ```
  Future<Map<String, dynamic>> getAddressFromCoordinates(LatLng coordinates);
}
