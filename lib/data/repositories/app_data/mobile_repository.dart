import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../models/mobile_model.dart';

class MobileRepository {
  static MobileRepository get instance => Get.find();

  /// -- WEB API HTTPS
  Future<List<Mobile>> getAllMobile() async {
    // Return List<Mobile>
    try {
      final response = await http.get(
        Uri.parse("${dotenv.env['API_URL']!}/api3/request/mobile"),
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        // Map to List<Mobile>
        return jsonData.map((item) => Mobile.fromJson(item)).toList();
      } else {
        throw Exception(
            'Failed to load mobiles. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAllMobile: $e');
      throw Exception(
          'Something went wrong while fetching mobiles. Please try again!');
    }
  }
}
