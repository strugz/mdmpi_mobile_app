import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mdmpi_mobile_app/base/utils/logger.dart';
import '../abstracts/i_places_service.dart';


/// Implementation of IPlacesService using RapidAPI Google Places Autocomplete.
///
/// Note: The API key is hardcoded in the implementation for now.
/// TODO: Move API key to environment variables for better security.
class PlacesService implements IPlacesService {
  static const String _rapidApiHost =
      'google-place-autocomplete-and-place-info.p.rapidapi.com';
  static const String _rapidApiKey =
      '4f82d3507fmsh8737922d6f89c00p1e27f4jsn31c6824aadc7';

  @override
  Future<List<dynamic>> getSuggestions(String input) async {
    if (input.isEmpty) {
      return [];
    }

    final String apiUrl =
        'https://google-place-autocomplete-and-place-info.p.rapidapi.com/maps/api/place/autocomplete/json?input=$input';
    final Map<String, String> headers = {
      'x-rapidapi-host': _rapidApiHost,
      'x-rapidapi-key': _rapidApiKey,
    };

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          return data['predictions'] ?? [];
        } else {
          logDebug(
            '⚠️ Places API returned non-OK status: ${data["status"]}',
          );
          return [];
        }
      } else {
        logDebug(
          '✗ Places API error - Status code: ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      logDebug('✗ Error getting suggestions: $e');
      return [];
    }
  }
}
