import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/helpers/polyline_decoder.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import '../abstracts/i_maps_service.dart';

/// Implementation of IMapsService using Google Maps API with caching.
///
/// Caches:
/// - Route calculations (origin-destination pairs)
/// - Geocoding results (place → coordinates)
/// - Reverse geocoding results (coordinates → address)
///
/// This helps reduce API calls and improves performance on slow internet connections.
class MapsService implements IMapsService {
  final String _apiKey = dotenv.env['API_KEY'] ?? '';

  // Cache maps
  final Map<String, Map<String, dynamic>> _routeCache = {};
  final Map<String, Map<String, dynamic>> _placeCoordinatesCache = {};
  final Map<String, Map<String, dynamic>> _coordinatesAddressCache = {};

  /// Generate cache key for routes
  String _getRouteCacheKey(LatLng origin, LatLng destination) {
    return '${origin.latitude},${origin.longitude}_${destination.latitude},${destination.longitude}';
  }

  /// Generate cache key for place coordinates
  String _getPlaceCoordinatesCacheKey(String place) {
    return 'place_${place.toLowerCase().trim()}';
  }

  /// Generate cache key for address from coordinates
  String _getAddressCacheKey(LatLng coordinates) {
    return 'address_${coordinates.latitude},${coordinates.longitude}';
  }

  /// Clear all caches
  void clearAllCaches() {
    _routeCache.clear();
    _placeCoordinatesCache.clear();
    _coordinatesAddressCache.clear();
    logDebug('✓ All maps caches cleared');
  }

  /// Clear route cache
  void clearRouteCache() {
    _routeCache.clear();
    logDebug('✓ Route cache cleared');
  }

  /// Clear coordinates cache
  void clearCoordinatesCache() {
    _placeCoordinatesCache.clear();
    _coordinatesAddressCache.clear();
    logDebug('✓ Coordinates cache cleared');
  }

  @override
  Future<Map<String, dynamic>> getRoute(
    LatLng origin,
    LatLng destination,
  ) async {
    if (origin == LatLng(0, 0) || destination == LatLng(0, 0)) {
      throw Exception('Invalid origin or destination coordinates');
    }

    final cacheKey = _getRouteCacheKey(origin, destination);

    // Check cache first
    if (_routeCache.containsKey(cacheKey)) {
      logDebug('📦 Route found in cache: $cacheKey');
      return _routeCache[cacheKey]!;
    }

    final String url =
        "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=${origin.latitude},${origin.longitude}"
        "&destination=${destination.latitude},${destination.longitude}"
        "&key=$_apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == "OK") {
        final route = data["routes"][0];
        final leg = route["legs"][0];
        final encodedPolyline = route["overview_polyline"]["points"];

        final routeData = {
          'polylinePoints': PolylineDecoder.decode(encodedPolyline),
          'distance': leg["distance"]["text"],
          'eta': leg["duration"]["text"],
          'address': leg["end_address"],
          'distanceValue': leg["distance"]["value"],
          'durationValue': leg["duration"]["value"],
        };

        // Cache the result
        _routeCache[cacheKey] = routeData;
        logDebug('✓ Route cached: $cacheKey');

        return routeData;
      } else {
        throw Exception('Route not found: ${data["status"]}');
      }
    } catch (e) {
      logDebug('✗ Error getting route: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getCoordinatesFromPlace(String place) async {
    final cacheKey = _getPlaceCoordinatesCacheKey(place);

    // Check cache first
    if (_placeCoordinatesCache.containsKey(cacheKey)) {
      logDebug('📦 Place coordinates found in cache: $cacheKey');
      return _placeCoordinatesCache[cacheKey]!;
    }

    final String url =
        "https://maps.googleapis.com/maps/api/geocode/json?"
        "address=${Uri.encodeComponent(place)}"
        "&key=$_apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data["status"] == "OK" && data["results"].isNotEmpty) {
        final location = data["results"][0]["geometry"]["location"];
        final coordinatesData = {
          'latitude': location["lat"],
          'longitude': location["lng"],
          'formatted_address': data["results"][0]["formatted_address"],
        };

        // Cache the result
        _placeCoordinatesCache[cacheKey] = coordinatesData;
        logDebug('✓ Place coordinates cached: $cacheKey');

        return coordinatesData;
      } else {
        throw Exception('Place not found: ${data["status"]}');
      }
    } catch (e) {
      logDebug('✗ Error getting coordinates from place: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getAddressFromCoordinates(
    LatLng coordinates,
  ) async {
    final cacheKey = _getAddressCacheKey(coordinates);

    // Check cache first
    if (_coordinatesAddressCache.containsKey(cacheKey)) {
      logDebug('📦 Address found in cache: $cacheKey');
      return _coordinatesAddressCache[cacheKey]!;
    }

    final String url =
        "https://maps.googleapis.com/maps/api/geocode/json?"
        "latlng=${coordinates.latitude},${coordinates.longitude}"
        "&key=$_apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data["status"] == "OK" && data["results"].isNotEmpty) {
        final addressData = {
          'address': data["results"][0]["formatted_address"],
        };

        // Cache the result
        _coordinatesAddressCache[cacheKey] = addressData;
        logDebug('✓ Address cached: $cacheKey');

        return addressData;
      } else {
        throw Exception('Address not found: ${data["status"]}');
      }
    } catch (e) {
      logDebug('✗ Error getting address from coordinates: $e');
      rethrow;
    }
  }
}
