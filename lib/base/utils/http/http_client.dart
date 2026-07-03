import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_environment.dart';

class BHttpHelper {
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(BApiEnvironment.api4Uri(endpoint));
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> post(
      String endpoint, dynamic data) async {
    final response = await http.post(
      BApiEnvironment.api4Uri(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> put(String endpoint, dynamic data) async {
    final response = await http.put(
      BApiEnvironment.api4Uri(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await http.delete(BApiEnvironment.api4Uri(endpoint));
    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }
}
