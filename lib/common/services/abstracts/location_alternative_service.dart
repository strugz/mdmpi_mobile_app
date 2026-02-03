import 'package:mdmpi_mobile_app/features/logistics/models/location_alternative_model.dart';

/// Abstract interface for location alternative management
abstract class ILocationAlternativeService {
  /// Save a corrected delivery location when user taps wrong address
  Future<int> saveLocationAlternative(LocationAlternativeModel model);

  /// Get all saved location alternatives for a request (accepts String or int)
  Future<List<LocationAlternativeModel>> getLocationAlternativesByRequestId(
    dynamic requestId,
  );

  /// Get the most recent location alternative for a request (accepts String or int)
  Future<LocationAlternativeModel?> getLatestLocationAlternative(
    dynamic requestId,
  );

  /// Delete all location alternatives for a request (accepts String or int)
  Future<int> deleteLocationAlternativesByRequestId(dynamic requestId);

  /// Delete a specific location alternative
  Future<int> deleteLocationAlternativeById(int id);

  /// Check if there are saved location alternatives for a request (accepts String or int)
  Future<bool> hasLocationAlternatives(dynamic requestId);

  /// Clear all location alternatives (cleanup)
  Future<int> clearAllLocationAlternatives();
}
