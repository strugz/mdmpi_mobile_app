/// Interface for Google Places Autocomplete service.
///
/// Provides address suggestions as the user types.
abstract class IPlacesService {
  /// Gets place suggestions for a given input string.
  ///
  /// Returns a list of predictions with place descriptions.
  ///
  /// Example:
  /// ```dart
  /// final suggestions = await placesService.getSuggestions('Times Square');
  /// suggestions.forEach((prediction) {
  ///   print(prediction['description']);
  /// });
  /// ```
  Future<List<dynamic>> getSuggestions(String input);
}
