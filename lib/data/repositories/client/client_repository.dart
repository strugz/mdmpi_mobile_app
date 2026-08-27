import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:http/http.dart' as http;

class ClientRepository extends GetxController {
  static ClientRepository get instance => Get.find();

  /// -- WEB API HTTPS
  Future<List<ClientModel>> getAllClientAPI() async {
    try {
      final response =
          await http.get(Uri.parse("${dotenv.env['API_URL']!}/api3/accmst"));

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);

        // Map into models while logging the parsed name for each client so we can
        // determine whether the casing change happens here or earlier/later.
        final clients = jsonResponse.map((data) {
          final model = ClientModel.fromJson(data);
          return model;
        }).toList();

        return clients;
      } else {
        throw Exception('Failed to load Client');
      }
    } catch (e) {
      throw Exception('Something went wrong. Please try again: $e');
    }
  }
}
