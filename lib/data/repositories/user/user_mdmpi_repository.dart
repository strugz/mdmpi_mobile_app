import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../models/cnstmst_model.dart';

class UserMDMPIRepository extends GetxController {
  static UserMDMPIRepository get instance => Get.find();

  /// -- WEB API HTTPS
  Future<List<CNTMSTModel>> getAllClientAPI() async {
    try {
      final response =
          await http.get(Uri.parse("${dotenv.env['API_URL']!}/api2/cntmst"));

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => CNTMSTModel.fromJson(data)).toList();
      } else {
        throw Exception('Failed to load Client');
      }
    } catch (e) {
      throw Exception('Something went wrong. Please try again: $e');
    }
  }
}
