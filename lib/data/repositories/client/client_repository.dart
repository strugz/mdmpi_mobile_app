import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:mdmpi_mobile_app/features/logistics/models/client_model.dart';
import 'package:http/http.dart' as http;

import '../../../base/utils/exceptions/api_exception.dart';

class ClientRepository extends GetxController {
  static ClientRepository get instance => Get.find();

  /// -- WEB API HTTPS
  Future<List<ClientModel>> getAllClientAPI() async {
    try {
      // /api2 rather than /api3: the two return byte-identical payloads here,
      // and keeping both reference lists on one API version means they cannot
      // drift apart the way cntmst did, where /api3 quietly dropped fields.
      final response =
          await http.get(Uri.parse("${dotenv.env['API_URL']!}/api2/accmst"));

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);

        // Map into models while logging the parsed name for each client so we can
        // determine whether the casing change happens here or earlier/later.
        final clients = jsonResponse.map((data) {
          final model = ClientModel.fromJson(data);
          return model;
        }).toList();

        return clients;
      }

      throw BApiException('client list', '/api2/accmst', response.statusCode);
    } on BApiException {
      rethrow;
    } catch (e) {
      throw Exception('Could not load the client list: $e');
    }
  }
}
