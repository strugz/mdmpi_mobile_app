import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Utility class for decoding Google Maps polyline encoded strings.
///
/// The Google Maps API encodes polylines using a precision loss algorithm
/// to reduce data size. This decoder reverses that process to get LatLng coordinates.
class PolylineDecoder {
  /// Decodes a Google Maps polyline encoded string into a list of LatLng coordinates.
  ///
  /// The polyline encoding algorithm is described here:
  /// https://developers.google.com/maps/documentation/utilities/polylinealgorithm
  ///
  /// Example:
  /// ```dart
  /// final encoded = "_p~iF~ps|U_ulLnnqC_mqNvxq`@";
  /// final coordinates = PolylineDecoder.decode(encoded);
  /// print(coordinates); // [LatLng(...), LatLng(...), ...]
  /// ```
  static List<LatLng> decode(String encoded) {
    final polylineCoordinates = <LatLng>[];
    int index = 0;
    final len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int shift = 0;
      int result = 0;
      int byte;

      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);

      final deltaLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += deltaLat;

      shift = 0;
      result = 0;

      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);

      final deltaLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += deltaLng;

      polylineCoordinates.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polylineCoordinates;
  }
}
